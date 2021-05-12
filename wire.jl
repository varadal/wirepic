### A Pluto.jl notebook ###
# v0.14.5

using Markdown
using InteractiveUtils

# ╔═╡ f20b1d4e-26fd-46e2-af97-f0603216a26a
using Images, TestImages, Colors, ImageSegmentation, FileIO, ImageDraw, Statistics, ImageContrastAdjustment, ImageTransformations

# ╔═╡ c4cd49db-8598-450d-a42c-f94a96803556
begin
	get_circle(radius::Int64, c::CartesianIndex{2}, n::Int64) = get_circle(radius, c[1], c[2], n)
	
	function get_circle(r::Int64, x::Int64, y::Int64, n::Int64)
		center = CartesianIndex(x, y)
		sol = Vector{CartesianIndex{2}}()
		for i = 0:(360/n):359.9
			rad = deg2rad(i)
			coord = (round(cos(rad)*r), round(sin(rad)*r))
			ci = convert(Tuple{Int64, Int64}, map(x->round(Int, x), coord))
			push!(sol, CartesianIndex(ci)+center)
		end
		return sol
	end
end

# ╔═╡ 59258b46-0143-4ebf-87d6-352493cfb43b
function count_color(img::AbstractArray{T, 2}, p0::CartesianIndex{2}, p1::CartesianIndex{2}, c=Gray(1)) where T<:Colorant
	
	count = 0
	(x0, y0) = Tuple(p0)
	(x1, y1) = Tuple(p1)
	
	
    dx = abs(x1 - x0)
    dy = abs(y1 - y0)

    sx = x0 < x1 ? 1 : -1
    sy = y0 < y1 ? 1 : -1;

    err = (dx > dy ? dx : -dy) / 2

    while true
        (x0 != x1 || y0 != y1) || break
		count += abs(c.val - img[x0, y0].val)
		count -= (c.val == img[x0, y0].val)*0.1
		
        e2 = err
        if e2 > -dx
            err -= dy
            x0 += sx
        end
        if e2 < dy
            err += dx
            y0 += sy
        end

    end

    count
end

# ╔═╡ adfed0fe-179a-4ced-8cbd-7c1fe8106392
begin
	img = load("/Users/magna/Documents/programming/repos/wirepic/images/harry_original.png")
	
	gray_img = Gray.(img);
	alg = ContrastStretching(t = 0.30, slope = 5);
	gray_img = adjust_histogram(gray_img, alg);
end

# ╔═╡ ce22faee-f77d-4f51-bd00-abcabc591f65
begin
	center = CartesianIndex(550, 1950)
	radius = 500
	circle_coords = get_circle(radius, center, 10000)

	circle_img = copy(img)
	circle_img[center] = RGB(1, 0, 0)
	for c ∈ circle_coords
		if all(Tuple(c) .∈ axes(circle_img))
			circle_img[c] = RGB(1, 0, 0)
		end
	end
	circle_img
end

# ╔═╡ e5e3bba0-52fc-4078-947e-d5c07a8efd54
function get_wire(img::Array{T,2}, center::CartesianIndex{2}, radius::Int64, loops=1000) where T<:Colorant

	coords = get_circle(radius, center, 1000)
	coords = filter!(x -> all(Tuple(x) .∈ axes(img)), coords)
	
	gray_img = Gray.(img)
	alg = ContrastStretching(t = 0.3, slope = 5)
	gray_img = adjust_histogram(gray_img, alg)

	
	lines = vec([(x, y) for x ∈ coords, y ∈ coords])
	used = Set{Tuple{CartesianIndex{2},CartesianIndex{2}}}()
	
	output_img = Gray.(ones(size(img)))

	used_coords = typeof(lines)()
	for i = 1:loops
		(v, p) = findmax(map(x -> count_color(gray_img, x[1], x[2]), lines))
		v > 0 || break
			
		draw!(output_img, LineSegment(lines[p][1], lines[p][2]), Gray(0.0))
		draw!(gray_img, LineSegment(lines[p][1], lines[p][2]), Gray(1))

		push!(used_coords, lines[p])
		push!(used, lines[p])
		start = lines[p][2]
		lines = [ (start, e_point) for e_point ∈ coords 
				  if (start, e_point) ∉ used && (e_point, start) ∉ used
				]
	end
	
	return output_img, used_coords
end

# ╔═╡ 6a7d55f4-01a2-47f8-b249-a64c8a885a4f
out_img, out_coord = get_wire(gray_img, center, radius, 3000);
# out_img;

# ╔═╡ 01fb7781-d160-4cad-a337-8912bd3f6c9e
out_img

# ╔═╡ 5e862dc5-5444-434e-86a5-0d6ff83e481b
begin
	tmp_img = copy(img)
	for tup ∈ out_coord
		draw!(tmp_img, LineSegment(tup[1], tup[2]), RGB(0, 0, 0))
	end
end

# ╔═╡ e814cead-3dc4-4889-a5ad-1ab6e40fba7a
out

# ╔═╡ Cell order:
# ╠═f20b1d4e-26fd-46e2-af97-f0603216a26a
# ╟─c4cd49db-8598-450d-a42c-f94a96803556
# ╟─59258b46-0143-4ebf-87d6-352493cfb43b
# ╠═adfed0fe-179a-4ced-8cbd-7c1fe8106392
# ╠═ce22faee-f77d-4f51-bd00-abcabc591f65
# ╠═e5e3bba0-52fc-4078-947e-d5c07a8efd54
# ╠═6a7d55f4-01a2-47f8-b249-a64c8a885a4f
# ╠═01fb7781-d160-4cad-a337-8912bd3f6c9e
# ╠═5e862dc5-5444-434e-86a5-0d6ff83e481b
# ╠═e814cead-3dc4-4889-a5ad-1ab6e40fba7a
