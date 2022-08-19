include("readData.jl")
using Main.readData, CairoMakie, Printf, ArgParse, ProgressBars

function innovationMovie(workDir, zs = [1,10,20,30,40,50]; dx=0.015, dt=2.0)
		
	u = rand(Float64,nx,ny,nz)
	v = rand(Float64,nx,ny,nz)
	w = rand(Float64,nx,ny,nz)
	
	stateDir = "/data/$(workDir)/state";
	
	nts = 1:length(readdir("$(stateDir)/")) 	# get how many gues time steps there are
	
	us = [Observable(u[z,:,:]) for z in zs]
	vs = [Observable(v[z,:,:]) for z in zs]
	ws = [Observable(w[z,:,:]) for z in zs]

	fig = Figure(resolution = (2118, 1020))
	axs = [ Axis(fig[i, j], width = ny, height = nz, title=(i==1 ? L"$%$(round(zs[j]*dx;sigdigits=3))$ [cm]" : "")) for i in 1:3, j in eachindex(zs) ]

	for ax in axs
		hidedecorations!(ax)
	end
	
	for j in eachindex(zs)
		heatmap!(axs[1,j],us[j],colormap="Oranges",colorrange=(0,1),rasterize=true)
		heatmap!(axs[2,j],vs[j],colormap="Purples",colorrange=(0,1),rasterize=true)
		heatmap!(axs[3,j],ws[j],colormap="Greens", colorrange=(0,1),rasterize=true)
	end
	Colorbar(fig[1,length(zs)+1]; colorrange=(0,1), colormap="Oranges", label=L"u")
	Colorbar(fig[2,length(zs)+1]; colorrange=(0,1), colormap="Purples", label=L"v")
	Colorbar(fig[3,length(zs)+1]; colorrange=(0,1), colormap="Greens",  label=L"w")
	tit = Label(fig[0,:], text = L"$t = 0$ [ms]", textsize = 32)
	resize_to_layout!(fig)

	record(fig, "$(workDir).mp4", ProgressBar(nts); framerate=10) do n
		try
			fnames = [@sprintf("%s/%04d/restart3d.%03d",stateDir,n,p) for p in 0:3]
			readRestarts!(u, v, w, fnames)
			tit.text[] = L"$t = %$(dt*(n-1))$ [ms]"
			for (j,z) in enumerate(zs)
				us[j][] = u[z,:,:]
				vs[j][] = v[z,:,:]
				ws[j][] = w[z,:,:]
			end
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
	end

	return parse_args(s)
end

function main(; baseDir="/data")
	parsed_args = parse_commandline()
	workDir = parsed_args["workDir"]
	#print("This is >7.23-1.25× faster than the Python implementation!\n")	
	innovationMovie(workDir)    
	print("\n")
end

main()
