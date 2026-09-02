Shader "Hidden/Snow/TrailAccumulation"
{
    Properties
    {
        [HideInInspector] _MainTex ("History Texture", 2D) = "white" {}
        //[HideInInspector] _CurrentTex ("Current Interaction Texture", 2D) = "black" {}
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
        }

        Cull Off
        ZWrite Off
        ZTest Always

        Pass
        {
            Name "AccumulateSnowTrail"

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            TEXTURE2D(_CurrentTex);
            SAMPLER(sampler_CurrentTex);

            float3 _OrthCamPos;
            float3 _LastFrameCamPos;
            float _OrthCamSize;

            float UVInRange(float2 uv)
            {
                return step(0.0, uv.x) * step(uv.x, 1.0) *
                       step(0.0, uv.y) * step(uv.y, 1.0);
            }

            half4 Frag(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

                float2 historyUV = input.texcoord;
                historyUV += ((_OrthCamPos.xz - _LastFrameCamPos.xz) * 0.5) /
                             max(_OrthCamSize, 0.0001);

                half4 history = SAMPLE_TEXTURE2D_X(
                    _BlitTexture,
                    sampler_LinearClamp,
                    historyUV) * UVInRange(historyUV);

                half4 current = SAMPLE_TEXTURE2D(
                    _CurrentTex,
                    sampler_CurrentTex,
                    input.texcoord);

                return max(history, current);
            }
            ENDHLSL
        }
    }

    Fallback Off
}
