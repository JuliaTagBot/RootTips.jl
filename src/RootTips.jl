__precompile__()

module RootTips

using NDFiles, Gtk, ProgressMeter

export main, batch_main

head = Gtk.GtkWindow("TrackRoots", 20, 20, false, true, visible=false, modal=true)

include(joinpath(Pkg.dir("RootTips"), "src", "utils.jl"))

include(joinpath(Pkg.dir("RootTips"), "src", "startPoints.jl"))

function main(ndfile::String = open_dialog("Pick an `.nd` file", head, ("*.nd",)))
    stages = nd2stages(ndfile)
    get_startpoints.(stages)
    run(`julia -e 'using TrackRoots; main(ARGS[1])' $ndfile`)
    # print(ndfile)
    # open(joinpath(tempdir(), "JULIA_NDFILE"), "w") do o
        # println(o, ndfile)
    # end
    # nothing
end

# batch

isnd(file::String) = last(splitext(file)) == ".nd"

function findall_nd(home::String)
    ndfiles = String[]
    for (root, dirs, files) in walkdir(home)
        filter!(isnd, files)
        append!(ndfiles, joinpath.(home, root, files))
    end
    return ndfiles
end

function batch_main(home::String = open_dialog("Pick a folder where all the `.nd` files are", action=GtkFileChooserAction.SELECT_FOLDER))
    ndfiles = findall_nd(home)
    n = length(ndfiles)
    # open(joinpath(tempdir(), "JULIA_NDFILES"), "w") do o
        info("Found $n `.nd` files")
        @showprogress 1 "Collecting start points…" for i in 1:n
            stages = nd2stages(ndfiles[i])
            get_startpoints.(stages)
            # println(o, ndfile)
        end
    # end
    run(`julia -e 'using TrackRoots; batch_main(ARGS[1])' $home`)
end

end # module
