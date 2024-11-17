# 3D Anime Flame Effect

*Note: This effect was originally created by [ゴロペコ](https://bsky.app/profile/goropeko.bsky.social) and its execution has been made possible by following his very well done [YT tutorial](https://www.youtube.com/watch?v=IcYq5ijWCVs).*

## Disclaimer

This is a Godot port, and thus requires the [Godot Engine](https://godotengine.org/) to work properly (at least verion 4.3). *Don't be scared if it says that it requires version 4.4. It'll work anyway*

It consists of a fully functional flame effect scene and a partially functional tool that allow live editing of the flame texture (feel free to contribute). It has been made in few hours and (currently) lacks comments or in code explanations.

## Concept

In order to fake flame flickering and air distortion in a 3D environment, a solution consists in recreating this distortion by deforming a surface where a flame texture is applied by fetching the texels using the surface normals (converted from world to camera space).

It's in fact a 3D transposition of the classical 2D flame effect.

## Resources

As mentioned before, this visual effect has been ported in few hours from a blender turorial. To do so, some help has been needed by grabbing really effective solution from all over the internet.

### The Sphere

We start with a sphere. For better effect, it must be a geometry with evenly distributed vertices. Classical geodesic sphere was chosen. I may be wrong, but I don't think that Godot propose geodesic sphere as Primitive Mesh (if that's the case, sorry). With time restriction, I needed some effective yet simple algorithm and gladfully found [Volodymyr Agafonkin's solution](https://observablehq.com/@mourner/fast-icosphere-mesh) which is easily portable in GDScript. I've just added UVs, normals and tangents computations that will be needed in the shader.

### The Noise

The sphere needs to be distorted. In fact, we'll displace its vertices using a continuous noise function. The original effect author (ゴロペコ) uses an inverted cellular noise which gives interesting results.
Several options are available :
- Use a 2D noise texture and get the values using the shifted UV of the sphere. Big cons : distortion on the poles (and we need beautiful and clean displacement).
- Use a 3D noise texture and get the values using the shifted initial vertices position. Cons : Require a big/heavy texture to avoid too repetitive patterns (it will be repetitive anyway).
- Use a 3D noise function computed within the vertex shader based on the vertices position. Cons : Computation can be heavy (really?), especially if there's a lot of vertices.

The later solution has been chosen. A [simple solution](https://github.com/MaxBittker/glsl-voronoi-noise) is available thanks to [Max Bittker](https://bsky.app/profile/maxbittker.bsky.social) who implemented a 3D voronoi noise in GLSL. This code has been stripped of uneeded computations and integrated to the final vertex shader.

### The Normals

One crucial element is the normals recomputation. As we don't deal with a simple parametric surface, we fake our way by locally recomputing normal vector for each displaced vertices. Once again, internet to the rescue and especially this [blessed forum entry by user marcofugaro](https://discourse.threejs.org/t/calculating-vertex-normals-after-displacement-in-the-vertex-shader/16989/8) which helped a lot. Not only because it works, but also because it produces some interesting artifacts depending on the resolution parameters that helps obtaining different results for the flame effect itself.

