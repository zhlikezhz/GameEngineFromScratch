////////////////////////////////////////////////////////////////////////////////
// Filename: pbr_ps.glsl
////////////////////////////////////////////////////////////////////////////////

/////////////////////
// INPUT VARIABLES //
/////////////////////
in vec4 normal;
in vec4 normal_world;
in vec4 v; 
in vec4 v_world;
in vec2 uv;

//////////////////////
// OUTPUT VARIABLES //
//////////////////////
out vec4 outputColor;

////////////////////////////////////////////////////////////////////////////////
// Pixel Shader
////////////////////////////////////////////////////////////////////////////////
void main()
{		
    vec3 N = normalize(normal_world.xyz);
    vec3 V = normalize(camPos - v_world.xyz);
    vec3 R = reflect(-V, N);   

    vec3 albedo;
    if (usingDiffuseMap)
    {
        albedo = texture(diffuseMap, uv).rgb; 
    }
    else
    {
        albedo = diffuseColor;
    }

    float meta = metallic;
    if (usingMetallicMap)
    {
        meta = texture(metallicMap, uv).r; 
    }

    float rough = roughness;
    if (usingRoughnessMap)
    {
        rough = texture(roughnessMap, uv).r; 
    }

    vec3 F0 = vec3(0.04f); 
    F0 = mix(F0, albedo, meta);
	           
    // reflectance equation
    vec3 Lo = vec3(0.0f);
    for (int i = 0; i < numLights; i++)
    {
        Light light = allLights[i];

        // calculate per-light radiance
        vec3 L = normalize(light.lightPosition.xyz - v_world.xyz);
        vec3 H = normalize(V + L);

        float NdotL = max(dot(N, L), 0.0f);

        // shadow test
        float visibility = shadow_test(v_world, light, NdotL);

        float lightToSurfDist = length(L);
        float lightToSurfAngle = acos(dot(-L, light.lightDirection.xyz));

        // angle attenuation
        float atten = apply_atten_curve(lightToSurfAngle, light.lightAngleAttenCurveParams);

        // distance attenuation
        atten *= apply_atten_curve(lightToSurfDist, light.lightDistAttenCurveParams);

        vec3 radiance = light.lightIntensity * atten * light.lightColor.rgb;
        
        // cook-torrance brdf
        float NDF = DistributionGGX(N, H, rough);        
        float G   = GeometrySmith(N, V, L, rough);      
        vec3 F    = fresnelSchlick(max(dot(H, V), 0.0f), F0);       
        
        vec3 kS = F;
        vec3 kD = vec3(1.0f) - kS;
        kD *= 1.0f - meta;	  
        
        vec3 numerator    = NDF * G * F;
        float denominator = 4.0f * max(dot(N, V), 0.0f) * NdotL;
        vec3 specular     = numerator / max(denominator, 0.001f);  
            
        // add to outgoing radiance Lo
        Lo += (kD * albedo / PI + specular) * radiance * NdotL * visibility; 
    }   
  
    vec3 ambient = ambientColor.rgb;
    {
        // ambient diffuse
        float ambientOcc = ao;
        if (usingAoMap)
        {
            ambientOcc = texture(aoMap, uv).r;
        }

        vec3 F = fresnelSchlickRoughness(max(dot(N, V), 0.0f), F0, rough);
        vec3 kS = F;
        vec3 kD = 1.0f - kS;
        kD *= 1.0f - meta;	  

        vec3 irradiance = textureLod(skybox, vec4(N, 0.0f), 1.0f).rgb;
        vec3 diffuse = irradiance * albedo;

        // ambient reflect
        const float MAX_REFLECTION_LOD = 8.0f;
        vec3 prefilteredColor = textureLod(skybox, vec4(R, 1.0f), rough * MAX_REFLECTION_LOD).rgb;    
        vec2 envBRDF  = texture(brdfLUT, vec2(max(dot(N, V), 0.0f), rough)).rg;
        vec3 specular = prefilteredColor * (F * envBRDF.x + envBRDF.y);

        ambient = (kD * diffuse + specular) * ambientOcc;
    }

    vec3 linearColor = ambient + Lo;
	
    // tone mapping
    linearColor = reinhard_tone_mapping(linearColor);
   
    // gamma correction
    linearColor = gamma_correction(linearColor);

    outputColor = vec4(linearColor, 1.0f);
}
