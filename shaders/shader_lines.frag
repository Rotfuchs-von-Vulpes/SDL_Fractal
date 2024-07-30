#version 460 core

uniform double iZoom;
uniform vec2 iPosition;
uniform vec2 iScreen;
uniform vec2 iMouse;
uniform dvec2 iMove;
uniform int iMode;

out vec4 frag_color;

#define ESCAPE 1000.0

dvec2 cx_sqr(dvec2 a){
	double x2 = a.x * a.x;
	double y2 = a.y * a.y;
	double xy = a.x * a.y;

	return dvec2(x2 - y2, xy + xy);
}

dvec2 fractal_f(dvec2 z,dvec2 c){
	return cx_sqr(z) + c;
}

vec3 gradient(float n){
	float div = 1.0f / ESCAPE;
	float red = 10.0f * n * div;
	float green = 5.0f * n * div - .5f;
	float blue = (6.0f * n - 9.0f) / (2.0f * (4.0f * ESCAPE - 6.0f));

	return vec3(red, green, blue);
}

vec3 fractal(dvec2 z, dvec2 c){
	int i;
	float smooth_i;

	for(i = 0; i < ESCAPE; ++i) {
		z = fractal_f(z, c);
		if(dot(float(z), float(z)) > ESCAPE) {
			float modu = sqrt(dot(float(z), float(z)));
			smooth_i = float(i) - log2(max(1.0, log2(modu)));
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
	dvec2 c = dvec2(dvec2((dvec2(screen_pos) - iMove) * dvec2(1.0, -1.0)) * iZoom);

	if (iMode == 0) {
		col += fractal(c, c);
	} else if (iMode == 1) {
		col += fractal(c, c);
		col += fractal(dvec2(dvec2(screen_pos) * dvec2(1.0, -1.0) * double(0.00543478260869565217391304347826)), iMouse);
		col *= 0.5;
	} else {
		col += fractal(c, iPosition);
	}

	gl_FragColor = vec4(clamp(col, 0.0, 1.0), 1.0);
}