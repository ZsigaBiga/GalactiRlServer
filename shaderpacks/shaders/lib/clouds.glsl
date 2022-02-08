
float GetCoverage(in float coverage, in float density, in float clouds)
{
	clouds = clamp(clouds - (1.0f - coverage), 0.0f, 1.0f -density) / (1.0f - density);
		clouds = max(0.0f, clouds * 1.1f - 0.1f);
	 // clouds = clouds = clouds * clouds * (3.0f - 2.0f * clouds);
	 // clouds = pow(clouds, 1.0f);
	return clouds;
}

vec4 CloudColor(in vec4 worldPosition, in float sunglow, in vec3 worldLightVector)
{

	float cloudHeight = 270.0f;
	float cloudDepth  = 200.0f;
	float cloudUpperHeight = cloudHeight + (cloudDepth / 2.0f);
	float cloudLowerHeight = cloudHeight - (cloudDepth / 2.0f);

	if (worldPosition.y < cloudLowerHeight || worldPosition.y > cloudUpperHeight)
		return vec4(0.0f);
	else
	{

		vec3 p = worldPosition.xyz / 150.0f;



		float t = frameTimeCounter * 0.5f;
			  //t *= 0.001;
		p.x -= t * 0.01f;

		// p += (Get3DNoise(p * 1.0f + vec3(0.0f, t * 0.01f, 0.0f)) * 2.0f - 1.0f) * 0.3f;

		vec3 p1 = p * vec3(1.0f, 0.5f, 1.0f)  + vec3(0.0f, t * 0.01f, 0.0f);
		float noise  = 	Get3DNoise(p * vec3(1.0f, 0.5f, 1.0f) + vec3(0.0f, t * 0.01f, 0.0f));	p *= 3.0f;	p.x -= t * 0.057f;	vec3 p2 = p;
			  noise += (1.0f - abs(Get3DNoise(p) * 1.0f - 0.5f)) * 0.2f;				p *= 3.0f;	p.xz -= t * 0.035f;	vec3 p3 = p;
			  noise += (1.0f - abs(Get3DNoise(p) * 3.0f - 1.0f)) * 0.045f;				p *= 3.0f;	p.xz -= t * 0.035f;
			  noise += (1.0f - abs(Get3DNoise(p) * 3.0f - 1.0f)) * 0.015f;
			  noise /= 1.475f;



		const float lightOffset = 0.45f;


		float heightGradient = clamp(( - (cloudLowerHeight - worldPosition.y) / (cloudDepth * 1.0f)), 0.0f, 1.0f);
		float heightGradient2 = clamp(( - (cloudLowerHeight - (worldPosition.y + worldLightVector.y * lightOffset * 30.0f)) / (cloudDepth * 1.0f)), 0.0f, 1.0f);

		float cloudAltitudeWeight = 1.0f - clamp(distance(worldPosition.y, cloudHeight) / (cloudDepth / 2.0f), 0.0f, 1.0f);
			  cloudAltitudeWeight = pow(cloudAltitudeWeight, mix(0.2f, 0.6f, rainStrength));
			  cloudAltitudeWeight *= 1.0f - heightGradient;

		float cloudAltitudeWeight2 = 1.0f - clamp(distance(worldPosition.y + worldLightVector.y * lightOffset * 30.0f, cloudHeight) / (cloudDepth / 2.0f), 0.0f, 1.0f);
			  cloudAltitudeWeight2 = pow(cloudAltitudeWeight2, mix(0.2f, 0.6f, rainStrength));
			  cloudAltitudeWeight2 *= 1.0f - heightGradient2;

		noise *= cloudAltitudeWeight;

		//cloud edge
		float coverage = 0.705f;
			  coverage = mix(coverage, 1.05f, rainStrength);
		float density = 0.66f;
		noise = clamp(noise - (1.0f - coverage), 0.0f, 1.0f - density) / (1.0f - density);
		//noise = GetCoverage(coverage, density, noise);

		//float sunProximity = pow(sunglow, 1.0f);
		//float propigation = mix(15.0f, 9.0f, sunProximity);


		// float directLightFalloff = pow(heightGradient, propigation);
		// 	  directLightFalloff += pow(heightGradient, propigation / 2.0f);
		// 	  directLightFalloff /= 2.0f;






		//float sundiff = -Get3DNoise(p1 + worldLightVector.xyz * lightOffset) * cloudAltitudeWeight2;
			  //sundiff += -(1.0f - abs(Get3DNoise(p2 + worldLightVector.xyz * lightOffset) * 1.0f - 0.5f)) * 0.4f * cloudAltitudeWeight2;
			  //sundiff += -(1.0f - abs(Get3DNoise(p3 + worldLightVector.xyz * lightOffset) * 3.0f - 1.0f)) * 0.035f * cloudAltitudeWeight2;
		float sundiff = Get3DNoise(p1 + worldLightVector.xyz * lightOffset);
			  sundiff += (1.0f - abs(Get3DNoise(p2 + worldLightVector.xyz * lightOffset) * 1.0f - 0.5f)) * 0.4f;
			  sundiff *= 0.9f;
			  sundiff *= cloudAltitudeWeight2;
			  //sundiff += (1.0f - abs(Get3DNoise(p3 + worldLightVector.xyz * lightOffset) * 3.0f - 1.0f)) * 0.075f * cloudAltitudeWeight2;
			  sundiff = -GetCoverage(coverage * 1.0f, 0.0f, sundiff);
		float firstOrder 	= pow(clamp(sundiff * 1.0f + 1.15f, 0.0f, 1.0f), 56.0f);
			  //firstOrder 	*= pow(clamp(1.3f - noise, 0.0f, 1.0f), 12.0f);
		float secondOrder 	= pow(clamp(sundiff * 1.0f + 1.1f, 0.0f, 1.0f), 11.0f);

			  //directLightFalloff *= mix(	clamp(pow(noise, 1.2f) * 1.0f, 0.0f, 1.0f), 	clamp(pow(1.0f - noise, 10.3f), 0.0f, 0.5f), 	pow(sunglow, 1.2f));




		float directLightFalloff = mix(firstOrder, secondOrder, 0.5f);
		//float directLightFalloff = firstOrder;
		float anisoBackFactor = mix(clamp(pow(noise, 1.6f) * 2.5f, 0.0f, 1.0f), 1.0f, pow(sunglow, 1.0f));

			  directLightFalloff *= anisoBackFactor;
		 	  directLightFalloff *= mix(6.5f, 1.0f, pow(sunglow, 0.25f));




		vec3 colorDirect = colorSunlight * 0.55f;
			 colorDirect = mix(colorDirect, colorDirect * vec3(0.2f, 0.5f, 1.0f), timeMidnight);
		//colorDirect *= 1.0f + pow(sunglow, 10.0f) * 0.0f * pow(directLightFalloff, 1.0f);
		colorDirect *= 1.0f + pow(sunglow, 2.0f) * 100.0f * pow(directLightFalloff, 1.1f) * (1.0f - rainStrength);
		//colorDirect *= mix(1.0f, (clamp(pow(1.1f - noise, 50.09f) * 1.0f, 0.0f, 1.0f)) * 5.0f + 1.0f, pow(sunglow, 1.5f));


		vec3 colorAmbient = mix(colorSkylight, colorSunlight * 2.0f, vec3(heightGradient * 0.0f)) * 0.03f;
			 //colorAmbient *= vec3(0.5f, 0.7f, 1.0f);
			 colorAmbient *= mix(1.0f, 0.3f, timeMidnight);
			 colorAmbient = mix(colorAmbient, colorAmbient * 3.0f + colorSunlight * 0.05f, vec3(clamp(pow(1.0f - noise, 12.0f) * 1.0f, 0.0f, 1.0f)));
			 colorAmbient *= heightGradient * heightGradient + 0.1f;

		 vec3 colorBounced = colorBouncedSunlight * 0.1f;
		 	 colorBounced *= pow((1.0f - heightGradient), 8.0f);


		directLightFalloff *= 1.0f - rainStrength * 0.7f;

		// //cloud shadows
		// vec4 shadowPosition = shadowModelView * (worldPosition - vec4(cameraPosition, 0.0f));
		// shadowPosition = shadowProjection * shadowPosition;
		// shadowPosition /= shadowPosition.w;

		// float dist = sqrt(shadowPosition.x * shadowPosition.x + shadowPosition.y * shadowPosition.y);
		// float distortFactor = (1.0f - SHADOW_MAP_BIAS) + dist * SHADOW_MAP_BIAS;
		// shadowPosition.xy *= 1.0f / distortFactor;
		// shadowPosition = shadowPosition * 0.5f + 0.5f;

		// float sunlightVisibility = shadow2D(shadow, vec3(shadowPosition.st, shadowPosition.z)).x;
		// directLightFalloff *= sunlightVisibility;

		vec3 color = mix(colorAmbient, colorDirect, vec3(min(1.0f, directLightFalloff)));
			 //color += colorBounced;
		     //color = colorAmbient;
		     //color = colorDirect * directLightFalloff;
			 //color *= clamp(pow(noise, 0.1f), 0.0f, 1.0f);

		color *= 0.9f;

		//color *= mix(1.0f, 0.4f, timeMidnight);

		vec4 result = vec4(color.rgb, noise);

		return result;
	}
}

void 	CalculateClouds (inout vec3 color, inout SurfaceStruct surface)
{
	//if (texcoord.s < 0.5f && texcoord.t < 0.5f)
	//{
		surface.cloudAlpha = 0.0f;

		vec2 coord = texcoord.st * 2.0f;

		vec4 worldPosition = gbufferModelViewInverse * surface.screenSpacePosition;
			 worldPosition.xyz += cameraPosition.xyz;

		float cloudHeight = 150.0f;
		float cloudDepth  = 60.0f;
		float cloudDensity = 1.0f;

		float startingRayDepth = far - 5.0f;

		float rayDepth = startingRayDepth;
			  //rayDepth += CalculateDitherPattern1() * 0.09f;
			  //rayDepth += texture2D(noisetex, texcoord.st * (viewWidth / noiseTextureResolution, viewHeight / noiseTextureResolution)).x * 0.1f;
			  //rayDepth += CalculateDitherPattern2() * 0.1f;
		float rayIncrement = far / 10.0f;

			  rayDepth += CalculateDitherPattern1() * rayIncrement;

		int i = 0;

		vec3 cloudColor = colorSunlight;
		vec4 cloudSum = vec4(0.0f);
			 cloudSum.rgb = colorSkylight * 0.2f;
			 cloudSum.rgb = color.rgb;

		float sunglow = CalculateSunglow(surface);

		float cloudDistanceMult = 650.0f / far;


		float surfaceDistance = length(worldPosition.xyz - cameraPosition.xyz);

		while (rayDepth > 0.0f)
		{
			//determine worldspace ray position
			vec4 rayPosition = GetCloudSpacePosition(texcoord.st, rayDepth, cloudDistanceMult);

			float rayDistance = length((rayPosition.xyz - cameraPosition.xyz) / cloudDistanceMult);

			vec4 proximity =  CloudColor(rayPosition, sunglow, surface.worldLightVector);
				 proximity.a *= cloudDensity;

				 //proximity.a *=  clamp(surfaceDistance - rayDistance, 0.0f, 1.0f);
				 if (surfaceDistance < rayDistance * cloudDistanceMult && !surface.mask.sky)
				 	proximity.a = 0.0f;

			//cloudSum.rgb = mix( cloudSum.rgb, proximity.rgb, vec3(min(1.0f, proximity.a * cloudDensity)) );
			//cloudSum.a += proximity.a * cloudDensity;
			color.rgb = mix(color.rgb, proximity.rgb, vec3(min(1.0f, proximity.a * cloudDensity)));

			surface.cloudAlpha += proximity.a;

			//Increment ray
			rayDepth -= rayIncrement;
			i++;

			 // if (rayDepth * cloudDistanceMult  < ((cloudHeight - (cloudDepth * 0.5)) - cameraPosition.y))
			 // {
			 // 	break;
			 // }
		}

		//color.rgb = mix(color.rgb, cloudSum.rgb, vec3(min(1.0f, cloudSum.a * 20.0f)));
		//color.rgb = cloudSum.rgb;
}

vec4 CloudColor(in vec4 worldPosition, in float sunglow, in vec3 worldLightVector, in float altitude, in float thickness)
{

	float cloudHeight = altitude;
	float cloudDepth  = thickness;
	float cloudUpperHeight = cloudHeight + (cloudDepth / 2.0f);
	float cloudLowerHeight = cloudHeight - (cloudDepth / 2.0f);

	worldPosition.xz /= 1.0f + max(0.0f, length(worldPosition.xz - cameraPosition.xz) / 3000.0f);

	vec3 p = worldPosition.xyz / 300.0f;




	float t = frameTimeCounter * 0.4f;
		  //t *= 0.001;
	p.x -= t * 0.01f;

	 p += (Get3DNoise(p * 1.0f + vec3(0.0f, t * 0.01f, 0.0f)) * 2.0f - 1.0f) * 0.3f;

	vec3 p1 = p * vec3(1.0f, 0.5f, 1.0f)  + vec3(0.0f, t * 0.01f, 0.0f);
	float noise  = 	Get3DNoise(p * vec3(1.0f, 0.5f, 1.0f) + vec3(0.0f, t * 0.01f, 0.0f));	p *= 2.0f;	p.x -= t * 0.057f;	vec3 p2 = p;
		  noise += (1.0f - abs(Get3DNoise(p) * 1.0f - 0.5f)) * 0.15f;						p *= 3.0f;	p.xz -= t * 0.035f;	vec3 p3 = p;
		  noise += (1.0f - abs(Get3DNoise(p) * 3.0f - 0.0f)) * 0.045f;						p *= 3.0f;	p.xz -= t * 0.035f;	vec3 p4 = p;
		  noise += (1.0f - abs(Get3DNoise(p) * 3.0f - 0.0f)) * 0.015f;						p *= 3.0f;	p.xz -= t * 0.035f;
		  noise += ((Get3DNoise(p))) * 0.015f;												p *= 3.0f;
		  noise += ((Get3DNoise(p))) * 0.006f;
		  noise /= 1.175f;



	const float lightOffset = 0.2f;


	float heightGradient = clamp(( - (cloudLowerHeight - worldPosition.y) / (cloudDepth * 1.0f)), 0.0f, 1.0f);
	float heightGradient2 = clamp(( - (cloudLowerHeight - (worldPosition.y + worldLightVector.y * lightOffset * 50.0f)) / (cloudDepth * 1.0f)), 0.0f, 1.0f);

	float cloudAltitudeWeight = 1.0f;

	float cloudAltitudeWeight2 = 1.0f;

	noise *= cloudAltitudeWeight;

	//cloud edge
	float coverage = 0.39f;
		  coverage = mix(coverage, 0.77f, rainStrength);

		  float dist = length(worldPosition.xz - cameraPosition.xz);
		  coverage *= max(0.0f, 1.0f - dist / 40000.0f);
	float density = 0.8f;
	noise = GetCoverage(coverage, density, noise);




	float sundiff = Get3DNoise(p1 + worldLightVector.xyz * lightOffset);
		  sundiff += Get3DNoise(p2 + worldLightVector.xyz * lightOffset / 2.0f) * 0.15f;
		  				float largeSundiff = sundiff;
		  				      largeSundiff = -GetCoverage(coverage, 0.0f, largeSundiff * 1.3f);
		  sundiff += Get3DNoise(p3 + worldLightVector.xyz * lightOffset / 5.0f) * 0.045f;
		  sundiff += Get3DNoise(p4 + worldLightVector.xyz * lightOffset / 8.0f) * 0.015f;
		  sundiff *= 1.3f;
		  sundiff *= cloudAltitudeWeight2;
		  sundiff = -GetCoverage(coverage * 1.0f, 0.0f, sundiff);
	float firstOrder 	= pow(clamp(sundiff * 1.0f + 1.1f, 0.0f, 1.0f), 12.0f);
	float secondOrder 	= pow(clamp(largeSundiff * 1.0f + 0.9f, 0.0f, 1.0f), 3.0f);



	float directLightFalloff = mix(firstOrder, secondOrder, 0.1f);
	float anisoBackFactor = mix(clamp(pow(noise, 1.6f) * 2.5f, 0.0f, 1.0f), 1.0f, pow(sunglow, 1.0f));

		  directLightFalloff *= anisoBackFactor;
	 	  directLightFalloff *= mix(11.5f, 1.0f, pow(sunglow, 0.5f));



	vec3 colorDirect = colorSunlight * 0.815f;
		 colorDirect = mix(colorDirect, colorDirect * vec3(0.2f, 0.5f, 1.0f), timeMidnight);
		 colorDirect *= 1.0f + pow(sunglow, 2.0f) * 300.0f * pow(directLightFalloff, 1.1f) * (1.0f - rainStrength);


	vec3 colorAmbient = mix(colorSkylight, colorSunlight * 2.0f, vec3(heightGradient * 0.0f + 0.15f)) * 0.36f;
		 colorAmbient *= mix(1.0f, 0.3f, timeMidnight);
		 colorAmbient = mix(colorAmbient, colorAmbient * 3.0f + colorSunlight * 0.05f, vec3(clamp(pow(1.0f - noise, 12.0f) * 1.0f, 0.0f, 1.0f)));
		 colorAmbient *= heightGradient * heightGradient + 0.1f;

	 vec3 colorBounced = colorBouncedSunlight * 0.1f;
	 	 colorBounced *= pow((1.0f - heightGradient), 8.0f);


	directLightFalloff *= 1.0f;
	//directLightFalloff += pow(Get3DNoise(p3), 2.0f) * 0.05f + pow(Get3DNoise(p4), 2.0f) * 0.015f;

	vec3 color = mix(colorAmbient, colorDirect, vec3(min(1.0f, directLightFalloff)));

	color *= 1.0f;

	vec4 result = vec4(color.rgb, noise);

	return result;

}

vec4 CloudColor2(in vec4 worldPosition, in float sunglow, in vec3 worldLightVector, in float altitude, in float thickness, const bool isShadowPass)
{

	float cloudHeight = altitude;
	float cloudDepth  = thickness;
	float cloudUpperHeight = cloudHeight + (cloudDepth / 2.0f);
	float cloudLowerHeight = cloudHeight - (cloudDepth / 2.0f);

	worldPosition.xz /= 1.0f + max(0.0f, length(worldPosition.xz - cameraPosition.xz) / 9001.0f);

	vec3 p = worldPosition.xyz / 100.0f;



	float t = frameTimeCounter * 0.4f;
		  t *= 0.4;


	 p += (Get3DNoise(p * 2.0f + vec3(0.0f, t * 0.01f, 0.0f)) * 2.0f - 1.0f) * 0.10f;

	  p.x -= (Get3DNoise(p * 0.125f + vec3(0.0f, t * 0.01f, 0.0f)) * 2.0f - 1.0f) * 1.2f;
	// p.xz -= (Get3DNoise(p * 0.0525f + vec3(0.0f, t * 0.01f, 0.0f)) * 2.0f - 1.0f) * 1.7f;


	p.x *= 0.25f;
	p.x -= t * 0.01f;

	vec3 p1 = p * vec3(1.0f, 0.5f, 1.0f)  + vec3(0.0f, t * 0.01f, 0.0f);
	float noise  = 	Get3DNoise(p * vec3(1.0f, 0.5f, 1.0f) + vec3(0.0f, t * 0.01f, 0.0f));	p *= 2.0f;	p.x -= t * 0.017f;	p.z += noise * 1.35f;	p.x += noise * 0.5f; 									vec3 p2 = p;
		  noise += (2.0f - abs(Get3DNoise(p) * 2.0f - 0.0f)) * (0.25f);						p *= 3.0f;	p.xz -= t * 0.005f;	p.z += noise * 1.35f;	p.x += noise * 0.5f; 	p.x *= 3.0f;	p.z *= 0.55f;	vec3 p3 = p;
		 	 p.z -= (Get3DNoise(p * 0.25f + vec3(0.0f, t * 0.01f, 0.0f)) * 2.0f - 1.0f) * 0.4f;
		  noise += (3.0f - abs(Get3DNoise(p) * 3.0f - 0.0f)) * (0.035f);					p *= 3.0f;	p.xz -= t * 0.005f;																					vec3 p4 = p;
		  noise += (3.0f - abs(Get3DNoise(p) * 3.0f - 0.0f)) * (0.025f);					p *= 3.0f;	p.xz -= t * 0.005f;
		  if (!isShadowPass)
		  {
		 		noise += ((Get3DNoise(p))) * (0.039f);												p *= 3.0f;
		  		 noise += ((Get3DNoise(p))) * (0.024f);
		  }
		  noise /= 1.575f;

	//cloud edge
	float rainy = mix(wetness, 1.0f, rainStrength);
		  //rainy = 0.0f;
	float coverage = 0.55f + rainy * 0.35f;
		  //coverage = mix(coverage, 0.97f, rainStrength);

		  float dist = length(worldPosition.xz - cameraPosition.xz);
		  coverage *= max(0.0f, 1.0f - dist / mix(10000.0f, 3000.0f, rainStrength));
	float density = 0.0f;

	if (isShadowPass)
	{
		return vec4(GetCoverage(coverage + 0.2f, density + 0.2f, noise));
	}
	else
	{

		noise = GetCoverage(coverage, density, noise);
		noise = noise * noise * (3.0f - 2.0f * noise);

		const float lightOffset = 0.2f;



		float sundiff = Get3DNoise(p1 + worldLightVector.xyz * lightOffset);
			  sundiff += (2.0f - abs(Get3DNoise(p2 + worldLightVector.xyz * lightOffset / 2.0f) * 2.0f - 0.0f)) * (0.55f);
			  				float largeSundiff = sundiff;
			  				      largeSundiff = -GetCoverage(coverage, 0.0f, largeSundiff * 1.3f);
			  sundiff += (3.0f - abs(Get3DNoise(p3 + worldLightVector.xyz * lightOffset / 5.0f) * 3.0f - 0.0f)) * (0.065f);
			  sundiff += (3.0f - abs(Get3DNoise(p4 + worldLightVector.xyz * lightOffset / 8.0f) * 3.0f - 0.0f)) * (0.025f);
			  sundiff /= 1.5f;
			  sundiff = -GetCoverage(coverage * 1.0f, 0.0f, sundiff);
		float secondOrder 	= pow(clamp(sundiff * 1.00f + 1.35f, 0.0f, 1.0f), 7.0f);
		float firstOrder 	= pow(clamp(largeSundiff * 1.1f + 1.56f, 0.0f, 1.0f), 3.0f);



		float directLightFalloff = secondOrder;
		float anisoBackFactor = mix(clamp(pow(noise, 1.6f) * 2.5f, 0.0f, 1.0f), 1.0f, pow(sunglow, 1.0f));

			  directLightFalloff *= anisoBackFactor;
		 	  directLightFalloff *= mix(11.5f, 1.0f, pow(sunglow, 0.5f));



		vec3 colorDirect = colorSunlight * 0.915f;
			 colorDirect = mix(colorDirect, colorDirect * vec3(0.2f, 0.5f, 1.0f), timeMidnight);
			 colorDirect *= 1.0f + pow(sunglow, 2.0f) * 100.0f * pow(directLightFalloff, 1.1f) * (1.0f - rainStrength);
			 // colorDirect *= 1.0f + pow(1.0f - sunglow, 2.0f) * 30.0f * pow(directLightFalloff, 1.1f) * (1.0f - rainStrength);


		vec3 colorAmbient = mix(colorSkylight, colorSunlight * 2.0f, vec3(0.15f)) * 0.04f;
			 colorAmbient *= mix(1.0f, 0.3f, timeMidnight);
			 colorAmbient *= mix(1.0f, ((1.0f - noise) + 0.5f) * 1.4f, rainStrength);
			 // colorAmbient = mix(colorAmbient, colorAmbient * 3.0f + colorSunlight * 0.05f, vec3(clamp(pow(1.0f - noise, 12.0f) * 1.0f, 0.0f, 1.0f)));


		directLightFalloff *= 1.0f - rainStrength * 0.75f;


		//directLightFalloff += (pow(Get3DNoise(p3), 2.0f) * 0.5f + pow(Get3DNoise(p3 * 1.5f), 2.0f) * 0.25f) * 0.02f;
		//directLightFalloff *= Get3DNoise(p2);

		vec3 color = mix(colorAmbient, colorDirect, vec3(min(1.0f, directLightFalloff)));

		color *= 1.0f;

		// noise *= mix(1.0f, 5.0f, sunglow);

		vec4 result = vec4(color, noise);

		return result;
	}

}

void CloudPlane(inout SurfaceStruct surface)
{
	//Initialize view ray
	vec4 worldVector = gbufferModelViewInverse * (-GetScreenSpacePosition(texcoord.st, 1.0f));

	surface.viewRay.dir = normalize(worldVector.xyz);
	surface.viewRay.origin = vec3(0.0f);

	float sunglow = CalculateSunglow(surface);



	float cloudsAltitude = 840.0f;
	float cloudsThickness = 150.0f;

	float cloudsUpperLimit = cloudsAltitude + cloudsThickness * 0.5f;
	float cloudsLowerLimit = cloudsAltitude - cloudsThickness * 0.5f;

	float density = 1.0f;

	if (cameraPosition.y < cloudsLowerLimit)
	{
		float planeHeight = cloudsUpperLimit;

		float stepSize = 25.5f;
		planeHeight -= cloudsThickness * 0.85f;
		//planeHeight += CalculateDitherPattern1() * stepSize;
		//planeHeight += CalculateDitherPattern() * stepSize;

		//while(planeHeight > cloudsLowerLimit)
		///{
			Plane pl;
			pl.origin = vec3(0.0f, cameraPosition.y - planeHeight, 0.0f);
			pl.normal = vec3(0.0f, 1.0f, 0.0f);

			Intersection i = RayPlaneIntersectionWorld(surface.viewRay, pl);

			if (i.angle < 0.0f)
			{
				if (i.distance < surface.linearDepth || surface.mask.sky)
				{
					 vec4 cloudSample = CloudColor2(vec4(i.pos.xyz * 0.5f + vec3(30.0f), 1.0f), sunglow, surface.worldLightVector, cloudsAltitude, cloudsThickness, false);
					 	 cloudSample.a = min(1.0f, cloudSample.a * density);

					surface.sky.albedo.rgb = mix(surface.sky.albedo.rgb, cloudSample.rgb, cloudSample.a);

					cloudSample = CloudColor2(vec4(i.pos.xyz * 0.65f + vec3(10.0f) + vec3(i.pos.z * 0.5f, 0.0f, 0.0f), 1.0f), sunglow, surface.worldLightVector, cloudsAltitude, cloudsThickness, false);
					cloudSample.a = min(1.0f, cloudSample.a * density);

					surface.sky.albedo.rgb = mix(surface.sky.albedo.rgb, cloudSample.rgb, cloudSample.a);

				}
			}

	}
}

float CloudShadow(in SurfaceStruct surface)
{
	float cloudsAltitude = 540.0f;
	float cloudsThickness = 150.0f;

	float cloudsUpperLimit = cloudsAltitude + cloudsThickness * 0.5f;
	float cloudsLowerLimit = cloudsAltitude - cloudsThickness * 0.5f;

	float planeHeight = cloudsUpperLimit;

	planeHeight -= cloudsThickness * 0.85f;

	Plane pl;
	pl.origin = vec3(0.0f, planeHeight, 0.0f);
	pl.normal = vec3(0.0f, 1.0f, 0.0f);

	//Cloud shadow
	Ray surfaceToSun;
	vec4 sunDir = gbufferModelViewInverse * vec4(surface.lightVector, 0.0f);
	surfaceToSun.dir = normalize(sunDir.xyz);
	vec4 surfacePos = gbufferModelViewInverse * surface.screenSpacePosition;
	surfaceToSun.origin = surfacePos.xyz + cameraPosition.xyz;

	Intersection i = RayPlaneIntersection(surfaceToSun, pl);

	float cloudShadow = CloudColor2(vec4(i.pos.xyz * 0.5f + vec3(30.0f), 1.0f), 0.0f, vec3(1.0f), cloudsAltitude, cloudsThickness, true).x;
		  cloudShadow += CloudColor2(vec4(i.pos.xyz * 0.65f + vec3(10.0f) + vec3(i.pos.z * 0.5f, 0.0f, 0.0f), 1.0f), 0.0f, vec3(1.0f), cloudsAltitude, cloudsThickness, true).x;

		  cloudShadow = min(cloudShadow, 1.0f);
		  cloudShadow = 1.0f - cloudShadow;

	return cloudShadow;
	// return 1.0f;
}
