Shader "Custom/Snow"
{
    Properties
    {
        // [HideInInspector]_OrthCamSize ("Orthognal Cam Size", Float) = 5.0
        // [HideInInspector]_OrthCamPos ("Orthognl Camera Position", Vector) = (0,0,0,0)
        _Tess("Tessellation", Range(1, 32)) = 8
        _MaxTessDistance("Max Tessellation Distance", Range(2, 100)) = 50
        _SnowHeight ("Snow Height", Float) = 0.0
        
        _MainColor ("MainColor", Color) = (0.0, 0.0, 0.0, 1.0)
        [HDR]_TrailColor ("TrailColor", Color) = (0.0, 0.0, 0.0, 1.0)
    }


    HLSLINCLUDE
 
    // Includes
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
    #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
    #include "DistanceTesselation.hlsl"

    CBUFFER_START(UnityPerMaterial)
        float4 _MainColor;
        float4 _TrailColor;
    CBUFFER_END

    ControlPoint TessellationVertexProgram(Attributes v)
    {
        ControlPoint p;
        p.vertex = v.vertex;
        p.uv = v.uv;
        p.normal = v.normal;
        return p;
    }
    ENDHLSL
 
    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
        }

        Pass
        {
            HLSLPROGRAM

            #pragma target 4.6
            #pragma require tessellation tessHW
            #pragma vertex TessellationVertexProgram
            #pragma hull hull
            #pragma domain domain
            #pragma fragment frag

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog

            


            float3 CalculateGeometricNormalWS(float3 positionWS)
            {
                float3 positionDX = ddx(positionWS);
                float3 positionDY = ddy(positionWS);

                return SafeNormalize(
                    cross(positionDY, positionDX)
                );
            }

            float3 NormalFromHeight(float height, float3 groundPositionWS)
            {
                float heightDx = ddx(height);
                float heightDy = ddy(height);

                // 未位移地面位置在屏幕 X/Y 方向上的变化
                float3 positionDx = ddx(groundPositionWS);
                float3 positionDy = ddy(groundPositionWS);

                // 给地面的两个切线方向加入贴图高度变化
                float3 displacedDx = positionDx + float3(0.0, heightDx, 0.0);

                float3 displacedDy = positionDy + float3(0.0, heightDy, 0.0);

                float3 normalWS = normalize(cross(displacedDy, displacedDx));

                normalWS = step(0, normalWS.y) * normalWS + step(normalWS.y, 0) * (-normalWS);

                return normalWS;
            
            }
            
           
      
            
            half4 frag(Varyings i) : SV_Target
            {
                
                float3 WorldNormal = CalculateGeometricNormalWS(i.WorldPos);

                float2 uv_Trail = 0.5 + (((i.GroundWorldPos.xz -_OrthCamPos.xz) * 0.5 )/ _OrthCamSize);
                half TrailFactor = UVInRange(uv_Trail) * SAMPLE_TEXTURE2D(_SnowTrailTex, sampler_SnowTrailTex, uv_Trail).g;

                float4 shadowCoord = TransformWorldToShadowCoord(i.WorldPos);
                Light mainLight = GetMainLight(shadowCoord);

                half shadow = mainLight.shadowAttenuation;
                half distanceAtten = mainLight.distanceAttenuation;
                half lightAttenuation = shadow * distanceAtten;
                half3 finalColor =  lerp(_MainColor, _TrailColor, TrailFactor);
                half EdgeMask = smoothstep(0, 1.0, distance(TrailFactor, 0.5));
                finalColor *= (1.0 - EdgeMask) * 0.3 + EdgeMask;
                finalColor *= lightAttenuation;
                return half4(finalColor, 1.0);
            }

            ENDHLSL
        }
    }
}
