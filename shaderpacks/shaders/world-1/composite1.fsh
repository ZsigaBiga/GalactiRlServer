#version 120
#extension GL_ARB_shader_texture_lod : enable

#define BANDING_FIX_FACTOR 1.0f
#define SMOOTH_SKY

/* DRAWBUFFERS:2 */

const bool gcolorMipmapEnabled = true;
const bool compositeMipmapEnabled = true;

uniform sampler2D gcolor;
uniform sampler2D gdepth;
uniform sampler2D gdepthtex;
uniform sampler2D gnormal;
uniform sampler2D composite;
uniform sampler2D noisetex;
//uniform sampler2D gaux1;

uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;
uniform float rainStrength;
uniform float wetness;
uniform float aspectRatio;
uniform float frameTimeCounter;
uniform int worldTime;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferPreviousProjection;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferPreviousModelView;
uniform mat4 shadowModelViewInverse;

uniform vec3 cameraPosition;
uniform vec3 previousCameraPosition;
uniform vec3 fogColor;

varying vec4 texcoord;

varying vec3 lightVector;
varying vec3 upVector;

varying float timeSunrise;
varying float timeNoon;
varying float timeSunset;
varying float timeMidnight;
varying float timeSkyDark;

varying vec3 colorSunlight;
varying vec3 colorSkylight;
varying vec3 colorBouncedSunlight;




#define animation_speed 1.0f

//#define ANIMATE_USING_WORLDTIME



#ifdef ANIMATE_USING_WORLDTIME
#define FRAME_TIME worldTime * animation_speed / 20.0f
#else
#define FRAME_TIME frameTimeCounter * animation_speed
#endif


/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////FUNCTIONS/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

vec3 GetNormals(in vec2 coord) {
	vec3 normal = vec3(0.0f);
		 normal = texture2DLod(gnormal, coord.st, 0).rgb;
	normal = normal * 2.0f - 1.0f;

	normal = normalize(normal);

	return normal;
}

float GetDepth(in vec2 coord) {
	return texture2D(gdepthtex, coord).x;
}

float 	ExpToLinearDepth(in float depth)
{
	return 2.0f * near * far / (far + near - (2.0f * depth - 1.0f) * (far - near));
}

float GetDepthLinear(vec2 coord) {
    return 2.0 * near * far / (far + near - (2.0 * texture2D(gdepthtex, coord).x - 1.0) * (far - near));
}

vec4  	GetViewSpacePosition(in vec2 coord) {	//Function that calculates the screen-space position of the objects in the scene using the depth texture and the texture coordinates of the full-screen quad
	float depth = GetDepth(coord);
		  //depth += float(GetMaterialMask(coord, 5)) * 0.38f;
	vec4 fragposition = gbufferProjectionInverse * vec4(coord.s * 2.0f - 1.0f, coord.t * 2.0f - 1.0f, 2.0f * depth - 1.0f, 1.0f);
		 fragposition /= fragposition.w;

	return fragposition;
}

float 	GetMaterialIDs(in vec2 coord) {			//Function that retrieves the texture that has all material IDs stored in it
	return texture2D(gdepth, coord).r;
}

float GetSunlightVisibility(in vec2 coord)
{
	return texture2D(gdepth, coord).g;
}

float cubicPulse(float c, float w, float x)
{
	x = abs(x - c);
	if (x > w) return 0.0f;
	x /= w;
	return 1.0f - x * x * (3.0f - 2.0f * x);
}

bool 	GetMaterialMask(in vec2 coord, in int ID, in float matID) {
		  matID = floor(matID * 255.0f);

	if (matID == ID) {
		return true;
	} else {
		return false;
	}
}

bool 	GetSkyMask(in vec2 coord, in float matID)
{
	matID = floor(matID * 255.0f);

	if (matID < 1.0f || matID > 254.0f)
	{
		return true;
	} else {
		return false;
	}
}

bool 	GetSkyMask(in vec2 coord)
{
	float matID = GetMaterialIDs(coord);
	matID = floor(matID * 255.0f);

	if (matID < 1.0f || matID > 254.0f)
	{
		return true;
	} else {
		return false;
	}
}

float 	GetSpecularity(in vec2 coord)
{
	return texture2D(composite, coord).r;
}

float 	GetRoughness(in vec2 coord)
{
	return texture2D(composite, coord).b;
}

//Water
float 	GetWaterTex(in vec2 coord) {				//Function that returns the texture used for water. 0 means "this pixel is not water". 0.5 and greater means "this pixel is water".
	return texture2D(gnormal, coord).b;		//values from 0.5 to 1.0 represent the amount of sky light hitting the surface of the water. It is used to simulate fake sky reflections in composite1.fsh
}

bool  	GetWaterMask(in float matID) {					//Function that returns "true" if a pixel is water, and "false" if a pixel is not water.
	matID = floor(matID * 255.0f);

	if (matID >= 35.0f && matID <= 51) {
		return true;
	} else {
		return false;
	}
}

bool  	GetWaterMask(in vec2 coord) {					//Function that returns "true" if a pixel is water, and "false" if a pixel is not water.
	float matID = floor(GetMaterialIDs(coord) * 255.0f);

	if (matID >= 35.0f && matID <= 51) {
		return true;
	} else {
		return false;
	}
}

float 	GetLightmapSky(in vec2 coord) {
	return texture2D(gdepth, texcoord.st).b;
}

vec3 convertScreenSpaceToWorldSpace(vec2 co) {
    vec4 fragposition = gbufferProjectionInverse * vec4(vec3(co, texture2DLod(gdepthtex, co, 0).x) * 2.0 - 1.0, 1.0);
    fragposition /= fragposition.w;
    return fragposition.xyz;
}

vec3 convertCameraSpaceToScreenSpace(vec3 cameraSpace) {
    vec4 clipSpace = gbufferProjection * vec4(cameraSpace, 1.0);
    vec3 NDCSpace = clipSpace.xyz / clipSpace.w;
    vec3 screenSpace = 0.5 * NDCSpace + 0.5;
		 screenSpace.z = 0.1f;
    return screenSpace;
}

float  	CalculateDitherPattern1() {
	int[16] ditherPattern = int[16] (0 , 9 , 3 , 11,
								 	 13, 5 , 15, 7 ,
								 	 4 , 12, 2,  10,
								 	 16, 8 , 14, 6 );

	vec2 count = vec2(0.0f);
	     count.x = floor(mod(texcoord.s * viewWidth, 4.0f));
		 count.y = floor(mod(texcoord.t * viewHeight, 4.0f));

	int dither = ditherPattern[int(count.x) + int(count.y) * 4];

	return float(dither) / 17.0f;
}

float  	CalculateDitherPattern2() {
	int[16] ditherPattern = int[16] (4 , 12, 2,  10,
								 	 16, 8 , 14, 6 ,
								 	 0 , 9 , 3 , 11,
								 	 13, 5 , 15, 7 );

	vec2 count = vec2(0.0f);
	     count.x = floor(mod(texcoord.s * viewWidth, 4.0f));
		 count.y = floor(mod(texcoord.t * viewHeight, 4.0f));

	int dither = ditherPattern[int(count.x) + int(count.y) * 4];

	return float(dither) / 17.0f;
}

vec3 	CalculateNoisePattern1(vec2 offset, float size) {
	vec2 coord = texcoord.st;

	coord *= vec2(viewWidth, viewHeight);
	coord = mod(coord + offset, vec2(size));
	coord /= 64.0f;

	return texture2D(noisetex, coord).xyz;
}

float noise (in float offset)
{
	vec2 coord = texcoord.st + vec2(offset);
	float noise = clamp(fract(sin(dot(coord ,vec2(12.9898f,78.233f))) * 43758.5453f),0.0f,1.0f)*2.0f-1.0f;
	return noise;
}

float noise (in vec2 coord, in float offset)
{
	coord += vec2(offset);
	float noise = clamp(fract(sin(dot(coord ,vec2(12.9898f,78.233f))) * 43758.5453f),0.0f,1.0f)*2.0f-1.0f;
	return noise;
}

void 	DoNightEye(inout vec3 color) {			//Desaturates any color input at night, simulating the rods in the human eye

	float amount = 0.8f; 						//How much will the new desaturated and tinted image be mixed with the original image
	vec3 rodColor = vec3(0.2f, 0.5f, 1.0f); 	//Cyan color that humans percieve when viewing extremely low light levels via rod cells in the eye
	float colorDesat = dot(color, vec3(1.0f)); 	//Desaturated color

	color = mix(color, vec3(colorDesat) * rodColor, timeSkyDark * amount);
	//color.rgb = color.rgb;
}


float Get3DNoise(in vec3 pos)
{
	pos.z += 0.0f;

	pos.xyz += 0.5f;

	vec3 p = floor(pos);
	vec3 f = fract(pos);

	f.x = f.x * f.x * (3.0f - 2.0f * f.x);
	f.y = f.y * f.y * (3.0f - 2.0f * f.y);
	f.z = f.z * f.z * (3.0f - 2.0f * f.z);

	vec2 uv =  (p.xy + p.z * vec2(17.0f)) + f.xy;
	vec2 uv2 = (p.xy + (p.z + 1.0f) * vec2(17.0f)) + f.xy;

	// uv -= 0.5f;
	// uv2 -= 0.5f;

	vec2 coord =  (uv  + 0.5f) / 64.0f;
	vec2 coord2 = (uv2 + 0.5f) / 64.0f;
	float xy1 = texture2D(noisetex, coord).x;
	float xy2 = texture2D(noisetex, coord2).x;
	return mix(xy1, xy2, f.z);
}

/////////////////////////STRUCTS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCTS///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

struct MaskStruct {

	float matIDs;

	bool sky;
	bool land;
	bool tallGrass;
	bool leaves;
	bool ice;
	bool hand;
	bool translucent;
	bool glow;
	bool goldBlock;
	bool ironBlock;
	bool diamondBlock;
	bool emeraldBlock;
	bool sand;
	bool sandstone;
	bool stone;
	bool cobblestone;
	bool wool;

	bool torch;
	bool lava;
	bool glowstone;
	bool fire;

	bool water;

};

struct Ray {
	vec3 dir;
	vec3 origin;
};

struct Plane {
	vec3 normal;
	vec3 origin;
};

struct SurfaceStruct {
	MaskStruct 		mask;			//Material ID Masks

	//Properties that are required for lighting calculation
		vec3 	color;					//Diffuse texture aka "color texture"
		vec3 	normal;					//Screen-space surface normals
		float 	depth;					//Scene depth
		float 	linearDepth;			//Scene depth

		float 	rDepth;
		float  	specularity;
		vec3 	specularColor;
		float 	roughness;
		float   fresnelPower;
		float 	baseSpecularity;
		Ray 	viewRay;


		vec4 	viewSpacePosition;
		vec4 	worldSpacePosition;
		vec3 	worldLightVector;
		vec3  	upVector;
		vec3 	lightVector;

		float 	sunlightVisibility;

		vec4 	reflection;

		float 	cloudAlpha;
} surface;

struct Intersection {
	vec3 pos;
	float distance;
	float angle;
};



/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////STRUCT FUNCTIONS//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

void 	CalculateMasks(inout MaskStruct mask) {
	mask.sky 			= GetSkyMask(texcoord.st, mask.matIDs);
	mask.land	 		= !mask.sky;
	mask.tallGrass 		= GetMaterialMask(texcoord.st, 2, mask.matIDs);
	mask.leaves	 		= GetMaterialMask(texcoord.st, 3, mask.matIDs);
	mask.ice		 	= GetMaterialMask(texcoord.st, 4, mask.matIDs);
	mask.hand	 		= GetMaterialMask(texcoord.st, 5, mask.matIDs);
	mask.translucent	= GetMaterialMask(texcoord.st, 6, mask.matIDs);

	mask.glow	 		= GetMaterialMask(texcoord.st, 10, mask.matIDs);

	mask.goldBlock 		= GetMaterialMask(texcoord.st, 20, mask.matIDs);
	mask.ironBlock 		= GetMaterialMask(texcoord.st, 21, mask.matIDs);
	mask.diamondBlock	= GetMaterialMask(texcoord.st, 22, mask.matIDs);
	mask.emeraldBlock	= GetMaterialMask(texcoord.st, 23, mask.matIDs);
	mask.sand	 		= GetMaterialMask(texcoord.st, 24, mask.matIDs);
	mask.sandstone 		= GetMaterialMask(texcoord.st, 25, mask.matIDs);
	mask.stone	 		= GetMaterialMask(texcoord.st, 26, mask.matIDs);
	mask.cobblestone	= GetMaterialMask(texcoord.st, 27, mask.matIDs);
	mask.wool			= GetMaterialMask(texcoord.st, 28, mask.matIDs);

	mask.torch 			= GetMaterialMask(texcoord.st, 30, mask.matIDs);
	mask.lava 			= GetMaterialMask(texcoord.st, 31, mask.matIDs);
	mask.glowstone 		= GetMaterialMask(texcoord.st, 32, mask.matIDs);
	mask.fire 			= GetMaterialMask(texcoord.st, 33, mask.matIDs);

	mask.water 			= GetWaterMask(mask.matIDs);
}

vec4 	ComputeRaytraceReflection(inout SurfaceStruct surface)
{
	float reflectionRange = 2.0f;
    float initialStepAmount = 1.0 - clamp(0.1f / 100.0, 0.0, 0.99);
		  initialStepAmount *= 4.0f;


	 // vec2 dither = CalculateNoisePattern1(vec2(0.0f), 4.0f).xy * 2.0f - 1.0f;
	 // vec3 ditherNormal = vec3(0.0f);
	 // 	 ditherNormal.x = dither.x;
	 // 	 ditherNormal.y = dither.y;
	 // 	 ditherNormal.z = sqrt(1.0f - dither.x * dither.x - dither.y * dither.y);
	 // 	 ditherNormal.z = -1.0f;

	 // 	 ditherNormal = normalize(ditherNormal);
	 // 	 ditherNormal -= normalize(surface.viewSpacePosition.xyz) * 1.0f;



    vec2 screenSpacePosition2D = texcoord.st;
    vec3 cameraSpacePosition = convertScreenSpaceToWorldSpace(screenSpacePosition2D);

    vec3 cameraSpaceNormal = surface.normal;
    	 //cameraSpaceNormal += ditherNormal * 0.65f * surface.roughness;

    vec3 cameraSpaceViewDir = normalize(cameraSpacePosition);
    vec3 cameraSpaceVector = initialStepAmount * normalize(reflect(cameraSpaceViewDir,cameraSpaceNormal));
    vec3 cameraSpaceVectorFar = far * normalize(reflect(cameraSpaceViewDir,cameraSpaceNormal));
	vec3 oldPosition = cameraSpacePosition;
    vec3 cameraSpaceVectorPosition = oldPosition + cameraSpaceVector;
    vec3 currentPosition = convertCameraSpaceToScreenSpace(cameraSpaceVectorPosition);
    vec4 color = vec4(pow(texture2D(gcolor, screenSpacePosition2D).rgb, vec3(3.0f + 1.2f)), 0.0);
    const int maxRefinements = 3;
	int numRefinements = 0;
    int count = 0;
	vec2 finalSamplePos = vec2(0.0f);

	int numSteps = 0;

    //while(count < far/initialStepAmount*reflectionRange)
    for (int i = 0; i < 40; i++)
    {
        if(currentPosition.x < 0 || currentPosition.x > 1 ||
           currentPosition.y < 0 || currentPosition.y > 1 ||
           currentPosition.z < 0 || currentPosition.z > 1 ||
           -cameraSpaceVectorPosition.z > far * 1.4f ||
           -cameraSpaceVectorPosition.z < 0.0f)
        {
		   break;
		}

        vec2 samplePos = currentPosition.xy;
        float sampleDepth = convertScreenSpaceToWorldSpace(samplePos).z;

        float currentDepth = cameraSpaceVectorPosition.z;
        float diff = sampleDepth - currentDepth;
        float error = length(cameraSpaceVector / pow(2.0f, numRefinements));

        //If a collision was detected, refine raymarch
        if(diff >= 0 && diff <= error * 2.00f && numRefinements <= maxRefinements)
        {
        	//Step back
        	cameraSpaceVectorPosition -= cameraSpaceVector / pow(2.0f, numRefinements);
        	++numRefinements;
		//If refinements run out
		}
		else if (diff >= 0 && diff <= error * 4.0f && numRefinements > maxRefinements)
		{
			finalSamplePos = samplePos;
			break;
		}



        cameraSpaceVectorPosition += cameraSpaceVector / pow(2.0f, numRefinements);

        if (numSteps > 1)
        cameraSpaceVector *= 1.375f;	//Each step gets bigger

		currentPosition = convertCameraSpaceToScreenSpace(cameraSpaceVectorPosition);
        count++;
        numSteps++;
    }

	color = pow(texture2DLod(gcolor, finalSamplePos, 0), vec4(2.2f));

	if (finalSamplePos.x == 0.0f || finalSamplePos.y == 0.0f) {
		color.a = 0.0f;
	}

	if (GetSkyMask(finalSamplePos))
		color.a = 0.0f;

	// if (GetWaterMask(finalSamplePos))
	// 	color.a = 0.0f;

	color.a *= clamp(1 - pow(distance(vec2(0.5), finalSamplePos)*2.0, 2.0), 0.0, 1.0);
	// color.a *= 1.0f - float(GetMaterialMask(finalSamplePos, 0, surface.mask.matIDs));

	//surface.color = vec3(numSteps / 10000000.0f);

    return color;
}

float 	CalculateLuminance(in vec3 color) {
	return (color.r * 0.2126f + color.g * 0.7152f + color.b * 0.0722f);
}

float   CalculateSunglow(in SurfaceStruct surface) {

	float curve = 4.0f;

	vec3 npos = normalize(surface.viewSpacePosition.xyz);
	vec3 halfVector2 = normalize(-surface.lightVector + npos);
	float factor = 1.0f - dot(halfVector2, npos);

	return factor * factor * factor * factor;
}

float   CalculateReflectedSunglow(in SurfaceStruct surface) {

	float curve = 4.0f;

	vec3 npos = normalize(surface.viewSpacePosition.xyz);
	surface.lightVector = reflect(surface.lightVector, surface.normal);
	vec3 halfVector2 = normalize(-surface.lightVector + npos);
	float factor = 1.0f - dot(halfVector2, npos);

	return factor * factor * factor * factor;
}

float   CalculateAntiSunglow(in SurfaceStruct surface) {

	float curve = 4.0f;

	vec3 npos = normalize(surface.viewSpacePosition.xyz);
	vec3 halfVector2 = normalize(surface.lightVector + npos);
	float factor = 1.0f - dot(halfVector2, npos);

	return factor * factor * factor * factor;
}

float   CalculateSunspot(in SurfaceStruct surface) {

	float curve = 1.0f;

	vec3 npos = normalize(surface.viewSpacePosition.xyz);
	vec3 halfVector2 = normalize(-surface.lightVector + npos);

	float sunProximity = abs(1.0f - dot(halfVector2, npos));

	//surface.roughness = 0.5f;

	float sizeFactor = 0.959f - surface.roughness * 0.7f;

	float sunSpot = (clamp(sunProximity, sizeFactor, 0.96f) - sizeFactor) / (0.96f - sizeFactor);
		  sunSpot = pow(cubicPulse(1.0f, 1.0f, sunSpot), 2.0f);

	// if (sunProximity > 0.96f) {
	// 	return 1.0f;
	// } else {
	// 	return 0.0f;
	// }

	float result = sunSpot / (surface.roughness * 20.0f + 0.1f);

		  result *= surface.sunlightVisibility;

	return result;
	//return 0.0f;
}

vec3 	ComputeReflectedSkyGradient(in SurfaceStruct surface) {
	float curve = 5.0f;
	surface.viewSpacePosition.xyz = reflect(surface.viewSpacePosition.xyz, surface.normal);
	vec3 npos = normalize(surface.viewSpacePosition.xyz);

	//surface.upVector = reflect(upVector, surface.normal);
	//surface.lightVector = reflect(lightVector, surface.normal);

	vec3 halfVector2 = normalize(-surface.upVector + npos);
	float skyGradientFactor = dot(halfVector2, npos);
	float skyGradientRaw = skyGradientFactor;
	float skyDirectionGradient = skyGradientFactor;

	if (dot(halfVector2, npos) > 0.75)
		skyGradientFactor = 1.5f - skyGradientFactor;

	skyGradientFactor = pow(skyGradientFactor, curve);

	vec3 skyColor = CalculateLuminance(pow(gl_Fog.color.rgb, vec3(2.2f))) * colorSkylight;

	skyColor *= mix(skyGradientFactor, 1.0f, clamp((0.12f - (timeNoon * 0.1f)) + rainStrength, 0.0f, 1.0f));
	skyColor *= pow(skyGradientFactor, 2.5f) + 0.2f;
	skyColor *= (pow(skyGradientFactor, 1.1f) + 0.425f) * 0.5f;
	skyColor.g *= skyGradientFactor * 3.0f + 1.0f;


	vec3 linFogColor = pow(gl_Fog.color.rgb, vec3(2.2f));

	float fogLum = max(max(linFogColor.r, linFogColor.g), linFogColor.b);


	float fadeSize = 0.0f;

	float fade1 = clamp(skyGradientFactor - 0.05f - fadeSize, 0.0f, 0.2f + fadeSize) / (0.2f + fadeSize);
		  fade1 = fade1 * fade1 * (3.0f - 2.0f * fade1);
	vec3 color1 = vec3(5.0f, 2.0, 0.7f) * 0.25f;
		 color1 = mix(color1, vec3(1.0f, 0.55f, 0.2f), vec3(timeSunrise + timeSunset));

	skyColor *= mix(vec3(1.0f), color1, vec3(fade1));

	float fade2 = clamp(skyGradientFactor - 0.11f - fadeSize, 0.0f, 0.2f + fadeSize) / (0.2f + fadeSize);
	vec3 color2 = vec3(1.7f, 1.0f, 0.8f) / 2.0f;
		 color2 = mix(color2, vec3(1.0f, 0.15f, 0.5f), vec3(timeSunrise + timeSunset));


	skyColor *= mix(vec3(1.0f), color2, vec3(fade2 * 0.5f));




	float horizonGradient = 1.0f - distance(skyDirectionGradient, 0.72f + fadeSize) / (0.72f + fadeSize);
		  horizonGradient = pow(horizonGradient, 10.0f);
		  horizonGradient = max(0.0f, horizonGradient);

	float sunglow = CalculateSunglow(surface);
		  horizonGradient *= sunglow * 2.0f+ (0.65f - timeSunrise * 0.55f - timeSunset * 0.55f);

	vec3 horizonColor1 = vec3(1.5f, 1.5f, 1.5f);
		 horizonColor1 = mix(horizonColor1, vec3(1.5f, 1.95f, 0.5f) * 2.0f, vec3(timeSunrise + timeSunset));
	vec3 horizonColor2 = vec3(1.5f, 1.2f, 0.8f) * 1.0f;
		 horizonColor2 = mix(horizonColor2, vec3(1.9f, 0.6f, 0.4f) * 2.0f, vec3(timeSunrise + timeSunset));

	skyColor *= mix(vec3(1.0f), horizonColor1, vec3(horizonGradient) * (1.0f - timeMidnight));
	skyColor *= mix(vec3(1.0f), horizonColor2, vec3(pow(horizonGradient, 2.0f)) * (1.0f - timeMidnight));

	float grayscale = fogLum / 20.0f;
		  grayscale /= 3.0f;

	float rainSkyBrightness = 1.2f;
		  rainSkyBrightness *= mix(0.05f, 10.0f, timeMidnight);

	skyColor = mix(skyColor, vec3(grayscale * colorSkylight.r) * 0.06f * vec3(0.85f, 0.85f, 1.0f), vec3(rainStrength));


	skyColor /= fogLum;


	float antiSunglow = CalculateAntiSunglow(surface);

	skyColor *= 1.0f + pow(sunglow, 1.1f) * (7.0f + timeNoon * 1.0f) * (1.0f - rainStrength);
	skyColor *= mix(vec3(1.0f), colorSunlight * 11.0f, clamp(vec3(sunglow) * (1.0f - timeMidnight) * (1.0f - rainStrength), vec3(0.0f), vec3(1.0f)));
	skyColor *= 1.0f + antiSunglow * 2.0f * (1.0f - rainStrength);


	if (surface.mask.water)
	{
		vec3 sunspot = vec3(CalculateSunspot(surface)) * colorSunlight;
			 sunspot *= 50.0f;
			 sunspot *= 1.0f - timeMidnight;
			 sunspot *= 1.0f - rainStrength;


		skyColor += sunspot;
	}

	skyColor *= pow(1.0f - clamp(skyGradientRaw - 0.75f, 0.0f, 0.25f) / 0.25f, 3.0f);

	skyColor *= mix(1.0f, 4.5f, timeNoon);


	return skyColor;
}

Intersection 	RayPlaneIntersectionWorld(in Ray ray, in Plane plane)
{
	float rayPlaneAngle = dot(ray.dir, plane.normal);

	float planeRayDist = 100000000.0f;
	vec3 intersectionPos = ray.dir * planeRayDist;

	if (rayPlaneAngle > 0.0001f || rayPlaneAngle < -0.0001f)
	{
		planeRayDist = dot((plane.origin), plane.normal) / rayPlaneAngle;
		intersectionPos = ray.dir * planeRayDist;
		intersectionPos = -intersectionPos;

		intersectionPos += cameraPosition.xyz;
	}

	Intersection i;

	i.pos = intersectionPos;
	i.distance = planeRayDist;
	i.angle = rayPlaneAngle;

	return i;
}



//	DoNightEye(color.rgb);

//	color.rgb *= mix(1.0f, 0.125f, timeMidnight);

//	return color;
//}

void 	CalculateSpecularReflections(inout SurfaceStruct surface) {

	float specularity = surface.specularity * surface.specularity * surface.specularity;
	      specularity = max(0.0f, specularity * 1.15f - 0.15f);
	surface.specularColor = vec3(1.0f);
	//surface.specularity = 1.0f;
	//surface.roughness *= surface.roughness;

	bool defaultItself = false;

	surface.rDepth = 0.0f;

	if (surface.mask.sky)
		specularity = 0.0f;

	if (surface.mask.water)
	{
		specularity = 0.7f;
		surface.roughness = 0.0f;
		surface.fresnelPower = 6.0f;
		surface.baseSpecularity = 0.02f;
	}

	if (surface.mask.ironBlock)
	{
		surface.baseSpecularity = 1.0f;
		//specularity = 1.0f;
		//surface.roughness = 0.0f;
	}

	if (surface.mask.goldBlock)
	{
		//surface.specularity = 1.0f;
		//surface.roughness = 0.4f;
		surface.baseSpecularity = 1.0f;
		surface.specularColor = vec3(1.0f, 0.32f, 0.002f);
		surface.specularColor = mix(surface.specularColor, vec3(1.0f), vec3(0.015f));
	}

	//surface.roughness = 0.0f;


	if (specularity > 0.00f) {

		vec3 noise3 = vec3(noise(0.0f), noise(1.0f), noise(2.0f));

		surface.normal += noise3 * 0.00f;

		vec4 reflection = ComputeRaytraceReflection(surface);
		//vec4 reflection = vec4(0.0f);

		float surfaceLightmap = GetLightmapSky(texcoord.st);


		vec3 noSkyToReflect = vec3(0.0f);

		if (defaultItself)
		{
			noSkyToReflect = surface.color.rgb;
		}


	


		reflection.rgb *= surface.specularColor;

		surface.color.rgb = mix(surface.color.rgb, reflection.rgb, vec3(reflection.a));
		surface.reflection = reflection;
	}
}

void CalculateSpecularHighlight(inout SurfaceStruct surface)
{
	if (!surface.mask.sky && !surface.mask.water)
	{
		//surface.specularity = 0.51f;
		//surface.roughness = 0.2f;

		vec3 halfVector = normalize(lightVector - normalize(surface.viewSpacePosition.xyz));

		float HdotN = max(0.0f, dot(halfVector, surface.normal.xyz));

		//surface.roughness = sin(FRAME_TIME * 3.1415f) * 0.5f + 0.5f;

		float gloss = pow(1.0f - surface.roughness + 0.01f, 4.5f);

		HdotN = clamp(HdotN * (1.0f + gloss * 0.01f), 0.0f, 1.0f);

		float spec = pow(HdotN, gloss * 8000.0f + 10.0f);

		//spec *= float(!surface.mask.sky);

		float fresnel = pow(clamp(1.0f + dot(normalize(surface.viewSpacePosition.xyz), surface.normal.xyz), 0.0f, 1.0f), surface.fresnelPower) * (1.0f - surface.baseSpecularity) + surface.baseSpecularity;


		spec *= fresnel;
		spec *= surface.sunlightVisibility;

		//spec *= pow(1.0f - surface.roughness, 1.5f) * 80000.0f;
		spec *= gloss * 9000.0f + 10.0f;
		spec *= surface.specularity * surface.specularity * surface.specularity;
		spec *= 1.0f - rainStrength;

		vec3 specularHighlight = spec * mix(colorSunlight, vec3(0.2f, 0.5f, 1.0f) * 0.0005f, vec3(timeMidnight)) * surface.specularColor;


		surface.color += specularHighlight / 500.0f;
	}
}

void CalculateGlossySpecularReflections(inout SurfaceStruct surface)
{
	float specularity = surface.specularity;
	float roughness = 0.7f;
	float spread = 0.02f;

	specularity *= 1.0f - float(surface.mask.sky);

	vec4 reflectionSum = vec4(0.0f);

	surface.fresnelPower = 6.0f;
	surface.baseSpecularity = 0.0f;

	if (surface.mask.ironBlock)
	{
		roughness = 0.9f;
		//specularity = 1.0f;
		//surface.baseSpecularity = 1.0f;
	}

	if (surface.mask.goldBlock)
	{
		specularity = 0.0f;
	}



	if (specularity > 0.01f)
	{
		float fresnel = 1.0f - clamp(-dot(normalize(surface.viewSpacePosition.xyz), surface.normal.xyz), 0.0f, 1.0f);

		for (int i = 1; i <= 10; i++)
		{
			vec2 translation = vec2(surface.normal.x, surface.normal.y) * i * spread;
				 translation *= vec2(1.0f, viewWidth / viewHeight);
			//vec2 scaling = (4.0f - vec2(fresnel) * 3.0f);

			float faceFactor = surface.normal.z;
				  faceFactor *= spread * 13.0f;

			vec2 scaling = vec2(1.0f + faceFactor * (i / 10.0f) * 2.0f);

			float r = float(i) + 4.0f;
				  r *= roughness * 0.8f;
			int 	ri = int(floor(r));
			float 	rf = fract(r);

			vec2 finalCoord = (((texcoord.st * 2.0f - 1.0f) * scaling) * 0.5f + 0.5f) + translation;

			float weight = (11 - i + 1) / 10.0f;
			reflectionSum.rgb += pow(texture2DLod(gcolor, finalCoord, r).rgb, vec3(2.2f));
		}



		reflectionSum.rgb /= 10.0f;

		fresnel *= 0.9;
		fresnel = pow(fresnel, surface.fresnelPower);

		surface.color = mix(surface.color, reflectionSum.rgb * 1.0f, vec3(specularity) * fresnel * (1.0f - surface.baseSpecularity) + surface.baseSpecularity);
		}
	//surface.color.rgb *= vec3(1.0f) + reflectionSum.rgb * 400000.2f;
}

vec4 TextureSmooth(in sampler2D tex, in vec2 coord, in int level)
{
	vec2 res = vec2(viewWidth, viewHeight);
	coord = coord * res + 0.5f;
	vec2 i = floor(coord);
	vec2 f = fract(coord);
	f = f * f * (3.0f - 2.0f * f);
	coord = i + f;
	coord = (coord - 0.5f) / res;
	return texture2D(tex, coord, level);
}


///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////////MAIN//////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
void main() {

	surface.color = pow(texture2DLod(gcolor, texcoord.st, 0).rgb, vec3(2.2f));
	surface.normal = GetNormals(texcoord.st);
	surface.depth = GetDepth(texcoord.st);
	surface.linearDepth 		= ExpToLinearDepth(surface.depth); 				//Get linear scene depth
	surface.viewSpacePosition = GetViewSpacePosition(texcoord.st);
	surface.worldSpacePosition = gbufferModelViewInverse * surface.viewSpacePosition;
	surface.lightVector = lightVector;
	surface.sunlightVisibility = GetSunlightVisibility(texcoord.st);
	surface.upVector 	= upVector;
	vec4 wlv 					= shadowModelViewInverse * vec4(0.0f, 0.0f, 0.0f, 1.0f);
	surface.worldLightVector 	= normalize(wlv.xyz);

	surface.specularity = GetSpecularity(texcoord.st);
	surface.roughness = 1.0f - GetRoughness(texcoord.st);
	surface.fresnelPower = 6.0f + surface.roughness * 0.0f;
	surface.baseSpecularity = 0.02f;

	surface.mask.matIDs = GetMaterialIDs(texcoord.st);
	CalculateMasks(surface.mask);


	CalculateSpecularReflections(surface);
	CalculateSpecularHighlight(surface);
	//CalculateGlossySpecularReflections(surface);


	// surface.color = surface.normal * 0.0001f;

	//surface.color = vec3(fwidth(surface.depth)) * 0.01f;

	//surface.color.rgb = surface.reflection.rgb;


	surface.color = pow(surface.color, vec3(1.0f / 2.2f));
	gl_FragData[0] = vec4(surface.color, 1.0f);
	//gl_FragData[1] = vec4(texture2D(composite, texcoord.st).r, cloudAlpha, texture2D(composite, texcoord.st).b, 1.0f);


}
