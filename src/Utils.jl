struct verTags
    ptype::Cint
    pindex::Cint
end

function _check_egads_status(status, msg=nothing)
    if status != 0
        if msg !== nothing
            # @error msg
            # error("EGADS ERROR CODE: $status")
            # print(stderr, "EGADS ERROR CODE: ")
            # print(stderr, status)
            # error()
            _egads_err(status)
        end
        # error("EGADS ERROR CODE: $status")
    end
end

function _check_ocsm_status(status, msg=nothing)
    if status != 0
        if msg !== nothing
            @error msg
        end
        error("EGADS ERROR CODE: $status")
    end
end

@inline _devnull_path() = Sys.iswindows() ? "NUL" : "/dev/null"

@inline function _egads_err(status)
    print(stderr, "EGADS ERROR CODE: ")
    print(stderr, status)
    error()
end

@inline function _suppress_stdout(f, args...; verbose=false)
    if verbose
        f(args...)
    end

    devnull = open(_devnull_path(), "w")
    old_stdout = stdout
    try
        redirect_stdout(devnull)
        return f(args...)
    finally
        redirect_stdout(old_stdout)
        close(devnull)
    end
end
