// Author: iandol
// Title: anstis+cavanaugh 1983 pseudo color shader

#ifdef GL_ES
precision mediump float;
#endif

uniform float radius;
uniform vec2 center;
uniform vec4 color1;
uniform vec4 color2;
uniform vec4 color3;
uniform vec4 color4;

varying vec3 baseColor;
varying float phase;
varying float frequency;
varying float sigma;

void main() {

	//current position
	vec2 pos = gl_TexCoord[0].xy;

	/* find our distance from center, if distance to center (aka radius of pixel) > Radius, discard this pixel: */
	if ( distance( pos, center ) > radius ) discard;

	float sv = sin(pos.x * frequency + phase);
	sv = (sv + 1.0) / 2.0; //get sv into 0 - 1 range;

	vec3 color = vec3(0.0);

	if (mod(pos.y,2.0) > 1.0) { //we will be color1/3
		if (sv > 0.5) {
			color = color1.rgb; //bright
		}
		else {
			color = color3.rgb; //dark
		}
	}
	else { // we will be color2/4
		if (sv > 0.5) {
			color = color2.rgb; //bright
		}
		else {
			color = color4.rgb; //dark
		}
	}
	
	gl_FragColor = vec4(color,1.0);
}