struct ESPGeometry{CN, CV, DN, DV, DLBS, DUBS}
    csm_file::String
    constant_parameter_names::CN
    constant_parameter_values::CV
    design_parameter_names::DN
    design_parameter_values::DV
    design_parameters_lbs::DLBS
    design_parameters_ubs::DUBS
    m_build_to::Ref{Cint}
    model::modl_T
    model_ptr::Ptr{modl_T}
end

function ESPGeometry(csm_file::String; verbose=false)
    constant_param_names, constant_param_vals = _get_parameter_names_and_values(
        csm_file, "conpmtr"; verbose=verbose
    )
    design_param_names, design_param_vals = _get_parameter_names_and_values(
        csm_file, "despmtr"; verbose=verbose
    )
    design_param_lbs, design_param_ubs = _get_design_parameter_bounds(csm_file)

    # setup model
    context = Ref{ego}() # Maybe ok?
    model = Ref{Ptr{Cvoid}}()

    status = _suppress_stdout(EG_open, context; verbose=verbose)
    _check_egads_status(status)
    status = _suppress_stdout(ocsmLoad, csm_file, model; verbose=verbose)
    _check_ocsm_status(status)
    @info "Model $csm_file loaded"

    # setup model object
    model_ptr = Ptr{modl_T}(model[])
    model = unsafe_load(model_ptr)
    model.context = context[]

    # check file
    status = _suppress_stdout(ocsmCheck, model_ptr; verbose=verbose)
    _check_ocsm_status(status)
    @info "Checks OK"

    # build geometry
    t_build_to = Cint(0)
    m_build_to = Ref{Cint}()
    n_body = Ref{Cint}()
    status = _suppress_stdout(ocsmBuild, model_ptr, t_build_to, m_build_to, n_body, C_NULL; verbose=verbose)
    _check_ocsm_status(status)
    EG_deleteObject(context[])
    model.context = C_NULL
    @info "Model geometry built"

    # do some checks
    model = unsafe_load(model_ptr)
    n_body = 0
    for i in 1:model.nbody
        body = unsafe_load(model.body, i + 1)
        if body.onstack != 1 || body.botype == OCSM_NULL_BODY
            continue
        end
        n_body = n_body + 1
    end
    
    if n_body <= 0
        error("No bodies found.")
    end

    geometry = ESPGeometry(
        csm_file, 
        constant_param_names, constant_param_vals,
        design_param_names, design_param_vals,
        design_param_lbs, design_param_ubs,
        m_build_to, model, model_ptr
    )
    update_design_parameters!(geometry, design_param_vals)
    return geometry
end

function Base.close(g::ESPGeometry)
    model_ptr = Ptr{Cvoid}(pointer_from_objref(g.model))
    ocsmFree(Ref(model_ptr))
    ocsmFree(C_NULL)
    EG_close(g.model.context)
end

function Base.show(io::IO, g::ESPGeometry)
    str = "$(typeof(g).name.name):\n"
    str = str * "  Constant Parameters:\n"
    for (n, v) in zip(g.constant_parameter_names, g.constant_parameter_values)
        str = str * "    $n = $v\n"
    end
    str = str * "  Design Parameters:\n"
    for (n, v) in zip(g.design_parameter_names, g.design_parameter_values)
        str = str * "    $n = $v\n"
    end
    println(io, str)
end

function update_design_parameters!(g::ESPGeometry, param_vals)
    @assert length(g.design_parameter_values) == length(param_vals)
    temp_file = split(g.csm_file, ".csm")[1] * "_temp.csm"
    counter = 1
    open(temp_file, "w") do outf
        for line in eachline(g.csm_file)
            stripped = strip(line)
            if startswith(stripped, "despmtr")
                parts = split(stripped)
                pname = parts[2]
                @assert pname in g.design_parameter_names
                parts[3] = @sprintf("%.16g", param_vals[counter])
                counter = counter + 1
                println(outf, join(parts, " "))
            else
                println(outf, line)
            end
        end
    end
    @assert counter - 1 == length(param_vals)
end

function _get_design_parameter_bounds(csm_file)
    parameter_lbs = Cdouble[]
    parameter_ubs = Cdouble[]
    open(csm_file, "r") do f
        for line in eachline(f)
            if occursin("despmtr", line)
                parts = split(line, " ")
                push!(parameter_lbs, parse(Cdouble, parts[5]))
                push!(parameter_ubs, parse(Cdouble, parts[7]))
            end
        end
    end
    return parameter_lbs, parameter_ubs
end

function _get_parameter_names_and_values(csm_file, key; verbose=false)
    parameter_names = String[]
    parameter_values = Cdouble[]
    open(csm_file, "r") do f
        for line in eachline(f)
            if occursin(key, line)
                parts = split(line, " ")
                push!(parameter_names, parts[2])
                push!(parameter_values, parse(Cdouble, parts[3]))
            end
        end
    end
    # dump parameter names
    if verbose
        string = "Parameters:\n"
        for (param, val) in zip(parameter_names, parameter_values)
            string = string * "  $param = $val\n"
        end
        @info string
    end
    return parameter_names, parameter_values
end
