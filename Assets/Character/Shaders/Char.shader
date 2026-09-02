Shader "Char/Standard_URP"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _NormalMap ("Normal", 2D) = "bump" {}
        _CompMask ("CompMask (R:rough, G:metal, B:skin)", 2D) = "black" {}
        _LutTex ("Skin LUT", 2D) = "black" {}
        _EnvMap ("Env Cubemap", Cube) = "" {}

        _RoughnessAdjust ("Roughness Adjust", Range(-1,1)) = 0
        _MetallicAdjust ("Metallic Adjust", Range(-1,1)) = 0
        _Shininess ("Shininess", Range(1,256)) = 64

        _SSSIntensity ("SSS Intensity", Range(0,5)) = 1
        _LutuvOffsetX ("LUT U Offset", Range(-1,1)) = 0
        _LutuvOffsetY ("LUT V", Range(0,1)) = 0.5

        _Expose ("Env Expose", Range(0,10)) = 1
        _RotateY ("Env Rotate Y (deg)", Range(0,360)) = 0
    }

    SubShader
    {
        Tags { "RenderPipeline"="UniversalRenderPipeline" "Queue"="Geometry" "RenderType"="Opaque" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // URP lighting keywords (main light + shadows)
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_MainTex);        SAMPLER(sampler_MainTex);
            TEXTURE2D(_NormalMap);      SAMPLER(sampler_NormalMap);
            TEXTURE2D(_CompMask);       SAMPLER(sampler_CompMask);
            TEXTURE2D(_LutTex);         SAMPLER(sampler_LutTex);
            TEXTURECUBE(_EnvMap);       SAMPLER(sampler_EnvMap);

            float4 _MainTex_ST;
            float4 _NormalMap_ST;
            float4 _CompMask_ST;
            float4 _LutTex_ST;

            float _RoughnessAdjust;
            float _MetallicAdjust;
            float _Shininess;

            float _SSSIntensity;
            float _LutuvOffsetX;
            float _LutuvOffsetY;

            float _Expose;
            float _RotateY;

            float3 RotateAroundY_Deg(float deg, float3 v)
            {
                float rad = deg * (PI / 180.0);
                float s = sin(rad);
                float c = cos(rad);
                return float3(c * v.x + s * v.z, v.y, -s * v.x + c * v.z);
            }

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;

                float3 positionWS : TEXCOORD1;
                float3 normalWS   : TEXCOORD2;
                float3 tangentWS  : TEXCOORD3;
                float3 bitanWS    : TEXCOORD4;

                float4 shadowCoord : TEXCOORD5;
            };

            Varyings vert (Attributes v)
            {
                Varyings o;
                VertexPositionInputs posInputs = GetVertexPositionInputs(v.positionOS.xyz);
                VertexNormalInputs   nInputs   = GetVertexNormalInputs(v.normalOS, v.tangentOS);

                o.positionCS = posInputs.positionCS;
                o.positionWS = posInputs.positionWS;

                o.normalWS  = nInputs.normalWS;
                o.tangentWS = nInputs.tangentWS;
                o.bitanWS   = nInputs.bitangentWS;

                o.uv = TRANSFORM_TEX(v.uv, _MainTex);

                o.shadowCoord = GetShadowCoord(posInputs);

                return o;
            }

            float3 UnpackNormalTS(float4 packed)
            {
                // URP normal unpack
                return UnpackNormal(packed);
            }

            half4 frag (Varyings i) : SV_Target
            {
                // ===== Textures =====
                float2 uv = i.uv;

                float4 albedo = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                float3 comp   = SAMPLE_TEXTURE2D(_CompMask, sampler_CompMask, uv).rgb;

                // URP默认Linear：albedo采样若纹理勾选sRGB，会自动转linear；不要再 pow(2.2)
                float3 albedoLin = albedo.rgb;

                // 如果你强烈想“兼容旧观感”，可以试试打开下面这一行（不推荐长期用）
                // albedoLin = pow(albedo.rgb, 2.2);

                float metal     =  0.0f;
                //saturate(comp.g + _MetallicAdjust);
                float roughness = saturate(comp.r + _RoughnessAdjust);

                float skinMask = 1.0 - comp.b; // 你原逻辑：skin = 1 - B

                // ===== Normal (TS -> WS) =====
                float3 nWS = normalize(i.normalWS);
                float3 tWS = normalize(i.tangentWS);
                float3 bWS = normalize(i.bitanWS);
                float3x3 TBN = float3x3(tWS, bWS, nWS);

                float2 uvN = TRANSFORM_TEX(uv, _NormalMap);
                float3 nTS = UnpackNormalTS(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, uvN));
                float3 normalWS = normalize(mul(nTS, TBN));

                float3 viewWS = normalize(GetWorldSpaceViewDir(i.positionWS));

                // ===== Main Light (URP) =====
                Light mainLight = GetMainLight(i.shadowCoord);
                float3 lightDirWS = normalize(mainLight.direction);
                float3 lightCol    = mainLight.color;
                float  atten       = mainLight.shadowAttenuation; // 阴影衰减（URP）

                // ===== Direct Diffuse (Half-Lambert) =====
                float NdotL = dot(normalWS, lightDirWS);
                float halfLambert = (1.0 + NdotL) * 0.5;
                float3 baseCol = albedoLin * (1.0 - metal);
                float3 specCol = lerp(0.0.xxx, albedoLin, metal);

                float3 directDiffuse = lightCol * baseCol * halfLambert;

                // ===== Direct Specular (stylized Blinn-Phong) =====
                float3 halfDir = normalize(lightDirWS + viewWS);
                float NdotH = max(0.0, dot(normalWS, halfDir));
                float shininess = lerp(1.0, _Shininess, (1.0 - roughness));
                float specTerm = pow(NdotH, shininess);
                float3 directSpec = lightCol * specCol * specTerm * atten;

                // ===== Indirect Diffuse (SH) =====
                float3 sh = SampleSH(normalWS);
                float3 envDiffuse = sh * baseCol;

                // ===== Indirect Specular (cubemap LOD) =====
                // roughness remap: roughness *= (1 - 0.7*roughness)
                float r = roughness * (1.0 - 0.7 * roughness);
                float mip = r * 6.0;

                float3 reflDir = reflect(-viewWS, normalWS);
                reflDir = RotateAroundY_Deg(_RotateY, reflDir);
                float3 envSpec = SAMPLE_TEXTURECUBE_LOD(_EnvMap, sampler_EnvMap, reflDir, mip).rgb;
                envSpec *= specCol * _Expose;

                // ===== Skin SSS (LUT) =====
                float2 sssUV = float2(halfLambert + _LutuvOffsetX, _LutuvOffsetY);
                float3 sss = SAMPLE_TEXTURE2D(_LutTex, sampler_LutTex, sssUV).rgb;
                sss = sss * _SSSIntensity * baseCol * lightCol;
                sss *= 1.2;

                float3 finalDirectDiffuse = lerp(directDiffuse, sss, skinMask);

                // ===== Final =====
                float3 finalCol = saturate(envDiffuse * 0.7 + finalDirectDiffuse + directSpec + envSpec);
                finalCol = pow(finalCol, 1.0 / 1.5); // 保留你原先的艺术调色

                return half4(finalCol, 1.0);
            }
            ENDHLSL
        }
    }
    Fallback Off
}