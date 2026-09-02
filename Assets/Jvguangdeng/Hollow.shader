// Made with Amplify Shader Editor v1.9.9.4
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Hollow"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		_RimColor( "RimColor", Color ) = ( 0, 0, 0, 0 )
		_RimColor2( "RimColor2", Color ) = ( 0, 0, 0, 0 )
		_RimWidth( "RimWidth", Range( 0, 1 ) ) = 0.99
		_Radius( "Radius", Range( 0, 0.5 ) ) = 0
		_MainTex( "MainTex", 2D ) = "white" {}
		_MainTexTilling( "MainTexTilling", Float ) = 1
		_RotateSpeed( "RotateSpeed", Float ) = 0
		_NoiseScale( "NoiseScale", Float ) = 0
		_NoiseIntense( "NoiseIntense", Float ) = 0
		_Float0( "Float 0", Range( -1, 1 ) ) = 0

		[HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" }

		Cull Off

		HLSLINCLUDE
		#pragma target 2.0
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		ENDHLSL

		
		Pass
		{
			Name "Sprite Unlit"
            Tags { "LightMode"="Universal2D" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZTest LEqual
			ZWrite Off
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM

			#define ASE_VERSION 19904
			#define ASE_SRP_VERSION 140012


			#pragma vertex vert
			#pragma fragment frag

            #define _SURFACE_TYPE_TRANSPARENT 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_COLOR
            #define FEATURES_GRAPH_VERTEX

			#define SHADERPASS SHADERPASS_SPRITEUNLIT

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
           

			
            #if ASE_SRP_VERSION >=140009
			#include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/Shaders/2D/Include/SurfaceData2D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging2D.hlsl"

			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0


			float ParticleInitSize[100];
			float ParticleSize[100];
			float4 ParticlePos[100];
			sampler2D _MainTex;
			CBUFFER_START( UnityPerMaterial )
			float4 _RimColor;
			float4 _RimColor2;
			float _MainTexTilling;
			float _NoiseIntense;
			float _RotateSpeed;
			float _NoiseScale;
			float _Radius;
			float _Float0;
			float _RimWidth;
			CBUFFER_END


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 uv0 : TEXCOORD0;
				float4 color : COLOR;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 texCoord0 : TEXCOORD0;
				float4 color : TEXCOORD1;
				float3 positionWS : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#if ETC1_EXTERNAL_ALPHA
				TEXTURE2D(_AlphaTex); SAMPLER(sampler_AlphaTex);
				float _EnableAlphaTexture;
			#endif

			float4 _RendererColor;

			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			
			float PartRimInner41( float3 WorldPos, float ArrayLength )
			{
				float result = 0.0;
				float innerCut = 0.0;
					for(int j = 0; j < 100; j++)
					{
						float dist2center = distance(WorldPos.xyz,  ParticlePos[j].xyz);
						float rimRange = step(ParticleSize[j], dist2center);
						rimRange = 1 - rimRange;
						
						innerCut += rimRange;
					}
					result = 1 - saturate(innerCut);
					return saturate(result);
			}
			
			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float3 RGBToHSV(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
				float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
				float d = q.x - min( q.w, q.y );
				float e = 1.0e-10;
				return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}
			float coord2theta152( float x, float y )
			{
				float theta = atan2(y, x);          // (-PI, PI]
				theta = (theta < 0) ? theta + 6.2831853 : theta; // 0..2PI
				return theta; // 弧度
			}
			
			float PartRim9( float3 WorldPos, float RimWidth, float partInner, float ArrayLength )
			{
				float result = 0.0;
								for(int j = 0; j < 100; j++)
								{
									float rimProportion = 1.0 * ParticleSize[j] / ParticleInitSize[j];
									float3 direction = normalize(WorldPos.xyz - ParticlePos[j].xyz);
									float3 rimPos = ParticlePos[j].xyz + direction * ParticleSize[j];
									float rim = distance(rimPos, WorldPos.xyz);		
									rim = smoothstep(1.0 - rimProportion, 1, 1 - saturate(rim));
									result += rim;
									
								}
								result *= partInner;
								return saturate(result);
			}
			

			VertexOutput vert( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_positionWS = TransformObjectToWorld( ( v.positionOS ).xyz );
				o.ase_texcoord3.xyz = ase_positionWS;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif
				v.normal = v.normal;
				v.tangent.xyz = v.tangent.xyz;

				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);

				o.positionCS = vertexInput.positionCS;
				o.positionWS = vertexInput.positionWS;
				o.texCoord0 = v.uv0;
				o.color = v.color;
				return o;
			}

			half4 frag( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				float2 temp_cast_0 = (_MainTexTilling).xx;
				float2 texCoord130 = IN.texCoord0.xy * temp_cast_0 + float2( 0,0 );
				float2 texCoord83 = IN.texCoord0.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_1 = (0.1).xx;
				float2 temp_cast_2 = (0.9).xx;
				float2 temp_cast_3 = (0.5).xx;
				float2 break92 = (  (temp_cast_1 + ( texCoord83 - float2( 0,0 ) ) * ( temp_cast_2 - temp_cast_1 ) / ( float2( 1,1 ) - float2( 0,0 ) ) ) - temp_cast_3 );
				float mulTime88 = _TimeParameters.x * _RotateSpeed;
				float temp_output_90_0 = cos( mulTime88 );
				float temp_output_91_0 = sin( mulTime88 );
				float2 appendResult96 = (float2(( ( break92.x * temp_output_90_0 ) - ( break92.y * temp_output_91_0 ) ) , ( ( break92.x * temp_output_91_0 ) + ( break92.y * temp_output_90_0 ) )));
				float2 NoiseUV116 = ( appendResult96 + ( 0.5 +  (0.0 + ( _TimeParameters.y - 0.0 ) * ( 0.2 - 0.0 ) / ( 1.0 - 0.0 ) ) ) );
				float simplePerlin2D113 = snoise( NoiseUV116*_NoiseScale );
				simplePerlin2D113 = simplePerlin2D113*0.5 + 0.5;
				float Noise106 = simplePerlin2D113;
				float temp_output_27_0 = pow( ( ( _NoiseIntense *  (-1.0 + ( Noise106 - 0.0 ) * ( 1.0 - -1.0 ) / ( 1.0 - 0.0 ) ) ) + _Radius ) , 2.0 );
				float2 texCoord14 = IN.texCoord0.xy * float2( 1,1 ) + float2( 0,0 );
				float2 _Vector0 = float2(0.5,0.5);
				float temp_output_25_0 = ( pow( ( texCoord14.x - _Vector0.x ) , 2.0 ) + pow( ( texCoord14.y - _Vector0.y ) , 2.0 ) );
				float Center34 = ( 1.0 - step( temp_output_27_0 , ( temp_output_25_0 + _Float0 ) ) );
				float3 ase_positionWS = IN.ase_texcoord3.xyz;
				float3 WorldPos41 = ase_positionWS;
				float ArrayLength41 = 0.0;
				float localPartRimInner41 = PartRimInner41( WorldPos41 , ArrayLength41 );
				float PartRimInner73 = localPartRimInner41;
				float clampResult129 = clamp( ( Center34 + ( 1.0 - PartRimInner73 ) ) , 0.0 , 1.0 );
				float CenterColorFactor121 = clampResult129;
				float3 MainColor127 = ( tex2D( _MainTex, texCoord130 ).rgb * CenterColorFactor121 );
				float3 hsvTorgb136 = RGBToHSV( _RimColor.rgb );
				float3 hsvTorgb168 = RGBToHSV( _RimColor2.rgb );
				float2 texCoord153 = IN.texCoord0.xy * float2( 1,1 ) + float2( 0,0 );
				float2 break165 = texCoord153;
				float x152 = ( break165.x - 0.5 );
				float y152 = ( break165.y - 0.5 );
				float localcoord2theta152 = coord2theta152( x152 , y152 );
				float mulTime198 = _TimeParameters.x * 0.05;
				float temp_output_200_0 = frac( ( ( localcoord2theta152 / 6.283 ) + frac( mulTime198 ) ) );
				float HueShift161 = ( ( ( temp_output_200_0 * 2.0 ) * step( temp_output_200_0 , 0.5 ) ) + ( step( 0.5 , temp_output_200_0 ) * ( ( temp_output_200_0 * -2.0 ) + 2.0 ) ) );
				float3 lerpResult169 = lerp( hsvTorgb136 , hsvTorgb168 , HueShift161);
				float3 break184 = lerpResult169;
				float3 hsvTorgb182 = HSVToRGB( float3(break184.x,break184.y,break184.z) );
				float smoothstepResult50 = smoothstep( 0.0 , 0.07 , distance( temp_output_27_0 , temp_output_25_0 ));
				float CenterRimColorFactor53 = ( 1.0 - smoothstepResult50 );
				float3 WorldPos9 = ase_positionWS;
				float RimWidth9 = _RimWidth;
				float partInner9 = localPartRimInner41;
				float ArrayLength9 = 0.0;
				float localPartRim9 = PartRim9( WorldPos9 , RimWidth9 , partInner9 , ArrayLength9 );
				float PartRim74 =  (0.0 + ( localPartRim9 - _RimWidth ) * ( 1.0 - 0.0 ) / ( 1.0 - _RimWidth ) );
				float RimColorFactor78 = ( ( CenterRimColorFactor53 * ( 1.0 - Center34 ) * PartRimInner73 ) + ( ( 1.0 - Center34 ) * PartRim74 * PartRimInner73 ) );
				float clampResult241 = clamp( ( CenterColorFactor121 + RimColorFactor78 ) , 0.0 , 1.0 );
				float4 appendResult242 = (float4(( MainColor127 + ( hsvTorgb182 * RimColorFactor78 ) ) , clampResult241));
				
				float4 Color = appendResult242;

				#if ETC1_EXTERNAL_ALPHA
					float4 alpha = SAMPLE_TEXTURE2D(_AlphaTex, sampler_AlphaTex, IN.texCoord0.xy);
					Color.a = lerp( Color.a, alpha.r, _EnableAlphaTexture);
				#endif

				#if defined(DEBUG_DISPLAY)
				SurfaceData2D surfaceData;
				InitializeSurfaceData(Color.rgb, Color.a, surfaceData);
				InputData2D inputData;
				InitializeInputData(IN.positionWS.xy, half2(IN.texCoord0.xy), inputData);
				half4 debugColor = 0;

				SETUP_DEBUG_DATA_2D(inputData, IN.positionWS);

				if (CanDebugOverrideOutputColor(surfaceData, inputData, debugColor))
				{
					return debugColor;
				}
				#endif

				Color *= IN.color * _RendererColor;
				return Color;
			}

			ENDHLSL
		}

		
		Pass
		{
			
            Name "Sprite Unlit Forward"
            Tags { "LightMode"="UniversalForward" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZTest LEqual
			ZWrite Off
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM

			#define ASE_VERSION 19904
			#define ASE_SRP_VERSION 140012


			#pragma vertex vert
			#pragma fragment frag

            #define _SURFACE_TYPE_TRANSPARENT 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD0
            #define ATTRIBUTES_NEED_COLOR
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_TEXCOORD0
            #define VARYINGS_NEED_COLOR
            #define FEATURES_GRAPH_VERTEX

			#define SHADERPASS SHADERPASS_SPRITEFORWARD

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
           

			
            #if ASE_SRP_VERSION >=140009
			#include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/Shaders/2D/Include/SurfaceData2D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging2D.hlsl"

			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0


			float ParticleInitSize[100];
			float ParticleSize[100];
			float4 ParticlePos[100];
			sampler2D _MainTex;
			CBUFFER_START( UnityPerMaterial )
			float4 _RimColor;
			float4 _RimColor2;
			float _MainTexTilling;
			float _NoiseIntense;
			float _RotateSpeed;
			float _NoiseScale;
			float _Radius;
			float _Float0;
			float _RimWidth;
			CBUFFER_END


			struct VertexInput
			{
				float4 positionOS : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 uv0 : TEXCOORD0;
				float4 color : COLOR;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 texCoord0 : TEXCOORD0;
				float4 color : TEXCOORD1;
				float3 positionWS : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			#if ETC1_EXTERNAL_ALPHA
				TEXTURE2D( _AlphaTex ); SAMPLER( sampler_AlphaTex );
				float _EnableAlphaTexture;
			#endif

			float4 _RendererColor;

			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			
			float PartRimInner41( float3 WorldPos, float ArrayLength )
			{
				float result = 0.0;
				float innerCut = 0.0;
					for(int j = 0; j < 100; j++)
					{
						float dist2center = distance(WorldPos.xyz,  ParticlePos[j].xyz);
						float rimRange = step(ParticleSize[j], dist2center);
						rimRange = 1 - rimRange;
						
						innerCut += rimRange;
					}
					result = 1 - saturate(innerCut);
					return saturate(result);
			}
			
			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float3 RGBToHSV(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
				float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
				float d = q.x - min( q.w, q.y );
				float e = 1.0e-10;
				return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}
			float coord2theta152( float x, float y )
			{
				float theta = atan2(y, x);          // (-PI, PI]
				theta = (theta < 0) ? theta + 6.2831853 : theta; // 0..2PI
				return theta; // 弧度
			}
			
			float PartRim9( float3 WorldPos, float RimWidth, float partInner, float ArrayLength )
			{
				float result = 0.0;
								for(int j = 0; j < 100; j++)
								{
									float rimProportion = 1.0 * ParticleSize[j] / ParticleInitSize[j];
									float3 direction = normalize(WorldPos.xyz - ParticlePos[j].xyz);
									float3 rimPos = ParticlePos[j].xyz + direction * ParticleSize[j];
									float rim = distance(rimPos, WorldPos.xyz);		
									rim = smoothstep(1.0 - rimProportion, 1, 1 - saturate(rim));
									result += rim;
									
								}
								result *= partInner;
								return saturate(result);
			}
			

			VertexOutput vert( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_positionWS = TransformObjectToWorld( ( v.positionOS ).xyz );
				o.ase_texcoord3.xyz = ase_positionWS;
				
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3( 0, 0, 0 );
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif
				v.normal = v.normal;
				v.tangent.xyz = v.tangent.xyz;

				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);

				o.positionCS = vertexInput.positionCS;
				o.positionWS = vertexInput.positionWS;
				o.texCoord0 = v.uv0;
				o.color = v.color;

				return o;
			}

			half4 frag( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

				float2 temp_cast_0 = (_MainTexTilling).xx;
				float2 texCoord130 = IN.texCoord0.xy * temp_cast_0 + float2( 0,0 );
				float2 texCoord83 = IN.texCoord0.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_1 = (0.1).xx;
				float2 temp_cast_2 = (0.9).xx;
				float2 temp_cast_3 = (0.5).xx;
				float2 break92 = (  (temp_cast_1 + ( texCoord83 - float2( 0,0 ) ) * ( temp_cast_2 - temp_cast_1 ) / ( float2( 1,1 ) - float2( 0,0 ) ) ) - temp_cast_3 );
				float mulTime88 = _TimeParameters.x * _RotateSpeed;
				float temp_output_90_0 = cos( mulTime88 );
				float temp_output_91_0 = sin( mulTime88 );
				float2 appendResult96 = (float2(( ( break92.x * temp_output_90_0 ) - ( break92.y * temp_output_91_0 ) ) , ( ( break92.x * temp_output_91_0 ) + ( break92.y * temp_output_90_0 ) )));
				float2 NoiseUV116 = ( appendResult96 + ( 0.5 +  (0.0 + ( _TimeParameters.y - 0.0 ) * ( 0.2 - 0.0 ) / ( 1.0 - 0.0 ) ) ) );
				float simplePerlin2D113 = snoise( NoiseUV116*_NoiseScale );
				simplePerlin2D113 = simplePerlin2D113*0.5 + 0.5;
				float Noise106 = simplePerlin2D113;
				float temp_output_27_0 = pow( ( ( _NoiseIntense *  (-1.0 + ( Noise106 - 0.0 ) * ( 1.0 - -1.0 ) / ( 1.0 - 0.0 ) ) ) + _Radius ) , 2.0 );
				float2 texCoord14 = IN.texCoord0.xy * float2( 1,1 ) + float2( 0,0 );
				float2 _Vector0 = float2(0.5,0.5);
				float temp_output_25_0 = ( pow( ( texCoord14.x - _Vector0.x ) , 2.0 ) + pow( ( texCoord14.y - _Vector0.y ) , 2.0 ) );
				float Center34 = ( 1.0 - step( temp_output_27_0 , ( temp_output_25_0 + _Float0 ) ) );
				float3 ase_positionWS = IN.ase_texcoord3.xyz;
				float3 WorldPos41 = ase_positionWS;
				float ArrayLength41 = 0.0;
				float localPartRimInner41 = PartRimInner41( WorldPos41 , ArrayLength41 );
				float PartRimInner73 = localPartRimInner41;
				float clampResult129 = clamp( ( Center34 + ( 1.0 - PartRimInner73 ) ) , 0.0 , 1.0 );
				float CenterColorFactor121 = clampResult129;
				float3 MainColor127 = ( tex2D( _MainTex, texCoord130 ).rgb * CenterColorFactor121 );
				float3 hsvTorgb136 = RGBToHSV( _RimColor.rgb );
				float3 hsvTorgb168 = RGBToHSV( _RimColor2.rgb );
				float2 texCoord153 = IN.texCoord0.xy * float2( 1,1 ) + float2( 0,0 );
				float2 break165 = texCoord153;
				float x152 = ( break165.x - 0.5 );
				float y152 = ( break165.y - 0.5 );
				float localcoord2theta152 = coord2theta152( x152 , y152 );
				float mulTime198 = _TimeParameters.x * 0.05;
				float temp_output_200_0 = frac( ( ( localcoord2theta152 / 6.283 ) + frac( mulTime198 ) ) );
				float HueShift161 = ( ( ( temp_output_200_0 * 2.0 ) * step( temp_output_200_0 , 0.5 ) ) + ( step( 0.5 , temp_output_200_0 ) * ( ( temp_output_200_0 * -2.0 ) + 2.0 ) ) );
				float3 lerpResult169 = lerp( hsvTorgb136 , hsvTorgb168 , HueShift161);
				float3 break184 = lerpResult169;
				float3 hsvTorgb182 = HSVToRGB( float3(break184.x,break184.y,break184.z) );
				float smoothstepResult50 = smoothstep( 0.0 , 0.07 , distance( temp_output_27_0 , temp_output_25_0 ));
				float CenterRimColorFactor53 = ( 1.0 - smoothstepResult50 );
				float3 WorldPos9 = ase_positionWS;
				float RimWidth9 = _RimWidth;
				float partInner9 = localPartRimInner41;
				float ArrayLength9 = 0.0;
				float localPartRim9 = PartRim9( WorldPos9 , RimWidth9 , partInner9 , ArrayLength9 );
				float PartRim74 =  (0.0 + ( localPartRim9 - _RimWidth ) * ( 1.0 - 0.0 ) / ( 1.0 - _RimWidth ) );
				float RimColorFactor78 = ( ( CenterRimColorFactor53 * ( 1.0 - Center34 ) * PartRimInner73 ) + ( ( 1.0 - Center34 ) * PartRim74 * PartRimInner73 ) );
				float clampResult241 = clamp( ( CenterColorFactor121 + RimColorFactor78 ) , 0.0 , 1.0 );
				float4 appendResult242 = (float4(( MainColor127 + ( hsvTorgb182 * RimColorFactor78 ) ) , clampResult241));
				
				float4 Color = appendResult242;

				#if ETC1_EXTERNAL_ALPHA
					float4 alpha = SAMPLE_TEXTURE2D( _AlphaTex, sampler_AlphaTex, IN.texCoord0.xy );
					Color.a = lerp( Color.a, alpha.r, _EnableAlphaTexture );
				#endif


				#if defined(DEBUG_DISPLAY)
					SurfaceData2D surfaceData;
					InitializeSurfaceData(Color.rgb, Color.a, surfaceData);
					InputData2D inputData;
					InitializeInputData(IN.positionWS.xy, half2(IN.texCoord0.xy), inputData);
					half4 debugColor = 0;

					SETUP_DEBUG_DATA_2D(inputData, IN.positionWS);

					if (CanDebugOverrideOutputColor(surfaceData, inputData, debugColor))
					{
						return debugColor;
					}
				#endif

				Color *= IN.color * _RendererColor;
				return Color;
			}

			ENDHLSL
		}
		
        Pass
        {
			
            Name "SceneSelectionPass"
            Tags { "LightMode"="SceneSelectionPass" }

            Cull Off

            HLSLPROGRAM

			#define ASE_VERSION 19904
			#define ASE_SRP_VERSION 140012


			#pragma vertex vert
			#pragma fragment frag

            #define _SURFACE_TYPE_TRANSPARENT 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define FEATURES_GRAPH_VERTEX

            #define SHADERPASS SHADERPASS_DEPTHONLY
			#define SCENESELECTIONPASS 1

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
           

			
            #if ASE_SRP_VERSION >=140009
			#include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0


			float ParticleInitSize[100];
			float ParticleSize[100];
			float4 ParticlePos[100];
			sampler2D _MainTex;
			CBUFFER_START( UnityPerMaterial )
			float4 _RimColor;
			float4 _RimColor2;
			float _MainTexTilling;
			float _NoiseIntense;
			float _RotateSpeed;
			float _NoiseScale;
			float _Radius;
			float _Float0;
			float _RimWidth;
			CBUFFER_END


            struct VertexInput
			{
				float3 positionOS : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

            int _ObjectId;
            int _PassValue;

			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			
			float PartRimInner41( float3 WorldPos, float ArrayLength )
			{
				float result = 0.0;
				float innerCut = 0.0;
					for(int j = 0; j < 100; j++)
					{
						float dist2center = distance(WorldPos.xyz,  ParticlePos[j].xyz);
						float rimRange = step(ParticleSize[j], dist2center);
						rimRange = 1 - rimRange;
						
						innerCut += rimRange;
					}
					result = 1 - saturate(innerCut);
					return saturate(result);
			}
			
			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float3 RGBToHSV(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
				float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
				float d = q.x - min( q.w, q.y );
				float e = 1.0e-10;
				return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}
			float coord2theta152( float x, float y )
			{
				float theta = atan2(y, x);          // (-PI, PI]
				theta = (theta < 0) ? theta + 6.2831853 : theta; // 0..2PI
				return theta; // 弧度
			}
			
			float PartRim9( float3 WorldPos, float RimWidth, float partInner, float ArrayLength )
			{
				float result = 0.0;
								for(int j = 0; j < 100; j++)
								{
									float rimProportion = 1.0 * ParticleSize[j] / ParticleInitSize[j];
									float3 direction = normalize(WorldPos.xyz - ParticlePos[j].xyz);
									float3 rimPos = ParticlePos[j].xyz + direction * ParticleSize[j];
									float rim = distance(rimPos, WorldPos.xyz);		
									rim = smoothstep(1.0 - rimProportion, 1, 1 - saturate(rim));
									result += rim;
									
								}
								result *= partInner;
								return saturate(result);
			}
			

			VertexOutput vert(VertexInput v )
			{
				VertexOutput o = (VertexOutput)0;

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_positionWS = TransformObjectToWorld( ( v.positionOS ).xyz );
				o.ase_texcoord1.xyz = ase_positionWS;
				
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;
				o.ase_texcoord1.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
				float3 positionWS = TransformObjectToWorld(v.positionOS);
				o.positionCS = TransformWorldToHClip(positionWS);

				return o;
			}

			half4 frag(VertexOutput IN) : SV_TARGET
			{
				float2 temp_cast_0 = (_MainTexTilling).xx;
				float2 texCoord130 = IN.ase_texcoord.xy * temp_cast_0 + float2( 0,0 );
				float2 texCoord83 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_1 = (0.1).xx;
				float2 temp_cast_2 = (0.9).xx;
				float2 temp_cast_3 = (0.5).xx;
				float2 break92 = (  (temp_cast_1 + ( texCoord83 - float2( 0,0 ) ) * ( temp_cast_2 - temp_cast_1 ) / ( float2( 1,1 ) - float2( 0,0 ) ) ) - temp_cast_3 );
				float mulTime88 = _TimeParameters.x * _RotateSpeed;
				float temp_output_90_0 = cos( mulTime88 );
				float temp_output_91_0 = sin( mulTime88 );
				float2 appendResult96 = (float2(( ( break92.x * temp_output_90_0 ) - ( break92.y * temp_output_91_0 ) ) , ( ( break92.x * temp_output_91_0 ) + ( break92.y * temp_output_90_0 ) )));
				float2 NoiseUV116 = ( appendResult96 + ( 0.5 +  (0.0 + ( _TimeParameters.y - 0.0 ) * ( 0.2 - 0.0 ) / ( 1.0 - 0.0 ) ) ) );
				float simplePerlin2D113 = snoise( NoiseUV116*_NoiseScale );
				simplePerlin2D113 = simplePerlin2D113*0.5 + 0.5;
				float Noise106 = simplePerlin2D113;
				float temp_output_27_0 = pow( ( ( _NoiseIntense *  (-1.0 + ( Noise106 - 0.0 ) * ( 1.0 - -1.0 ) / ( 1.0 - 0.0 ) ) ) + _Radius ) , 2.0 );
				float2 texCoord14 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 _Vector0 = float2(0.5,0.5);
				float temp_output_25_0 = ( pow( ( texCoord14.x - _Vector0.x ) , 2.0 ) + pow( ( texCoord14.y - _Vector0.y ) , 2.0 ) );
				float Center34 = ( 1.0 - step( temp_output_27_0 , ( temp_output_25_0 + _Float0 ) ) );
				float3 ase_positionWS = IN.ase_texcoord1.xyz;
				float3 WorldPos41 = ase_positionWS;
				float ArrayLength41 = 0.0;
				float localPartRimInner41 = PartRimInner41( WorldPos41 , ArrayLength41 );
				float PartRimInner73 = localPartRimInner41;
				float clampResult129 = clamp( ( Center34 + ( 1.0 - PartRimInner73 ) ) , 0.0 , 1.0 );
				float CenterColorFactor121 = clampResult129;
				float3 MainColor127 = ( tex2D( _MainTex, texCoord130 ).rgb * CenterColorFactor121 );
				float3 hsvTorgb136 = RGBToHSV( _RimColor.rgb );
				float3 hsvTorgb168 = RGBToHSV( _RimColor2.rgb );
				float2 texCoord153 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 break165 = texCoord153;
				float x152 = ( break165.x - 0.5 );
				float y152 = ( break165.y - 0.5 );
				float localcoord2theta152 = coord2theta152( x152 , y152 );
				float mulTime198 = _TimeParameters.x * 0.05;
				float temp_output_200_0 = frac( ( ( localcoord2theta152 / 6.283 ) + frac( mulTime198 ) ) );
				float HueShift161 = ( ( ( temp_output_200_0 * 2.0 ) * step( temp_output_200_0 , 0.5 ) ) + ( step( 0.5 , temp_output_200_0 ) * ( ( temp_output_200_0 * -2.0 ) + 2.0 ) ) );
				float3 lerpResult169 = lerp( hsvTorgb136 , hsvTorgb168 , HueShift161);
				float3 break184 = lerpResult169;
				float3 hsvTorgb182 = HSVToRGB( float3(break184.x,break184.y,break184.z) );
				float smoothstepResult50 = smoothstep( 0.0 , 0.07 , distance( temp_output_27_0 , temp_output_25_0 ));
				float CenterRimColorFactor53 = ( 1.0 - smoothstepResult50 );
				float3 WorldPos9 = ase_positionWS;
				float RimWidth9 = _RimWidth;
				float partInner9 = localPartRimInner41;
				float ArrayLength9 = 0.0;
				float localPartRim9 = PartRim9( WorldPos9 , RimWidth9 , partInner9 , ArrayLength9 );
				float PartRim74 =  (0.0 + ( localPartRim9 - _RimWidth ) * ( 1.0 - 0.0 ) / ( 1.0 - _RimWidth ) );
				float RimColorFactor78 = ( ( CenterRimColorFactor53 * ( 1.0 - Center34 ) * PartRimInner73 ) + ( ( 1.0 - Center34 ) * PartRim74 * PartRimInner73 ) );
				float clampResult241 = clamp( ( CenterColorFactor121 + RimColorFactor78 ) , 0.0 , 1.0 );
				float4 appendResult242 = (float4(( MainColor127 + ( hsvTorgb182 * RimColorFactor78 ) ) , clampResult241));
				
				float4 Color = appendResult242;

				half4 outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				return outColor;
			}

            ENDHLSL
        }

		
        Pass
        {
			
            Name "ScenePickingPass"
            Tags { "LightMode"="Picking" }

			Cull Off

            HLSLPROGRAM

			#define ASE_VERSION 19904
			#define ASE_SRP_VERSION 140012


			#pragma vertex vert
			#pragma fragment frag

            #define _SURFACE_TYPE_TRANSPARENT 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define FEATURES_GRAPH_VERTEX

            #define SHADERPASS SHADERPASS_DEPTHONLY
			#define SCENEPICKINGPASS 1

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
           

			
            #if ASE_SRP_VERSION >=140009
			#include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

        	#define ASE_NEEDS_TEXTURE_COORDINATES0
        	#define ASE_NEEDS_FRAG_TEXTURE_COORDINATES0


			float ParticleInitSize[100];
			float ParticleSize[100];
			float4 ParticlePos[100];
			sampler2D _MainTex;
			CBUFFER_START( UnityPerMaterial )
			float4 _RimColor;
			float4 _RimColor2;
			float _MainTexTilling;
			float _NoiseIntense;
			float _RotateSpeed;
			float _NoiseScale;
			float _Radius;
			float _Float0;
			float _RimWidth;
			CBUFFER_END


            struct VertexInput
			{
				float3 positionOS : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

            float4 _SelectionID;

			float3 mod2D289( float3 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float2 mod2D289( float2 x ) { return x - floor( x * ( 1.0 / 289.0 ) ) * 289.0; }
			float3 permute( float3 x ) { return mod2D289( ( ( x * 34.0 ) + 1.0 ) * x ); }
			float snoise( float2 v )
			{
				const float4 C = float4( 0.211324865405187, 0.366025403784439, -0.577350269189626, 0.024390243902439 );
				float2 i = floor( v + dot( v, C.yy ) );
				float2 x0 = v - i + dot( i, C.xx );
				float2 i1;
				i1 = ( x0.x > x0.y ) ? float2( 1.0, 0.0 ) : float2( 0.0, 1.0 );
				float4 x12 = x0.xyxy + C.xxzz;
				x12.xy -= i1;
				i = mod2D289( i );
				float3 p = permute( permute( i.y + float3( 0.0, i1.y, 1.0 ) ) + i.x + float3( 0.0, i1.x, 1.0 ) );
				float3 m = max( 0.5 - float3( dot( x0, x0 ), dot( x12.xy, x12.xy ), dot( x12.zw, x12.zw ) ), 0.0 );
				m = m * m;
				m = m * m;
				float3 x = 2.0 * frac( p * C.www ) - 1.0;
				float3 h = abs( x ) - 0.5;
				float3 ox = floor( x + 0.5 );
				float3 a0 = x - ox;
				m *= 1.79284291400159 - 0.85373472095314 * ( a0 * a0 + h * h );
				float3 g;
				g.x = a0.x * x0.x + h.x * x0.y;
				g.yz = a0.yz * x12.xz + h.yz * x12.yw;
				return 130.0 * dot( m, g );
			}
			
			float PartRimInner41( float3 WorldPos, float ArrayLength )
			{
				float result = 0.0;
				float innerCut = 0.0;
					for(int j = 0; j < 100; j++)
					{
						float dist2center = distance(WorldPos.xyz,  ParticlePos[j].xyz);
						float rimRange = step(ParticleSize[j], dist2center);
						rimRange = 1 - rimRange;
						
						innerCut += rimRange;
					}
					result = 1 - saturate(innerCut);
					return saturate(result);
			}
			
			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float3 RGBToHSV(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
				float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
				float d = q.x - min( q.w, q.y );
				float e = 1.0e-10;
				return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}
			float coord2theta152( float x, float y )
			{
				float theta = atan2(y, x);          // (-PI, PI]
				theta = (theta < 0) ? theta + 6.2831853 : theta; // 0..2PI
				return theta; // 弧度
			}
			
			float PartRim9( float3 WorldPos, float RimWidth, float partInner, float ArrayLength )
			{
				float result = 0.0;
								for(int j = 0; j < 100; j++)
								{
									float rimProportion = 1.0 * ParticleSize[j] / ParticleInitSize[j];
									float3 direction = normalize(WorldPos.xyz - ParticlePos[j].xyz);
									float3 rimPos = ParticlePos[j].xyz + direction * ParticleSize[j];
									float rim = distance(rimPos, WorldPos.xyz);		
									rim = smoothstep(1.0 - rimProportion, 1, 1 - saturate(rim));
									result += rim;
									
								}
								result *= partInner;
								return saturate(result);
			}
			

			VertexOutput vert(VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;

				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_positionWS = TransformObjectToWorld( ( v.positionOS ).xyz );
				o.ase_texcoord1.xyz = ase_positionWS;
				
				o.ase_texcoord.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord.zw = 0;
				o.ase_texcoord1.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.positionOS.xyz = vertexValue;
				#else
					v.positionOS.xyz += vertexValue;
				#endif

				VertexPositionInputs vertexInput = GetVertexPositionInputs(v.positionOS.xyz);
				float3 positionWS = TransformObjectToWorld(v.positionOS);
				o.positionCS = TransformWorldToHClip(positionWS);

				return o;
			}

			half4 frag(VertexOutput IN ) : SV_TARGET
			{
				float2 temp_cast_0 = (_MainTexTilling).xx;
				float2 texCoord130 = IN.ase_texcoord.xy * temp_cast_0 + float2( 0,0 );
				float2 texCoord83 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 temp_cast_1 = (0.1).xx;
				float2 temp_cast_2 = (0.9).xx;
				float2 temp_cast_3 = (0.5).xx;
				float2 break92 = (  (temp_cast_1 + ( texCoord83 - float2( 0,0 ) ) * ( temp_cast_2 - temp_cast_1 ) / ( float2( 1,1 ) - float2( 0,0 ) ) ) - temp_cast_3 );
				float mulTime88 = _TimeParameters.x * _RotateSpeed;
				float temp_output_90_0 = cos( mulTime88 );
				float temp_output_91_0 = sin( mulTime88 );
				float2 appendResult96 = (float2(( ( break92.x * temp_output_90_0 ) - ( break92.y * temp_output_91_0 ) ) , ( ( break92.x * temp_output_91_0 ) + ( break92.y * temp_output_90_0 ) )));
				float2 NoiseUV116 = ( appendResult96 + ( 0.5 +  (0.0 + ( _TimeParameters.y - 0.0 ) * ( 0.2 - 0.0 ) / ( 1.0 - 0.0 ) ) ) );
				float simplePerlin2D113 = snoise( NoiseUV116*_NoiseScale );
				simplePerlin2D113 = simplePerlin2D113*0.5 + 0.5;
				float Noise106 = simplePerlin2D113;
				float temp_output_27_0 = pow( ( ( _NoiseIntense *  (-1.0 + ( Noise106 - 0.0 ) * ( 1.0 - -1.0 ) / ( 1.0 - 0.0 ) ) ) + _Radius ) , 2.0 );
				float2 texCoord14 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 _Vector0 = float2(0.5,0.5);
				float temp_output_25_0 = ( pow( ( texCoord14.x - _Vector0.x ) , 2.0 ) + pow( ( texCoord14.y - _Vector0.y ) , 2.0 ) );
				float Center34 = ( 1.0 - step( temp_output_27_0 , ( temp_output_25_0 + _Float0 ) ) );
				float3 ase_positionWS = IN.ase_texcoord1.xyz;
				float3 WorldPos41 = ase_positionWS;
				float ArrayLength41 = 0.0;
				float localPartRimInner41 = PartRimInner41( WorldPos41 , ArrayLength41 );
				float PartRimInner73 = localPartRimInner41;
				float clampResult129 = clamp( ( Center34 + ( 1.0 - PartRimInner73 ) ) , 0.0 , 1.0 );
				float CenterColorFactor121 = clampResult129;
				float3 MainColor127 = ( tex2D( _MainTex, texCoord130 ).rgb * CenterColorFactor121 );
				float3 hsvTorgb136 = RGBToHSV( _RimColor.rgb );
				float3 hsvTorgb168 = RGBToHSV( _RimColor2.rgb );
				float2 texCoord153 = IN.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float2 break165 = texCoord153;
				float x152 = ( break165.x - 0.5 );
				float y152 = ( break165.y - 0.5 );
				float localcoord2theta152 = coord2theta152( x152 , y152 );
				float mulTime198 = _TimeParameters.x * 0.05;
				float temp_output_200_0 = frac( ( ( localcoord2theta152 / 6.283 ) + frac( mulTime198 ) ) );
				float HueShift161 = ( ( ( temp_output_200_0 * 2.0 ) * step( temp_output_200_0 , 0.5 ) ) + ( step( 0.5 , temp_output_200_0 ) * ( ( temp_output_200_0 * -2.0 ) + 2.0 ) ) );
				float3 lerpResult169 = lerp( hsvTorgb136 , hsvTorgb168 , HueShift161);
				float3 break184 = lerpResult169;
				float3 hsvTorgb182 = HSVToRGB( float3(break184.x,break184.y,break184.z) );
				float smoothstepResult50 = smoothstep( 0.0 , 0.07 , distance( temp_output_27_0 , temp_output_25_0 ));
				float CenterRimColorFactor53 = ( 1.0 - smoothstepResult50 );
				float3 WorldPos9 = ase_positionWS;
				float RimWidth9 = _RimWidth;
				float partInner9 = localPartRimInner41;
				float ArrayLength9 = 0.0;
				float localPartRim9 = PartRim9( WorldPos9 , RimWidth9 , partInner9 , ArrayLength9 );
				float PartRim74 =  (0.0 + ( localPartRim9 - _RimWidth ) * ( 1.0 - 0.0 ) / ( 1.0 - _RimWidth ) );
				float RimColorFactor78 = ( ( CenterRimColorFactor53 * ( 1.0 - Center34 ) * PartRimInner73 ) + ( ( 1.0 - Center34 ) * PartRim74 * PartRimInner73 ) );
				float clampResult241 = clamp( ( CenterColorFactor121 + RimColorFactor78 ) , 0.0 , 1.0 );
				float4 appendResult242 = (float4(( MainColor127 + ( hsvTorgb182 * RimColorFactor78 ) ) , clampResult241));
				
				float4 Color = appendResult242;
				half4 outColor = unity_SelectionID;
				return outColor;
			}

            ENDHLSL
        }
		
	}
	CustomEditor "UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback Off
}
/*ASEBEGIN
Version=19904
Node;AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;105;-6514.931,-2728.131;Inherit;False;2213.133;1156.864;Comment;24;90;100;97;89;91;99;93;104;102;101;111;94;86;87;96;98;92;88;95;103;110;112;83;116;Noiseuv;1,1,1,1;0;0
Node;AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;83;-6464.931,-2678.131;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;101;-6454.337,-2434.246;Inherit;False;Constant;_Float3;Float 3;7;0;Create;True;0;0;0;False;0;False;0.9;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;102;-6451.656,-2527.449;Inherit;False;Constant;_Float4;Float 4;7;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;89;-6122.994,-2152.812;Inherit;False;Property;_RotateSpeed;RotateSpeed;6;0;Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;87;-6020.931,-2426.798;Inherit;False;Constant;_Float1;Float 1;6;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;100;-6153.548,-2641.64;Inherit;False;5;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;2;FLOAT2;1,1;False;3;FLOAT2;0,0;False;4;FLOAT2;1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleTimeNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;88;-5886.994,-2243.478;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;86;-5825.597,-2544.131;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SinOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;91;-5658.995,-2166.144;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CosOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;90;-5630.995,-2305.478;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;92;-5662.325,-2504.749;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;95;-5319.294,-2319.03;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;93;-5315.105,-2455.603;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinTimeNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;112;-5360.867,-1839.843;Inherit;False;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;98;-5381.363,-1989.339;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;97;-5387.157,-2148.689;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;104;-4880.142,-2191.482;Inherit;False;Constant;_Float5;Float 5;7;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;99;-5168.898,-2074.324;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;94;-5168.329,-2352.145;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;111;-4890.38,-2020.456;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;0.2;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;96;-4874.344,-2361.154;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;110;-4669.225,-2132.977;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;103;-4629.811,-2283.482;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;32;-4071.849,-2467.118;Inherit;False;3495.847;1492.868;Comment;28;114;34;118;22;43;19;119;25;53;51;30;106;21;29;27;15;81;58;120;14;50;31;113;59;117;24;33;201;Center;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;116;-4488.863,-2215.041;Inherit;False;NoiseUV;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;117;-3997.373,-1951.065;Inherit;False;Property;_NoiseScale;NoiseScale;7;0;Create;True;0;0;0;False;0;False;0;3.27;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;114;-3979.283,-2126.593;Inherit;False;116;NoiseUV;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;159;-400.9183,-2858.169;Inherit;False;4438.173;750.063;Comment;16;161;157;152;154;155;165;153;156;158;180;173;174;198;199;200;197;HueShifting;1,1,1,1;0;0
Node;AmplifyShaderEditor.NoiseGeneratorNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;113;-3669.299,-2125.438;Inherit;True;Simplex2D;True;False;2;0;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;106;-3230.85,-2120.568;Inherit;False;Noise;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;14;-3399.83,-1474.887;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;31;-3348.487,-1283.081;Inherit;False;Constant;_Vector0;Vector 0;2;0;Create;True;0;0;0;False;0;False;0.5,0.5;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;153;-269.1175,-2684.728;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;119;-3105.249,-2262.471;Inherit;False;Property;_NoiseIntense;NoiseIntense;8;0;Create;True;0;0;0;False;0;False;0;0.04;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;120;-2781.936,-2108.417;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-1;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;29;-2992.283,-1507.547;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;30;-3009.618,-1296.948;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;165;116.6277,-2627.999;Inherit;False;FLOAT2;1;0;FLOAT2;0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;155;80.67953,-2408.785;Inherit;False;Constant;_Float7;Float 7;10;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;15;-2793.399,-1856.11;Inherit;False;Property;_Radius;Radius;3;0;Create;True;0;0;0;False;0;False;0;0.288;0;0.5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;118;-2408.187,-2141.963;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;22;-2542.947,-1422.873;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;19;-2530.258,-1290.918;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;154;403.7625,-2624.813;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;156;390.335,-2426.269;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;76;-1717.484,276.3686;Inherit;False;3201.669;1147.25;Comment;14;6;13;26;35;74;73;7;8;9;41;36;10;244;247;ParticleRim;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;59;-2449.184,-1154.302;Inherit;False;Property;_Float0;Float 0;9;0;Create;True;0;0;0;False;0;False;0;0.01;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;81;-2210.277,-2120.927;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;21;-2789.391,-1370.923;Inherit;False;Constant;_Float2;Float 2;2;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;25;-2361.079,-1357.991;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;158;592.1654,-2363.311;Inherit;False;Constant;_Float8;Float 8;10;0;Create;True;0;0;0;False;0;False;6.283;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;198;741.6624,-2267.468;Inherit;False;1;0;FLOAT;0.05;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;152;608,-2576;Inherit;False;float theta = atan2(y, x)@          // (-PI, PI]$theta = (theta < 0) ? theta + 6.2831853 : theta@ // 0..2PI$return theta@ // 弧度;1;Create;2;True;x;FLOAT;0;In;;Inherit;False;True;y;FLOAT;0;In;;Inherit;False;coord2theta;True;False;0;;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;10;-1364.282,532.5789;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;58;-2126.306,-1313.833;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;27;-2003.147,-2132.15;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;199;948.9958,-2328.801;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;157;802.8334,-2573.737;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;173;1406.172,-2391.44;Inherit;False;766.9729;249.2798;Comment;4;171;176;177;175;>0.5;1,1,1,1;0;0
Node;AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;24;-1559.242,-2128.039;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;197;1056.707,-2567.699;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;41;-1008,816;Inherit;False;float result = 0.0@$float innerCut = 0.0@$	for(int j = 0@ j < 100@ j++)$	{$		float dist2center = distance(WorldPos.xyz,  ParticlePos[j].xyz)@$		float rimRange = step(ParticleSize[j], dist2center)@$		rimRange = 1 - rimRange@$		$		innerCut += rimRange@$	}$	result = 1 - saturate(innerCut)@$	return saturate(result)@;1;Create;2;True;WorldPos;FLOAT3;0,0,0;In;;Inherit;False;True;ArrayLength;FLOAT;0;In;;Inherit;False;PartRimInner;True;False;0;;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;49;-3539.586,-660.3901;Inherit;False;1942.686;699.8418;Comment;12;125;124;123;121;39;122;37;38;127;129;130;131;MainColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;174;1441.523,-2755.208;Inherit;False;727.0234;232.1565;Comment;3;172;178;179;<0.5;1,1,1,1;0;0
Node;AmplifyShaderEditor.DistanceOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;43;-2155.492,-1452.452;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;33;-1393.822,-2129.898;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;73;-464.8075,825.0746;Inherit;False;PartRimInner;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;175;1469.307,-2246.844;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;-2;False;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;200;1236.663,-2603.359;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;13;-1106.537,657.3738;Inherit;False;Property;_RimWidth;RimWidth;2;0;Create;True;0;0;0;False;0;False;0.99;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;50;-1758.865,-1407.721;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.07;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;34;-1185,-2138.036;Inherit;False;Center;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;125;-3461.265,-94.61858;Inherit;False;73;PartRimInner;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;171;1750.33,-2343.317;Inherit;False;2;0;FLOAT;0.5;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;179;1500.031,-2706.362;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;172;1642.472,-2638.512;Inherit;False;2;0;FLOAT;0.5;False;1;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;177;1651.81,-2235.089;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;62;-150.3594,-1104.724;Inherit;False;1564.961;1005.519;Comment;7;61;56;55;60;66;75;78;RimColor;1,1,1,1;0;0
Node;AmplifyShaderEditor.OneMinusNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;51;-1264.129,-1265.455;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;124;-3286.277,-153.5887;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;39;-3473.667,-334.7882;Inherit;False;34;Center;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;176;1955.422,-2300.899;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;178;1896.542,-2709.952;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;9;-710.1386,611.9543;Inherit;False;float result = 0.0@$				for(int j = 0@ j < 100@ j++)$				{$					float rimProportion = 1.0 * ParticleSize[j] / ParticleInitSize[j]@$					float3 direction = normalize(WorldPos.xyz - ParticlePos[j].xyz)@$					float3 rimPos = ParticlePos[j].xyz + direction * ParticleSize[j]@$					float rim = distance(rimPos, WorldPos.xyz)@		$					rim = smoothstep(1.0 - rimProportion, 1, 1 - saturate(rim))@$					result += rim@$					$				}$				result *= partInner@$				return saturate(result)@;1;Create;4;True;WorldPos;FLOAT3;0,0,0;In;;Inherit;False;True;RimWidth;FLOAT;0;In;;Inherit;False;True;partInner;FLOAT;0;In;;Inherit;False;True;ArrayLength;FLOAT;0;In;;Inherit;False;PartRim;True;False;0;;False;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;247;-432,624;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;0;False;4;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;53;-983.718,-1228.54;Inherit;False;CenterRimColorFactor;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;60;-100.3594,-692.6124;Inherit;False;34;Center;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;35;-815.2011,378.712;Inherit;False;34;Center;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;123;-3039.718,-203.9709;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;180;2408.887,-2492.677;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;74;-224,592;Inherit;False;PartRim;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;56;-87.39455,-845.6631;Inherit;False;53;CenterRimColorFactor;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;75;100.6247,-579.1019;Inherit;False;73;PartRimInner;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;61;123.0388,-708.2084;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;36;-520.317,409.7352;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;129;-2865.364,-148.4594;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;131;-3525.364,-521.1262;Inherit;False;Property;_MainTexTilling;MainTexTilling;5;0;Create;True;0;0;0;False;0;False;1;2.62;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;54;1345.773,-1897.597;Inherit;False;Property;_RimColor;RimColor;0;0;Create;True;0;0;0;False;0;False;0,0,0,0;1,0,0.3096347,0;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.ColorNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;166;1286.755,-1609.604;Inherit;False;Property;_RimColor2;RimColor2;1;0;Create;True;0;0;0;False;0;False;0,0,0,0;0.5656157,0.9058824,0.08235288,0;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;161;3148.41,-2572.856;Inherit;False;HueShift;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;55;450.807,-766.8787;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;26;16,560;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;121;-2729.729,-215.5886;Inherit;False;CenterColorFactor;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;130;-3334.03,-555.1262;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RGBToHSVNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;168;1576.127,-1607.358;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RGBToHSVNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;136;1647.931,-1881.271;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;163;1777.123,-1375.927;Inherit;False;161;HueShift;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;66;776.7839,-759.0947;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;122;-3015.178,-361.8729;Inherit;False;121;CenterColorFactor;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;169;2072.75,-1671.897;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;37;-3056,-592;Inherit;True;Property;_MainTex;MainTex;4;0;Create;True;0;0;0;False;0;False;-1;None;3f6b63e45ee14cd43bd2753eb62c2141;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;False;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;78;1062.189,-802.6589;Inherit;False;RimColorFactor;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.BreakToComponentsNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;184;2312.833,-1666.259;Inherit;False;FLOAT3;1;0;FLOAT3;0,0,0;False;16;FLOAT;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT;5;FLOAT;6;FLOAT;7;FLOAT;8;FLOAT;9;FLOAT;10;FLOAT;11;FLOAT;12;FLOAT;13;FLOAT;14;FLOAT;15
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;38;-2624.224,-542.6591;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;80;2528,-1440;Inherit;False;78;RimColorFactor;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;77;3264,-1488;Inherit;False;121;CenterColorFactor;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.HSVToRGBNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;182;2448,-1664;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;127;-2366.181,-522.2728;Inherit;False;MainColor;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;240;3568,-1408;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;79;2899.492,-1657.349;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;128;3008,-1824;Inherit;False;127;MainColor;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;126;3536,-1680;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;241;3819.984,-1349.495;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;244;128,752;Inherit;False;Test;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;201;-2987.509,-2009.615;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;8;-1661.241,999.0676;Inherit;False;ParticleInitSize;0;100;0;False;False;0;1;True;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;235;3509.796,-1549.222;Inherit;False;Constant;_Float6;Float 6;10;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;7;-1662.522,744.6213;Inherit;False;ParticleSize;0;100;0;False;False;0;1;True;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;6;-1665.484,563.1331;Inherit;False;ParticlePos;0;100;2;False;False;0;1;True;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;245;3648,-1504;Inherit;False;244;Test;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;242;4128,-1488;Inherit;False;FLOAT4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;143;4160,-1584;Inherit;False;74;PartRim;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;237;3706.207,-1627.443;Float;False;False;-1;3;UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI;0;17;New Amplify Shader;cf964e524c8e69742b1d21fbe2ebcc4a;True;Sprite Unlit Forward;0;1;Sprite Unlit Forward;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;0;True;12;all;0;False;True;2;5;False;;10;False;;3;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForward;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;238;3706.207,-1627.443;Float;False;False;-1;3;UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI;0;17;New Amplify Shader;cf964e524c8e69742b1d21fbe2ebcc4a;True;SceneSelectionPass;0;2;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;0;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;239;3706.207,-1627.443;Float;False;False;-1;3;UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI;0;17;New Amplify Shader;cf964e524c8e69742b1d21fbe2ebcc4a;True;ScenePickingPass;0;3;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;0;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;236;4512,-1488;Float;False;True;-1;3;UnityEditor.ShaderGraph.GenericShaderGraphMaterialGUI;0;17;Hollow;cf964e524c8e69742b1d21fbe2ebcc4a;True;Sprite Unlit;0;0;Sprite Unlit;4;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;True;0;True;12;all;0;False;True;2;5;False;;10;False;;3;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;3;Vertex Position;1;0;Debug Display;0;0;External Alpha;0;0;0;4;True;True;True;True;False;;False;0
WireConnection;100;0;83;0
WireConnection;100;3;102;0
WireConnection;100;4;101;0
WireConnection;88;0;89;0
WireConnection;86;0;100;0
WireConnection;86;1;87;0
WireConnection;91;0;88;0
WireConnection;90;0;88;0
WireConnection;92;0;86;0
WireConnection;95;0;92;1
WireConnection;95;1;91;0
WireConnection;93;0;92;0
WireConnection;93;1;90;0
WireConnection;98;0;92;1
WireConnection;98;1;90;0
WireConnection;97;0;92;0
WireConnection;97;1;91;0
WireConnection;99;0;97;0
WireConnection;99;1;98;0
WireConnection;94;0;93;0
WireConnection;94;1;95;0
WireConnection;111;0;112;4
WireConnection;96;0;94;0
WireConnection;96;1;99;0
WireConnection;110;0;104;0
WireConnection;110;1;111;0
WireConnection;103;0;96;0
WireConnection;103;1;110;0
WireConnection;116;0;103;0
WireConnection;113;0;114;0
WireConnection;113;1;117;0
WireConnection;106;0;113;0
WireConnection;120;0;106;0
WireConnection;29;0;14;1
WireConnection;29;1;31;1
WireConnection;30;0;14;2
WireConnection;30;1;31;2
WireConnection;165;0;153;0
WireConnection;118;0;119;0
WireConnection;118;1;120;0
WireConnection;22;0;29;0
WireConnection;22;1;21;0
WireConnection;19;0;30;0
WireConnection;19;1;21;0
WireConnection;154;0;165;0
WireConnection;154;1;155;0
WireConnection;156;0;165;1
WireConnection;156;1;155;0
WireConnection;81;0;118;0
WireConnection;81;1;15;0
WireConnection;25;0;22;0
WireConnection;25;1;19;0
WireConnection;152;0;154;0
WireConnection;152;1;156;0
WireConnection;58;0;25;0
WireConnection;58;1;59;0
WireConnection;27;0;81;0
WireConnection;27;1;21;0
WireConnection;199;0;198;0
WireConnection;157;0;152;0
WireConnection;157;1;158;0
WireConnection;24;0;27;0
WireConnection;24;1;58;0
WireConnection;197;0;157;0
WireConnection;197;1;199;0
WireConnection;41;0;10;0
WireConnection;43;0;27;0
WireConnection;43;1;25;0
WireConnection;33;0;24;0
WireConnection;73;0;41;0
WireConnection;175;0;200;0
WireConnection;200;0;197;0
WireConnection;50;0;43;0
WireConnection;34;0;33;0
WireConnection;171;1;200;0
WireConnection;179;0;200;0
WireConnection;172;0;200;0
WireConnection;177;0;175;0
WireConnection;51;0;50;0
WireConnection;124;0;125;0
WireConnection;176;0;171;0
WireConnection;176;1;177;0
WireConnection;178;0;179;0
WireConnection;178;1;172;0
WireConnection;9;0;10;0
WireConnection;9;1;13;0
WireConnection;9;2;41;0
WireConnection;247;0;9;0
WireConnection;247;1;13;0
WireConnection;53;0;51;0
WireConnection;123;0;39;0
WireConnection;123;1;124;0
WireConnection;180;0;178;0
WireConnection;180;1;176;0
WireConnection;74;0;247;0
WireConnection;61;0;60;0
WireConnection;36;0;35;0
WireConnection;129;0;123;0
WireConnection;161;0;180;0
WireConnection;55;0;56;0
WireConnection;55;1;61;0
WireConnection;55;2;75;0
WireConnection;26;0;36;0
WireConnection;26;1;74;0
WireConnection;26;2;73;0
WireConnection;121;0;129;0
WireConnection;130;0;131;0
WireConnection;168;0;166;0
WireConnection;136;0;54;0
WireConnection;66;0;55;0
WireConnection;66;1;26;0
WireConnection;169;0;136;0
WireConnection;169;1;168;0
WireConnection;169;2;163;0
WireConnection;37;1;130;0
WireConnection;78;0;66;0
WireConnection;184;0;169;0
WireConnection;38;0;37;5
WireConnection;38;1;122;0
WireConnection;182;0;184;0
WireConnection;182;1;184;1
WireConnection;182;2;184;2
WireConnection;127;0;38;0
WireConnection;240;0;77;0
WireConnection;240;1;80;0
WireConnection;79;0;182;0
WireConnection;79;1;80;0
WireConnection;126;0;128;0
WireConnection;126;1;79;0
WireConnection;241;0;240;0
WireConnection;201;0;106;0
WireConnection;242;0;126;0
WireConnection;242;3;241;0
WireConnection;236;1;242;0
ASEEND*/
//CHKSM=65A6F424A262610E6B556BC9CD6228AF2D26696F