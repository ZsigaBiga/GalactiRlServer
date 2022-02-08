varying vec4 color;
varying vec2 texcoord;

uniform sampler2D texture;

uniform float frameTimeCounter;


void main() {

  float glintSpeed = 0.15;


/* DRAWBUFFERS:0 */

  // 0 = gcolor
  // 1 = gdepth
  // 2 = gnormal
  // 3 = composite
  // 4 = gaux1
  // 5 = gaux2
  // 6 = gaux3
  // 7 = gaux4

  gl_FragData[0] = texture2D(texture, texcoord.st + vec2(frameTimeCounter * glintSpeed)) * color;

}
