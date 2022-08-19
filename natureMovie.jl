include("readData.jl")
using Main.readData, PyPlot, Printf, ArgParse, ProgressBars

plt.style.use("seaborn-paper")

PyPlot.rc("font", family="serif")
PyPlot.rc("text", usetex=true)
PyPlot.matplotlib.rcParams["axes.titlesize"] = 10
PyPlot.matplotlib.rcParams["axes.labelsize"] = 10
PyPlot.matplotlib.rcParams["xtick.labelsize"] = 9
PyPlot.matplotlib.rcParams["ytick.labelsize"] = 9

const sw = 3.40457
const dw = 7.05826

function innovationMovie(workDir, zs = [1,10,20,30,40,50]; dx=0.015, dt=2.0)
		
	u = rand(Float64,nx,ny,nz)
	v = rand(Float64,nx,ny,nz)
	w = rand(Float64,nx,ny,nz)
	
	stateDir = "/data/$(workDir)/state";
	frameDir = "./nature_frames"; 
	mkpath(frameDir);
	
	nts = 1:length(readdir("$(stateDir)/")) 	# get how many gues time steps there are
	times = dt.*(nts.-1)
	
	fig,axs = plt.subplots(3,length(zs), figsize=(dw,sw), sharex=true, sharey=true, constrained_layout=true)			
	for (n,t) in ProgressBar(enumerate(times))
		for ax in axs
			ax.cla()
			ax.axes.set_aspect("equal")
			ax.set_xticks([])
			ax.set_yticks([])
		end
		try
			fnames = [@sprintf("%s/%04d/restart3d.%03d",stateDir,n,p) for p in 0:3]
			readRestarts!(u, v, w, fnames)
			
			for (o,z) in enumerate(zs)
				obsdepth = z==1 ? 0.0 : z*dx
				axs[end,o].set_xlabel(@sprintf("\$ %2.3f\$ [cm]", obsdepth))
				if n==1 && o==length(zs)
					ima = axs[1,o].pcolormesh(transpose(u[z,:,:]), snap=true, shading="auto", rasterized=true, vmin=0.0, vmax=1.0, cmap="Oranges")
					clb = plt.colorbar(ima, ax=axs[1,:])
					clb.ax.set_ylabel("\$u\$")
					ima = axs[2,o].pcolormesh(transpose(v[z,:,:]), snap=true, shading="auto", rasterized=true, vmin=0.0, vmax=1.0, cmap="Purples")
					clb = plt.colorbar(ima, ax=axs[2,:])
					clb.ax.set_ylabel("\$v\$")
					ima = axs[3,o].pcolormesh(transpose(w[z,:,:]), snap=true, shading="auto", rasterized=true, vmin=0.0, vmax=1.0, cmap="Greens")
					clb = plt.colorbar(ima, ax=axs[3,:])
					clb.ax.set_ylabel("\$w\$")
				else
					axs[1,o].pcolormesh(transpose(u[z,:,:]), snap=true, shading="auto", rasterized=true, vmin=0.0, vmax=1.0, cmap="Oranges")
					axs[2,o].pcolormesh(transpose(v[z,:,:]), snap=true, shading="auto", rasterized=true, vmin=0.0, vmax=1.0, cmap="Purples")
					axs[3,o].pcolormesh(transpose(w[z,:,:]), snap=true, shading="auto", rasterized=true, vmin=0.0, vmax=1.0, cmap="Greens")
				end
			end
			plt.suptitle("\$t=$(t)\$ [ms]")
			plt.savefig(@sprintf("%s/%04d.png", frameDir, n), dpi=300, bbox_inches="tight")
		catch
			print("\n\t Stopping frame generation at iteration $(n).\n")
			break
		end
	end
	try
		rm("$(workDir).mp4");
	catch
	end
	run(`ffmpeg -r 10 -f image2 -start_number 1 -i $(frameDir)/%04d.png -c:v h264_nvenc -pix_fmt yuv420p -loglevel quiet -stats $(workDir).mp4`);
	rm(frameDir, recursive=true);
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
