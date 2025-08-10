using Aqua
using EngineeringSketchPadWrapper
using Test

function test_geometry()
    g = ESPGeometry("hole.csm")
end

function test_geometry_verbose()
    g = ESPGeometry("hole.csm"; verbose=true)
end

function test_tesselation()
    t = ESPTesselation("hole.csm")
end

# function test_tesselation_verbose()
#     t = ESPTesselation("hole.csm"; verbose=true)
# end

@testset "Geometry" begin
    test_geometry()
    test_geometry_verbose()
end

@testset "Tesselation" begin
    test_tesselation()
    # test_tesselation_verbose()
end

@testset "Aqua" begin
    Aqua.test_all(EngineeringSketchPadWrapper)
end
