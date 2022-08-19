using CairoMakie, ProgressBars

const nts = 1:10
const zs = [1,24,50]

function generateObsData(; zs=[1,24,50])

	obs = [];
	for x in 1:3:200, y in 1:3:200, z in [1,50]
		if y!= 90
			push!(obs,[z, y, x, rand()])
		end
	end
	#=
	for x in 5:10:195, y in 5:10:195, z in [24]
		if y!= 90
			push!(obs,[z, y, x, rand()])
		end
	end
	=#
	obs = reduce(hcat,obs)
	
	return obs
	
end

const obs = generateObsData(; zs=zs);

function main1()
	
	iz = [findall(z.==obs[1,:]) for z in zs]
	ys = [Observable(obs[2,z])  for z in iz]
	xs = [Observable(obs[3,z])  for z in iz]
	us = [Observable(obs[4,z])  for z in iz]

	fig = Figure(resolution = (900, 400))
	axs = [ Axis(fig[i, j], width = 200, height = 200) for i in 1:1, j in eachindex(zs) ]

	for ax in axs
		hidedecorations!(ax)
	end

	for j in eachindex(zs)
		if length(us[j][]) > 0
			contourf!(axs[1,j], ys[j], xs[j], us[j];levels=range(0,1,129),colormap=:Oranges,colorrange=(0,1),rasterize=true)
		end
	end
	Colorbar(fig[1:1,length(zs)+1]; colorrange=(0,1), colormap=:Oranges, label=L"u")
	tit = Label(fig[0,:], text = L"$t = 0$ []", textsize = 24)
	resize_to_layout!(fig)

	record(fig, "obsTest1.mp4", ProgressBar(nts); framerate=10) do n
		obs .= generateObsData(; zs=zs);
		for (j,z) in enumerate(iz)
			ys[j][] = obs[2,z]
			xs[j][] = obs[3,z]
			us[j][] = obs[4,z]
		end
		tit.text[] = L"$t = %$(n-1)$ []"
	end
	
	return nothing
end

function main2()
	
	OO = Observable(obs)
	
	fig = Figure(resolution = (900, 400))
	axs = [ Axis(fig[i, j], width = 200, height = 200) for i in 1:1, j in eachindex(zs) ]

	for ax in axs
		hidedecorations!(ax)
	end

	for (j,z) in enumerate(zs)
		iz = findall(z.==obs[1,:])
		contourf!(axs[1,j], @lift($OO[2,iz]), @lift($OO[3,iz]), @lift($OO[4,iz]);levels=range(0,1,129),colormap=:Oranges,colorrange=(0,1),rasterize=true)
	end
	Colorbar(fig[1:1,length(zs)+1]; colorrange=(0,1), colormap=:Oranges, label=L"u")
	tit = Label(fig[0,:], text = L"$t = 0$ []", textsize = 24)
	resize_to_layout!(fig)

	record(fig, "obsTest2.mp4", ProgressBar(nts); framerate=10) do n
		obs .= generateObsData(; zs=zs);
		OO[] = obs;
		tit.text[] = L"$t = %$(n-1)$ []"
	end
	
	return nothing
end

function main3()	# due to Jules [https://discourse.julialang.org/t/makie-observable-subtlety-with-contourf-using-vectors/85845/3]
	
	observations = Observable(obs)

	iz = [findall(z.==obs[1,:]) for z in zs]
	ys = [Observable(obs[2,z])  for z in iz]
	xs = [Observable(obs[3,z])  for z in iz]
	us = [Observable(obs[4,z])  for z in iz]

	on(observations) do obs
		iz = [findall(z.==obs[1,:]) for z in zs]
		for (i, z) in enumerate(iz)
			ys[i][] = obs[2,z]
			xs[i][] = obs[3,z]
			us[i].val = obs[4,z]
		end
	end

	fig = Figure(resolution = (900, 400))
	axs = [ Axis(fig[i, j], width = 200, height = 200) for i in 1:1, j in eachindex(zs) ]

	for ax in axs
		hidedecorations!(ax)
	end

	for j in eachindex(zs)
		if length(us[j][]) > 0
			contourf!(axs[1,j], ys[j], xs[j], us[j];levels=range(0,1,15),colormap=:Oranges,colorrange=(0,1),rasterize=true)
		end
	end
	Colorbar(fig[1:1,length(zs)+1]; colorrange=(0,1), colormap=:Oranges, label=L"u")
	tit = Label(fig[0,:], text = L"$t = 0$ []", textsize = 24)
	resize_to_layout!(fig)

	record(fig, "obsTest3.mp4", ProgressBar(nts); framerate=10) do n
		observations[] = generateObsData(; zs=zs);
		tit.text[] = L"$t = %$(n-1)$ []"
	end

	return nothing
end

function main4()
	
	observations = Observable(obs)

	iz = [findall(z.==obs[1,:]) for z in zs]
	ys = [Observable(obs[2,z])  for z in iz]
	xs = [Observable(obs[3,z])  for z in iz]
	us = [Observable(obs[4,z])  for z in iz]

	on(observations) do obs
		iz = [findall(z.==obs[1,:]) for z in zs]
		for (i, z) in enumerate(iz)
			ys[i][] = obs[2,z]
			xs[i][] = obs[3,z]
			us[i][] = obs[4,z]
		end
	end

	fig = Figure(resolution = (900, 400))
	axs = [ Axis(fig[i, j], width = 200, height = 200) for i in 1:1, j in eachindex(zs) ]

	for ax in axs
		hidedecorations!(ax)
	end

	for j in eachindex(zs)
		if length(us[j][]) > 0
			heatmap!(axs[1,j], ys[j], xs[j], us[j];colormap=:Oranges,colorrange=(0,1),rasterize=true,interpolate=true)
		end
	end
	Colorbar(fig[1:1,length(zs)+1]; colorrange=(0,1), colormap=:Oranges, label=L"u")
	tit = Label(fig[0,:], text = L"$t = 0$ []", textsize = 24)
	resize_to_layout!(fig)

	record(fig, "obsTest4.mp4", ProgressBar(nts); framerate=10) do n
		observations[] = generateObsData(; zs=zs);
		tit.text[] = L"$t = %$(n-1)$ []"
	end

	return nothing
end

main1()	# ~40s/it

main2()	# ~40s/it

main3() # ~15s/it

main4()	# ~14it/s
