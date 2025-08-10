module EngineeringSketchPadWrapper

export ESPGeometry
export ESPSensitivity
export ESPTesselation
export update_design_parameters!

using CEnum
using EngineeringSketchPad_jll
using Exodus
using Exodus_jll
using OCCT_jll
using Printf

include("Wrappers.jl")
include("Utils.jl")

include("Analysis.jl")
include("Geometry.jl")
include("Tesselation.jl")
include("Sensitivities.jl")

function __init__()
    esp_jll_dir = EngineeringSketchPad_jll.artifact_dir
    ENV["ESP_ARCH"] = "LINUX64"
    ENV["ESP_ROOT"] = esp_jll_dir
    ENV["CASROOT"] = OCCT_jll.artifact_dir
    ENV["CARARCH"] = "."
    ENV["CASREV"] = "7.7"
    ENV["CAPS_GLYPH"] = joinpath(esp_jll_dir, "src", "CAPS", "aim", "pointwise", "glyph")
    ENV["ESP_JULIA_ROOT"] = dirname(dirname(@__FILE__))
    # collect all dep libraries
    dep_libs = Exodus_jll.LIBPATH[] * EngineeringSketchPad_jll.LIBPATH[]
    ENV["PYESPDEPLIBS"] = dep_libs
    ENV["UDUNITS2_XML_PATH"] = joinpath(esp_jll_dir, "share", "esp_udunits", "udunits2.xml")
end

end # module
