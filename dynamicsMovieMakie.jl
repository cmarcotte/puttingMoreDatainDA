include("readData.jl")
using Main.readData, CairoMakie, Printf, ArgParse, ProgressBars, FortranFiles

function readObsFile(obsFile::String; verbose=false)
	#=
	obsFile : string for observation filename
	=#
	f = FortranFile(obsFile)
	#obs = Array{Float32,1}(undef, 6) # not needed, but useful for reference
	Obs = [] # accumulator
	while !eof(f)
		obs = read(f, (Float32,6));
		if verbose; println("Read observation $(obs)"); end
		push!(Obs, obs)
	end
	if eof(f)
		close(f)
	end
	return Obs
end

function obs2arr(obs)
	return reduce(hcat,obs)
end

function obsSlice(obs,z)
	iz = findall(z.==obs[2,:])
end

function dynamicsMovie(workDir, obsDir, ens = "gues", zs = [1,24,50]; dx=0.015, dt=2.0)
		
	mu = rand(Float64,nx,ny,nz)
	mv = rand(Float64,nx,ny,nz)
	mw = rand(Float64,nx,ny,nz)
	su = rand(Float64,nx,ny,nz)
	sv = rand(Float64,nx,ny,nz)
	sw = rand(Float64,nx,ny,nz)
	obs = reduce(hcat,readObsFile(@sprintf("%s/%04d.dat",obsDir,1)))
	
	meanDir = "/data/$(workDir)/$(ens)/mean";
	sprdDir = "/data/$(workDir)/$(ens)/sprd";
	
	nts = 1:length(readdir("$(meanDir)/")) 	# get how many gues time steps there are
	#=
	for n in 1:length(nts)				# check them by reading each corresponding anal dir
		try 
			readdir(@sprintf("%s/%04d/",sprdDir,n))
		catch
			nts = nts[1:(n-1)]
		end
	end
	=#	
	times = dt.*(nts.-1)
	
	MU = [Observable(mu[z,:,:]) for z in zs]
	SU = [Observable(su[z,:,:]) for z in zs]

	observations = Observable(obs)
	iz = [findall(z.==obs[2,:]) for z in zs]
	ys = [Observable(obs[3,z])  for z in iz]
	xs = [Observable(obs[4,z])  for z in iz]
	us = [Observable(obs[5,z])  for z in iz]

	on(observations) do obs
		iz = [findall(z.==obs[2,:]) for z in zs]
		for (i, z) in enumerate(iz)
			ys[i][] = obs[3,z]
			xs[i][] = obs[4,z]
			us[i][] = obs[5,z]
		end
	end

	fig = Figure(resolution = (1020, 1200))
	axs = [ Axis(fig[i, j], width = ny, height = nz, title=(i==1 ? L"$%$(round(zs[j]*dx;sigdigits=3))$ [cm]" : "")) for i in 1:3, j in eachindex(zs) ]

	for ax in axs
		hidedecorations!(ax)
	end
	
	for j in eachindex(zs)
		heatmap!(axs[j,1],MU[j];colormap=:Oranges,colorrange=(0,1),rasterize=true,interpolate=true)
		heatmap!(axs[j,2],SU[j];colormap=:Oranges,colorrange=(0,1),rasterize=true,interpolate=true)
		if length(iz[j]) > 0
			heatmap!(axs[j,3], ys[j], xs[j], us[j]; colormap=:Oranges,colorrange=(0,1),rasterize=true,interpolate=true)
		end
	end
	Colorbar(fig[1:3,length(zs)+1]; colorrange=(0,1), colormap=:Oranges, label=L"u")
	#cbartit = Label(fig[:,end], text=L"$u$", textsize=32, alignmode=Inside(), valign=:top)
	tit = Label(fig[0,:], text = L"$t = 0$ [ms]", textsize = 24)
	resize_to_layout!(fig)
	
	record(fig, "$(workDir)_dynamics.mp4", ProgressBar(enumerate(times)); framerate=10) do (n,t)
		try
			fnames = [@sprintf("%s/%04d/restart3d.%03d",meanDir,n,p) for p in 0:3]
			readRestarts!(mu, mv, mw, fnames)
			fnames = [@sprintf("%s/%04d/restart3d.%03d",sprdDir,n,p) for p in 0:3]
			readRestarts!(su, sv, sw, fnames)
			for (j,z) in enumerate(zs)
				MU[j][] = mu[z,:,:]
				SU[j][] = su[z,:,:]
			end
			observations[] = reduce(hcat,readObsFile(@sprintf("%s/%04d.dat",obsDir,n)))
			tit.text[] = L"$t = %$(dt*(n-1))$ [ms]"
		catch
		end
	end
	
	return nothing
end

function parse_commandline()
	s = ArgParseSettings()

	@add_arg_table s begin
	"workDir"
		help = "workDir"
		required = true
	#"obsDir"
	#	help = "obsDir"
	#	required = false
	end

	return parse_args(s)
end

function main(; baseDir="/data")
	parsed_args = parse_commandline()
	workDir = parsed_args["workDir"]
	#try
	#	obsDir = parsed_args["obsDir"]
	#catch
		obsDir = "/data/$(workDir)/obs"
	#end
	#print("This is >5.43-1.22× faster than the Python implementation!\n")	
	dynamicsMovie(workDir, obsDir)    
	print("\n")
end

main()
