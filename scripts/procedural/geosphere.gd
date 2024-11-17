@tool
class_name IcoSphere
extends PrimitiveMesh

const ICO_X : float = .525731112119133606
const ICO_Z : float = .850650808352039932

const ICO_VERTICES : Array[Vector3] = [
	Vector3(-ICO_X, 0.0, ICO_Z),
	Vector3(ICO_X, 0.0, ICO_Z),
	Vector3(-ICO_X, 0.0, -ICO_Z),
	Vector3(ICO_X, 0.0, -ICO_Z),
	Vector3(0.0, ICO_Z, ICO_X),
	Vector3(0.0, ICO_Z, -ICO_X),
	Vector3(0.0, -ICO_Z, ICO_X),
	Vector3(0.0, -ICO_Z, -ICO_X),
	Vector3(ICO_Z, ICO_X, 0.0),
	Vector3(-ICO_Z, ICO_X, 0.0),
	Vector3(ICO_Z, -ICO_X, 0.0),
	Vector3(-ICO_Z, -ICO_X, 0.0)
]

const ICO_INDICES : Array[int] = [
	0,4,1,
	0,9,4,
	9,5,4,
	4,5,8,
	4,8,1,
	8,10,1,
	8,3,10,
	5,3,8,
	5,2,3,
	2,7,3,
	7,10,3,
	7,6,10,
	7,11,6,
	11,0,6,
	0,1,6,
	6,1,10,
	9,0,11,
	9,11,2,
	9,2,5,
	7,2,11
]

const ICO_FACES : Array[Vector3i] = [
	Vector3i(0,4,1),
	Vector3i(0,9,4),
	Vector3i(9,5,4),
	Vector3i(4,5,8),
	Vector3i(4,8,1),
	Vector3i(8,10,1),
	Vector3i(8,3,10),
	Vector3i(5,3,8),
	Vector3i(5,2,3),
	Vector3i(2,7,3),
	Vector3i(7,10,3),
	Vector3i(7,6,10),
	Vector3i(7,11,6),
	Vector3i(11,0,6),
	Vector3i(0,1,6),
	Vector3i(6,1,10),
	Vector3i(9,0,11),
	Vector3i(9,11,2),
	Vector3i(9,2,5),
	Vector3i(7,2,11)
]

@export_range(1, 16, 1) var subdivision : int = 2 :
	set(value) :
		subdivision = value
		request_update()

@export var height : float = 1.0 :
	set(value) :
		height = value
		request_update()

@export var diameter : float = 1.0 :
	set(value) :
		diameter = value
		request_update()


func _add_mid_point(a : int, b : int, h : Dictionary[int, int], vertices : Array[Vector3]) -> int:
	@warning_ignore("integer_division")
	var key : int = floor(((a + b) * (a + b + 1) / 2) + min(a, b))
	var r: int
	if h.has(key):
		r = h[key]
		h.erase(key) # Optional
	else:
		r = vertices.size()
		h[key] = r
		vertices.append((vertices[a] + vertices[b]) / 2)
	return r

func _create(order : int) -> Array:
	var vertices : Array[Vector3] = []
	vertices.append_array(ICO_VERTICES)
	
	var faces : Array[Vector3i] = ICO_FACES
	
	var mid_cache : Dictionary[int, int] = {}
	
	var prev_faces : Array[Vector3i] = faces
	
	for i in range(order):
		var prev_faces_count : int = prev_faces.size()
		faces = []
		faces.resize(prev_faces_count * 4)
		
		for k in range(prev_faces_count):
			var v1 : int = prev_faces[k].x
			var v2 : int = prev_faces[k].y
			var v3 : int = prev_faces[k].z
			var a : int = _add_mid_point(v1, v2, mid_cache, vertices)
			var b : int = _add_mid_point(v2, v3, mid_cache, vertices)
			var c : int = _add_mid_point(v3, v1, mid_cache, vertices)
			var next : int = k * 4
			faces[next    ] = Vector3i(v1,  a,  c)
			faces[next + 1] = Vector3i(v2,  b,  a)
			faces[next + 2] = Vector3i(v3,  c,  b)
			faces[next + 3] = Vector3i( a,  b,  c)
		prev_faces = faces

	var normals : Array[Vector3] = []
	var tangents : Array[Vector3] = []
	var bitangents : Array[Vector3] = []
	var v_count : int = vertices.size()
	normals.resize(v_count)
	tangents.resize(v_count)
	bitangents.resize(v_count)

	var uvs : Array[Vector2] = []
	uvs.resize(v_count)

	for i in range(v_count):
		var n : Vector3 = vertices[i].normalized() / 2.
		vertices[i] = n
		vertices[i].y *= height
		vertices[i].x *= diameter
		vertices[i].z *= diameter
		uvs[i] = Vector2((atan2(n.x, n.z) / (2 * PI)) + 0.5, n.y + .5)

	var radius : float = diameter / 2.
	var mid_h : float = height / 2.
	
	var r2 : float = radius * radius
	var h2 : float = mid_h * mid_h
	var div : Vector3 = Vector3(r2, h2, r2)

	for i in range(v_count):
		var n : Vector3 = (vertices[i] / div).normalized()
		var t : Vector3 = (Vector3(-n.y, n.x, 0.0) if abs(n.x) > abs(n.z) else Vector3(0.0, -n.z, n.y)).normalized()
		normals[i] = n # Changes if faceted.
		tangents[i] = t

	var f_count : int = prev_faces.size()
	var gen_faces : Array[int] = []
	gen_faces.resize(f_count * 3)
	for i in range(f_count):
		var o : int = i * 3
		gen_faces[o + 0] = prev_faces[i].x
		gen_faces[o + 1] = prev_faces[i].y
		gen_faces[o + 2] = prev_faces[i].z

	var tangents_array : PackedFloat32Array = PackedFloat32Array()
	tangents_array.resize(tangents.size() * 4)
	for i in range(tangents.size()):
		var j : int = i * 4
		tangents_array[j + 0] = tangents[i].x
		tangents_array[j + 1] = tangents[i].y
		tangents_array[j + 2] = tangents[i].z
		tangents_array[j + 3] = 1.

	var info : Array = []
	info.resize(Mesh.ARRAY_MAX)
	info[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
	info[Mesh.ARRAY_NORMAL] = PackedVector3Array(normals)
	info[Mesh.ARRAY_INDEX] = PackedInt32Array(gen_faces)
	info[Mesh.ARRAY_TEX_UV] = PackedVector2Array(uvs)
	info[Mesh.ARRAY_TANGENT] = tangents_array

	return info

func _create_mesh_array() -> Array:
	return _create(subdivision)
