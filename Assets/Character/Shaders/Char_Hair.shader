Shader "char_Hair"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("NormalMap", 2D) = "bump" {}
        _AnisoMap ("AnisoMap", 2D) = "white" {}

        _SpecColor1 ("SpecColor1", Color) = (1, 1, 1, 1)
        _SpecNoise1 ("SpecNoise1", Range(0.0, 2.5)) = 1.0
        _SpecOffset1 ("SpecOffset1", Range(0.01, 0.5)) = 0.0

        _Shininess ("Shininess", Range(0.01, 0.1)) = 0.01

        _SpecColor2 ("SpecColor2", Color) = (1, 1, 1, 1)
        _SpecNoise2 ("SpecNoise2", Range(0.0, 2.5)) = 1.0
        _SpecOffset2 ("SpecOffset2", Range(0.01, 0.5)) = 0.0

        _Shininess2 ("Shininess2", Range(0.01, 0.1)) = 10.0

        _EnvMap ("EnvMap", Cube) = "_Skybox" {}
        _RotateY ("RotateY", Range(0, 360)) = 0.0
        _Expose ("Expose", range(0.0, 1.0)) = 0.0
        _RoughnessAdjust ("RoughnessAdjust", Range(-1, 1)) = 0.0
    }

    SubShader
    {
        // --- URP 需要这些 Tags ---
        Tags
        {
            "RenderType"="Opaque"
            "RenderPipeline"="UniversalRenderPipeline"
            "Queue"="Geometry"
        }

        LOD 100

        Pass
        {
            // --- Built-in: ForwardBase -> URP: UniversalForward ---
            Tags { "LightMode" = "UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // --- URP 主光/阴影关键词 ---
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            // --- URP includes ---
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            // ===== 保留原变量名（只是改成URP采样声明方式） =====
            TEXTURE2D(_MainTex);      SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalMap);    SAMPLER(sampler_NormalMap);
            TEXTURE2D(_AnisoMap);     SAMPLER(sampler_AnisoMap);
            TEXTURECUBE(_EnvMap);     SAMPLER(sampler_EnvMap);

            half4 _AnisoMap_ST;
            half4 _SpecColor1;
            half  _SpecNoise1;
            half  _SpecOffset1;
            half4 _SpecColor2;
            half  _SpecNoise2;
            half  _SpecOffset2;

            half  _Shininess;
            half  _Shininess2;

            half  _RotateY;
            half  _Expose;
            half  _RoughnessAdjust;

            // ===== 原 RotateAroundY 函数保留 =====
            half3 RotateAroundY(half3 degree, half3 target)
            {
                half rad = degree * 3.14 / 180;
                half2x2 m_rotate = half2x2(cos(rad), -sin(rad),
                    sin(rad), cos(rad));
                half2 dir_rotate = mul(m_rotate, target.xz);
                target = half3(dir_rotate.x, target.y, dir_rotate.y);
                return target;
            }

            struct appdata
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 worldpos : TEXCOORD1;
                float3 normal_world : TEXCOORD2;
                float3 tangent_world : TEXCOORD3;
                float3 binormal_world : TEXCOORD4;

                // --- Built-in LIGHTING_COORDS -> URP shadowCoord ---
                float4 shadowCoord : TEXCOORD5;
            };

            v2f vert (appdata v)
            {
                v2f o;

                // --- Built-in: UnityObjectToClipPos / UnityObjectToWorldNormal -> URP Inputs ---
                VertexPositionInputs posInputs = GetVertexPositionInputs(v.vertex.xyz);
                VertexNormalInputs   nInputs   = GetVertexNormalInputs(v.normal, v.tangent);

                o.pos = posInputs.positionCS;
                o.worldpos = posInputs.positionWS;

                o.uv = v.texcoord;

                o.normal_world  = normalize(nInputs.normalWS);
                o.tangent_world = normalize(nInputs.tangentWS);
                o.binormal_world = normalize(nInputs.bitangentWS);

                // --- URP 阴影坐标 ---
                o.shadowCoord = GetShadowCoord(posInputs);

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                //Tex info
                half4 albedoCol = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.uv);
                half4 albedoCol_Linear = pow(albedoCol, 2.2);
                half3 baseCol_Linear = albedoCol_Linear.rgb;
                half3 specCol_Linear = baseCol_Linear;

                half roughness = saturate(_RoughnessAdjust);
                half3 normalData = UnpackNormal(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, i.uv));

                //Dir
                half3 normal_world = normalize(i.normal_world);
                half3 tangent_world = normalize(i.tangent_world);
                half3 binormal_world = normalize(i.binormal_world);
                half3x3 TBN = half3x3(tangent_world, binormal_world, normal_world);

                // 原 shader 这里虽然算了 normalData，但最终 normal 用 normal_world（保留原逻辑不改）
                half3 normal = normal_world;

                half3 viewDir = normalize(_WorldSpaceCameraPos - i.worldpos);
                half3 reflectDir = reflect(-viewDir.xyz, normal);

                // ===== Light Info (URP替换部分) =====
                Light mainLight = GetMainLight(i.shadowCoord);

                half3 lightDir = normalize(mainLight.direction);
                half  atten = mainLight.shadowAttenuation;

                // 用局部变量保留原来的 _LightColor0 名称用法
                half3 _LightColor0 = mainLight.color;

                //Direct Diffuse
                half NdotL = dot(normal, lightDir);
                half half_Lambert = (1.0 +  NdotL) * 0.5; //half-Lambert
                half3 diffuseCol_dirLight_common = _LightColor0.rgb * baseCol_Linear.rgb * half_Lambert;

                half3 diffuseCol_dirLight = diffuseCol_dirLight_common;

                //Direct Specular
                half2 aniso_uv = i.uv * _AnisoMap_ST.xy + _AnisoMap_ST.zw;
                half aniso_noise = SAMPLE_TEXTURE2D(_AnisoMap, sampler_AnisoMap, aniso_uv).r - 0.5;

                half3 halfDir = normalize(lightDir + viewDir);
                half NdotH = dot(normal, halfDir);
                half TdotH = dot(tangent_world, halfDir);

                half NdotV = max(0.0, dot(normal, viewDir));
                float aniso_atten = saturate(sqrt(max(0.0, half_Lambert / NdotV))) * atten;

                //spec1
                half3 spec_Col1 = _SpecColor1.rgb + baseCol_Linear;
                float3 aniso_offset1 = normal_world * (aniso_noise * _SpecNoise1 + _SpecOffset1);
                float3 binormal1 = normalize(binormal_world + aniso_offset1);
                float BdotH1 = dot(binormal1, halfDir) / _Shininess;
                float3 spec_term1 = exp(-(TdotH * TdotH + BdotH1 * BdotH1) / (1.0 + NdotH));
                float3 final_spec1 = spec_term1 * _LightColor0.rgb * aniso_atten * spec_Col1;

                //spec2
                half3 spec_Col2 = _SpecColor2.rgb + baseCol_Linear;
                float3 aniso_offset2 = normal_world * (aniso_noise * _SpecNoise2 + _SpecOffset2);
                float3 binormal2 = normalize(binormal_world + aniso_offset2);
                float BdotH2 = dot(binormal2, halfDir) / _Shininess2;

                // 保留你原公式：BdotH1 * BdotH2（不擅自改成 BdotH2^2）
                float3 spec_term2 = exp(-(TdotH * TdotH + BdotH1 * BdotH2) / (1.0 + NdotH));
                float3 final_spec2 = spec_term2 * _LightColor0.rgb * aniso_atten * spec_Col2;

                //Indirect Specular
                roughness *= (1.0 - 0.7 * roughness);
                half miplevel = roughness * 6.0;

                reflectDir = RotateAroundY(_RotateY, reflectDir);//Rotation

                // Built-in: texCUBElod -> URP: SAMPLE_TEXTURECUBE_LOD
                half3 col_envmap = SAMPLE_TEXTURECUBE_LOD(_EnvMap, sampler_EnvMap, reflectDir, miplevel).rgb;
                half3 env_specular = col_envmap.rgb * _Expose * aniso_noise;

                half3 finalCol = final_spec1 + final_spec2 + diffuseCol_dirLight + env_specular;
                finalCol = pow(finalCol, 1.0 / 2.2);

                return saturate(half4(finalCol, 1.0));
            }
            ENDHLSL
        }
    }

    Fallback Off
}