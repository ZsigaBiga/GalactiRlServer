#version 120

//#define CSBOX //Customize the color of your block selection box. Enabling will also change leads to the selected color Sadly this is unavoidable.
	#define CSR 0 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 104 108 112 116 120 124 128 132 136 140 144 148 152 156 160 164 168 172 176 180 184 188 192 196 200 204 208 212 216 220 224 228 232 236 240 244 248 252 255]
	#define CSG 0 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 104 108 112 116 120 124 128 132 136 140 144 148 152 156 160 164 168 172 176 180 184 188 192 196 200 204 208 212 216 220 224 228 232 236 240 244 248 252 255]
	#define CSB 0 //[0 4 8 12 16 20 24 28 32 36 40 44 48 52 56 60 64 68 72 76 80 84 88 92 96 100 104 108 112 116 120 124 128 132 136 140 144 148 152 156 160 164 168 172 176 180 184 188 192 196 200 204 208 212 216 220 224 228 232 236 240 244 248 252 255]


varying vec4 color;

const int GL_LINEAR = 9729;
const int GL_EXP = 2048;

uniform int fogMode;

/* DRAWBUFFERS:0 */


void main() {

	#ifdef CSBOX
	vec3 color = vec3(CSR, CSG, CSB)/255;

			gl_FragData[0] = vec4(color, 1.0);

	#endif

	#ifndef CSBOX

		gl_FragData[0] = color; //gcolor

	#endif

	//depth
	gl_FragData[1] = vec4(0.0f, 0.0f, 1.0f, 0.0f);

	gl_FragData[2] = vec4(0.0f, 0.0f, 0.0f, 0.0f);

	//matIDs, lightmap.r, lightmap.b
	gl_FragData[3] = vec4(0.0f, 0.0f, 0.0f, 0.0f);

	//specularity.r, specularity.g, iswater
	//gl_FragData[3] = vec4(0.0f, 0.0f, 0.0f, alphamask);

	//gl_FragData[5] = vec4(0.0f, 0.0f, 1.0f, alphamask);
	//gl_FragData[6] = vec4(0.0f, 0.0f, 0.0f, alphamask);

	if (fogMode == GL_EXP) {
		gl_FragData[0].rgb = mix(gl_FragData[0].rgb, (gl_Fog.color.rgb * 1.0), 1.0 - clamp(exp(-gl_Fog.density * gl_FogFragCoord), 0.0, 1.0));
	} else if (fogMode == GL_LINEAR) {
		gl_FragData[0].rgb = mix(gl_FragData[0].rgb, (gl_Fog.color.rgb * 1.0), clamp((gl_FogFragCoord - gl_Fog.start) * gl_Fog.scale, 0.0, 1.0));
	}

	//gl_FragData[7] = vec4(0.0f, 0.0f, 0.0f, 0.0f);

}
