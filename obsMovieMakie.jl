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
	return obs[:,findall(z.==obs[2,:])]
end

function main( obsDir="/home/chris/Development/Alessio_Data/obs/114", zs = [1,24,50]; dx=0.015, dt=2.0)
	
	obs = reduce(hcat,readObsFile(@sprintf("%s/%04d.dat",obsDir,1)))
	
	nts = 1:100
	times = dt.*(nts.-1)
	
	fig = Figure(resolution = (900, 400))
	axs = [ Axis(fig[i, j], width = ny, height = nz, title=(i==1 ? L"$%$(round(zs[j]*dx;sigdigits=3))$ [cm]" : "")) for i in 1:1, j in eachindex(zs) ]
	
	# doing this correctly updates the plots, but it's super slow (~1 it/s), instead of 8 it/s for the usual dense matrices?
	iz = [findall(z.==obs[2,:]) for z in zs]
	ys = [Observable(obs[3,z])  for z in iz]
	xs = [Observable(obs[4,z])  for z in iz]
	us = [Observable(obs[5,z])  for z in iz]
	
	for ax in axs
		hidedecorations!(ax)
	end
	
	for j in eachindex(zs)
		if length(us[j][]) > 0
			contourf!(axs[1,j], ys[j], xs[j], us[j];levels=range(0,1,129),colormap=:Oranges,colorrange=(0,1),rasterize=true)
		end
	end
	Colorbar(fig[1:3,length(zs)+1]; colorrange=(0,1), colormap=:Oranges, label=L"u")
	tit = Label(fig[0,:], text = L"$t = 0$ [ms]", textsize = 24)
	resize_to_layout!(fig)
	
	record(fig, "114_unc_obs.mp4", ProgressBar(enumerate(times)); framerate=10) do (n,t)
		obs .= reduce(hcat,readObsFile(@sprintf("%s/%04d.dat",obsDir,n)))
		for (j,z) in enumerate(iz)
			ys[j][] = obs[3,z]
			xs[j][] = obs[4,z]
			us[j][] = obs[5,z]
		end
		tit.text[] = L"$t = %$(dt*(n-1))$ [ms]"
	end
	
	return nothing
end
main()
