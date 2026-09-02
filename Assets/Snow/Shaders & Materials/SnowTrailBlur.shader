Shader "Hidden/Snow/TrailBlur"
{
    Properties
    {
        [HideInInspector] _MainTex ("Source Texture", 2D) = "black" {}
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

        HLSLINCLUDE
        #pragma target 3.5
        #pragma vertex Vert

        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

        float _BlurRadius;

        half4 SampleGaussian(float2 uv, float2 direction)
        {
            float2 offset1 = direction * (1.3846153846 * _BlurRadius);
            float2 offset2 = direction * (3.2307692308 * _BlurRadius);

            half4 color = SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv) * 0.2270270270;
            color += SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv + offset1) * 0.3162162162;
            color += SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv - offset1) * 0.3162162162;
            color += SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv + offset2) * 0.0702702703;
            color += SAMPLE_TEXTURE2D_X(_BlitTexture, sampler_LinearClamp, uv - offset2) * 0.0702702703;
            return color;
        }
        ENDHLSL

        Pass
        {
            Name "BlurHorizontal"

            HLSLPROGRAM
            #pragma fragment FragHorizontal

            half4 FragHorizontal(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                return SampleGaussian(input.texcoord, float2(_BlitTexture_TexelSize.x, 0.0));
            }
            ENDHLSL
        }

        Pass
        {
            Name "BlurVertical"

            HLSLPROGRAM
            #pragma fragment FragVertical

            half4 FragVertical(Varyings input) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
                return SampleGaussian(input.texcoord, float2(0.0, _BlitTexture_TexelSize.y));
            }
            ENDHLSL
        }
    }

    Fallback Off
}
