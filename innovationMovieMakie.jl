include("readData.jl")
using Main.readData, CairoMakie, Printf, ArgParse, ProgressBars, FortranFiles

function innovationMovie(workDir, zs = [1,10,20,30,40,50]; dx=0.015, dt=2.0)
		
	gu = rand(Float64,nx,ny,nz)
	v  = rand(Float64,nx,ny,nz)
	w  = rand(Float64,nx,ny,nz)
	au = rand(Float64,nx,ny,nz)
	iu = gu.-au
	
	guesDir = "/data/$(workDir)/gues/mean";
	analDir = "/data/$(workDir)/anal/mean";
	
	nts = 1:length(readdir("$(guesDir)/")) 	# get how many gues time steps there are
	times = dt.*(nts.-1)
	
	GU = [Observable(gu[z,:,:]) for z in zs]
	AU = [Observable(au[z,:,:]) for z in zs]
	IU = [Observable(iu[z,:,:]) for z in zs]
	
	fig = Figure(resolution = (2160, 1200))
	axs = [ Axis(fig[i, j], width = ny, height = nz, title=(i==1 ? L"$%$(round(zs[j]*dx;sigdigits=3))$ [cm]" : "")) for i in 1:3, j in eachindex(zs) ]

	for ax in axs
		hidedecorations!(ax)
	end
	
	for j in eachindex(zs)
		heatmap!(axs[1,j],GU[j]; colormap=:Oranges,colorrange=(+0.0,+1.0),rasterize=true,interpolate=true)
		heatmap!(axs[2,j],IU[j]; colormap=:seismic,colorrange=(-0.1,+0.1),rasterize=true,interpolate=true)
		heatmap!(axs[3,j],AU[j]; colormap=:Oranges,colorrange=(+0.0,+1.0),rasterize=true,interpolate=true)
	end
	Colorbar(fig[1:1,length(zs)+1]; colorrange=(+0.0,+1.0), colormap=:Oranges, label=L"u_g")
	Colorbar(fig[2:2,length(zs)+1]; colorrange=(-0.1,+0.1), colormap=:seismic, label=L"u_a-u_g")
	Colorbar(fig[3:3,length(zs)+1]; colorrange=(+0.0,+1.0), colormap=:Oranges, label=L"u_a")
	#cbartit = Label(fig[:,end], text=L"$u$", textsize=32, alignmode=Inside(), valign=:top)
	tit = Label(fig[0,:], text = L"$t = 0$ [ms]", textsize = 24)
	resize_to_layout!(fig)
	
	record(fig, "$(workDir)_innovation.mp4", ProgressBar(enumerate(times)); framerate=10) do (n,t)
		fnames = [@sprintf("%s/%04d/restart3d.%03d",guesDir,n,p) for p in 0:3]
		readRestarts!(gu, v, w, fnames)
		fnames = [@sprintf("%s/%04d/restart3d.%03d",analDir,n,p) for p in 0:3]
		readRestarts!(au, v, w, fnames)
		iu .= gu .- au;
		for (j,z) in enumerate(zs)
			GU[j][] = gu[z,:,:]
			AU[j][] = au[z,:,:]
			IU[j][] = iu[z,:,:]
		end			
		tit.text[] = L"$t = %$(dt*(n-1))$ [ms]"
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
	innovationMovie(workDir)    
	print("\n")
end

main()
