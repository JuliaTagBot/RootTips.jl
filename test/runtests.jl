using RootTips
@static if VERSION < v"0.7.0-DEV.2005"
    using Base.Test
else
    using Test
end

import RootTips:Mark

using DataDeps

ENV["DATADEPS_ALWAY_ACCEPT"]=true
register(DataDep("test",
                "These are two folders with their `nd` files and multiple dark and light timelapse 16 bit TIF images (1.9 GB total).",
                "https://s3.eu-central-1.amazonaws.com/yakirgagnon/roots/test.zip",
                "d99b8f2edce5e72104ba1cfed02798a6683bc22f4b76a5cb823c80257bc4bf48",
                post_fetch_method=unpack))

# # incase there are old test files, remove them just in case they are old/bad
rm(joinpath(datadep"test", "1", "d2"), recursive=true, force=true)

@testset "utils" begin
    @test RootTips.isnd("name.nd")
    @test !RootTips.isnd("name.ndd")
    ndfiles = RootTips.findall_nd(datadep"test")
    @test length(ndfiles) == 2
end

@testset "startpoint" begin

    @test RootTips.get_point(GtkReactive.XY{GtkReactive.UserUnit}(.2,.4)) == Mark(.4,.2)

    ndfile = joinpath(datadep"test", "1", "d2.nd")
    stages = RootTips.nd2stages(ndfile)
    file = stages[1].timelapse[1].dark
    img, imgtmp, ms = RootTips.fetch_image(file)
    @test img == imgtmp
    @test ms == [0.0038452735179674985, 0.005874723430228122]

    M = 0.5
    message = "test"
    s, b = RootTips.build_slider(M, message)
    @test GtkReactive.value(s) == M
    @test b isa Gtk.GtkBoxLeaf

end

@testset "all" begin
    startpoints = [[Mark[[774.3011654713115, 911.7642161885246]]], [Mark[[761.334080430328, 413.93003970286884]], Mark[[811.9541095671107, 510.3906089907787]]]]
    endpoints = [[Mark[[905.2760077185163, 918.9115390162102]]], [Mark[[1016.9281490727263, 209.57046484226038]], Mark[[1017.350592982095, 315.11227808371984]]]]
    for (i, dataset) in enumerate(["1","5"])
        files = readdir(joinpath(datadep"test", dataset))
        ind = findfirst(x -> last(splitext(x)) == ".nd", files)
        ndfile = joinpath(datadep"test", dataset, files[ind])
        stages = RootTips.nd2stages(ndfile)
        Δx = RootTips.pixel_width(stages[1])
        calibstages = RootTips.stages2calib(stages, Δx)
        tracks = RootTips.trackroot.(calibstages, startpoints[i])
        endpoint = map(tracks) do t
            map(t) do r
                r.coordinates[end]
            end
        end
        @test endpoints[i] == endpoint
    end
end

@testset "plotting" begin

    startpoint = [Mark[[774.3011654713115, 911.7642161885246]]]
    ndfile = joinpath(datadep"test", "1", "d2.nd")
    main(ndfile, startpoint, Base.DevNullStream())

    @test isfile(joinpath(datadep"test", "1", "d2", "stage 1", "roots.png"))
    @test isfile(joinpath(datadep"test", "1", "d2", "stage 1", "root 1", "coordinates.csv"))
    @test isfile(joinpath(datadep"test", "1", "d2", "stage 1", "root 1", "intensities.csv"))
    @test isfile(joinpath(datadep"test", "1", "d2", "stage 1", "root 1", "summary.mp4"))

    #clean up
    #=rm(joinpath(first(DataDeps.default_loadpath), "test", "1", "d2"), recursive=true, force=true)=#
end

