shader_type spatial;

render_mode cull_back, depth_draw_opaque;

// Voronoi noise from Max Bittker : https://github.com/MaxBittker/glsl-voronoi-noise

const mat2 myt = mat2(vec2(.12121212, .13131313), vec2(-.13131313, .12121212));
const vec2 mys = vec2(1e4, 1e6);

vec2 rhash(vec2 uv) {
  uv *= myt;
  uv *= mys;
  return fract(fract(uv / mys) * uv);
}

vec3 hash(vec3 p) {
  return fract(
      sin(vec3(dot(p, vec3(1.0, 57.0, 113.0)), dot(p, vec3(57.0, 113.0, 1.0)),
               dot(p, vec3(113.0, 1.0, 57.0)))) *
      43758.5453);
}

vec2 voronoi3d(const in vec3 x) {
  vec3 p = floor(x);
  vec3 f = fract(x);

  vec2 res = vec2(100.0);
  for (int k = -1; k <= 1; k++) {
    for (int j = -1; j <= 1; j++) {
      for (int i = -1; i <= 1; i++) {
        vec3 b = vec3(float(i), float(j), float(k));
        vec3 r = vec3(b) - f + hash(p + b);
        float d = dot(r, r);

        float cond = max(sign(res.x - d), 0.0);
        float nCond = 1.0 - cond;

        float cond2 = nCond * max(sign(res.y - d), 0.0);
        float nCond2 = 1.0 - cond2;

        res = vec2(d, res.x) * cond + res * nCond;

        res.y = cond2 * d + nCond2 * res.y;
      }
    }
  }

  return sqrt(res);
}

uniform sampler2D decal : repeat_enable;

uniform sampler2D attenuation : repeat_disable;

uniform float displace_strenght : hint_range(-16.0, 16.0, 0.01) = 0.;

uniform float flame_speed : hint_range(-5., 5., 0.01) = 1.;

uniform float offset = 0.01;

uniform vec3 noise_factor = vec3(3.);

varying vec3 vNormal;

void vertex() {
	vec3 neighbor1 = VERTEX + offset * TANGENT;
	vec3 bitangent = normalize(cross(NORMAL, TANGENT));
	vec3 neighbor2 = VERTEX + offset * bitangent;

	vec3 noise_texture_coord = (VERTEX - vec3(0., flame_speed * TIME, 0.)) * noise_factor;
	vec3 noise_texture_coord1 = (neighbor1 - vec3(0., flame_speed * TIME, 0.)) * noise_factor;
	vec3 noise_texture_coord2 = (neighbor2 - vec3(0., flame_speed * TIME, 0.)) * noise_factor;

	vec2 d1 = voronoi3d(noise_texture_coord1);
	vec2 d2 = voronoi3d(noise_texture_coord2);
	vec2 d = voronoi3d(noise_texture_coord);

	float att = displace_strenght * texture(attenuation, vec2(UV.y, 0)).r;
	VERTEX += NORMAL * (1. - d.x) * att;
	vec3 v1 = neighbor1 + NORMAL * (1. - d1.x) * att;
	vec3 v2 = neighbor2 + NORMAL * (1. - d2.x) * att;
	vec3 dis_tangent = v1 - VERTEX;
	vec3 dis_bi_tangent = v2 - VERTEX;
	vec3 dis_normal = normalize(cross(dis_tangent, dis_bi_tangent));

	NORMAL = dis_normal;
	vNormal = MODEL_NORMAL_MATRIX * dis_normal;
}

void fragment() {
	vec3 view_normal = mat3(VIEW_MATRIX) * vNormal;
	vec2 l_uv = view_normal.xy * .5 + .5;
	vec4 real_c = texture(decal, vec2(l_uv.x, 1. - l_uv.y));
	ALBEDO = real_c.rgb;
	ALPHA = real_c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.3;
}
