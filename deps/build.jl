pkgs = ["NDFiles", "TrackRoots"]
for pkg in pkgs
    if Pkg.cd(!isdir, pkg) 
        Pkg.clone("https://github.com/yakir12/$pkg.jl")
        Pkg.build(pkg)
    end
end
