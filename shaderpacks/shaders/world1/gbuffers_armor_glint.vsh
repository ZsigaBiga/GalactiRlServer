//#define shakingCamera

varying vec4 color;
varying vec2 texcoord;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;

uniform float frameTimeCounter;


void main() {

  texcoord = gl_MultiTexCoord0.st;
  color    = gl_Color;

	vec4 position = gbufferModelViewInverse * gl_ModelViewMatrix * gl_Vertex;

  #ifdef shakingCamera
		position.xy += vec2(0.01 * sin(frameTimeCounter * 2.0), 0.01 * cos(frameTimeCounter * 3.0));
	#endif

	gl_Position = gl_ProjectionMatrix * gbufferModelView * position;

}
