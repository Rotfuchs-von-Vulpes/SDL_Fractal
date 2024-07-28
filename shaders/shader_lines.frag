#version 330 core

uniform float iZoom;
uniform vec2 iPosition;
uniform vec2 iScreen;
uniform vec2 iMouse;
uniform vec2 iMove;
uniform int iMode;

out vec4 frag_color;

#define ESCAPE 1000.0

vec2 cx_sqr(vec2 a){
	float x2 = a.x * a.x;
	float y2 = a.y * a.y;
	float xy = a.x * a.y;

	return vec2(x2 - y2, xy + xy);
}

vec2 fractal_f(vec2 z,vec2 c){
	return cx_sqr(z) + c;
}

vec3 gradient(float n){
	float div = 1.f / ESCAPE;
	float red = 10.f * n * div;
	float green = 5.f * n * div - .5f;
	float blue = (6.f * n - 9.f) / (2.f * (4.f * ESCAPE - 6.f));

	return vec3(red, green, blue);
}

vec3 fractal(vec2 z, vec2 c){
	int i;
	float smooth_i;

	for(i = 0; i < ESCAPE; ++i) {
		z = fractal_f(z, c);
		if(dot(z, z) > ESCAPE) {
			float mod = sqrt(dot(z, z));
			smooth_i = float(i) - log2(max(1.0f, log2(mod)));
			break;
		}
	}

	if (i < ESCAPE) {
		return gradient(smooth_i);
	}
	return gradient(i);
}

void main(){
	vec2 screen_pos = gl_FragCoord.xy - (iScreen.xy * 0.5);
	vec3 col = vec3(0.0, 0.0, 0.0);
	vec2 c = vec2((screen_pos - iMove) * vec2(1.0, -1.0) * iZoom);

	if (iMode == 0) {
		col += fractal(c, c);
	} else if (iMode == 1) {
		col += fractal(c, c);
		col += fractal(vec2(screen_pos * vec2(1.0, -1.0) * 0.005434782608695652), iMouse);
		col *= 0.5;
	} else {
		col += fractal(c, iPosition);
	}

	gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}