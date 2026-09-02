// Made with Amplify Shader Editor v1.9.9.4
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Shield"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HDR] _MainColor( "MainColor", Color ) = ( 0, 0, 0, 0 )
		_DissolveAmount( "DissolveAmount", Range( -3, -0.37 ) ) = -0.37
		_MainColorintensity( "MainColorintensity", Float ) = 1
		_HoloBias( "HoloBias", Range( 0, 0.3 ) ) = 0
		_RimPower( "RimPower", Float ) = 3
		_RimSclae( "RimSclae", Float ) = 1
		_FlowIntensity( "FlowIntensity", Range( 0, 40 ) ) = 1
		_LineIntensity( "LineIntensity", Range( 0, 1 ) ) = 0.3090088
		_VertOffsetIntense( "VertOffsetIntense", Float ) = 0.12
		_HitRimIntense( "HitRimIntense", Float ) = 0
		_HitWaveIntense( "HitWaveIntense", Float ) = 0
		_DepthFadeDistance( "DepthFadeDistance", Range( 0, 0.6 ) ) = 0.6
		_Line( "Line", 2D ) = "white" {}
		_TestPos( "TestPos", Vector ) = ( 0, 0, 0, 0 )
		_HitWaveTest( "HitWaveTest", Float ) = 0
		_HitRimTest( "HitRimTest", Float ) = 0
		_Scale( "Scale", Float ) = 0
		_DissolvePos( "DissolvePos", Vector ) = ( 0, 0, 0, 0 )
		_DissolveRimWidth( "DissolveRimWidth", Float ) = 0.32
		_Grid( "Grid", 2D ) = "white" {}


		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

		[HideInInspector][ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Transparent" "Queue"="Transparent" "UniversalMaterialType"="Unlit" }

		Cull Back
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 5.0
		#pragma prefer_hlslcc gles
		// ensure rendering platforms toggle list is visible

		#if ( SHADER_TARGET > 35 ) && defined( SHADER_API_GLES3 )
			#error For WebGL2/GLES3, please set your shader target to 3.5 via SubShader options. URP shaders in ASE use target 4.5 by default.
		#endif

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}

		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
							(( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS
		ENDHLSL

		
		Pass
		{
			Name "ExtraPrePass"
			

			Blend Zero One
			Cull Back
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			

			#pragma multi_compile_local _ALPHATEST_ON
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_VERSION 19904
			#define ASE_SRP_VERSION 140012


			

			#pragma vertex vert
			#pragma fragment frag

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_VERT_NORMAL


			struct Attributes
			{
				float4 positionOS : POSITION;
				half3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				float4 positionWSAndFogFactor : TEXCOORD0;
				half3 normalWS : TEXCOORD1;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MainColor;
			float3 _DissolvePos;
			float3 _TestPos;
			float _VertOffsetIntense;
			float _HitRimIntense;
			float _Scale;
			float _HitRimTest;
			float _DissolveRimWidth;
			float _HoloBias;
			float _FlowIntensity;
			float _HitWaveIntense;
			float _LineIntensity;
			float _MainColorintensity;
			float _HitWaveTest;
			float _DissolveAmount;
			float _RimPower;
			float _DepthFadeDistance;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float ParticleCrntSize[10];
			float ParticleFinalSize[10];
			float4 HitPos[10];
			UNITY_INSTANCING_BUFFER_START(Shield)
			UNITY_INSTANCING_BUFFER_END(Shield)


			float3 ASESafeNormalize(float3 inVec)
			{
				float dp3 = max(1.175494351e-38, dot(inVec, inVec));
				return inVec* rsqrt(dp3);
			}
			
			float HitWave417( float3 WorldPos, float3 OriginWorldPos, float ShieldRadius, float3 TestPos, float HitWaveTest )
			{
				float result = 0.0f;
				for(int j = 0; j < 10; j++)
				{	
					float fade = 1.0f - saturate(1.0f * ParticleCrntSize[j] / ParticleFinalSize[j]);
					float3 newR = normalize(HitPos[j].xyz - OriginWorldPos);
					//float3 newR = normalize(TestPos - OriginWorldPos);
					float3 newPos = OriginWorldPos + newR * ShieldRadius;
					float3 a = newPos - OriginWorldPos;
					float3 b = WorldPos - OriginWorldPos;
					float wave = dot(a, b) / (ShieldRadius * ShieldRadius);
					//wave = acos(wave) - HitWaveTest;
					wave = acos(wave) - ParticleCrntSize[j];
					float mask = 1.0f - step(0.001, wave);
					wave = distance(0, wave) * mask;
					wave = 1.0f - saturate(wave);
					wave *= mask;
					wave = smoothstep(0.3f, 1.05f, wave);	
					result += wave * fade;
					
				}
				return saturate(result);
			}
			

			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output = (PackedVaryings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				float3 objToWorld55 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 temp_output_3_0_g1 = ( ase_positionWS - objToWorld55 );
				float3 ase_normalWS = TransformObjectToWorldNormal( input.normalOS );
				float3 temp_output_6_0_g2 = ase_normalWS;
				float dotResult1_g2 = dot( temp_output_3_0_g1 , temp_output_6_0_g2 );
				float dotResult2_g2 = dot( temp_output_6_0_g2 , temp_output_6_0_g2 );
				float3 temp_output_58_0 = ( temp_output_3_0_g1 - ( ( dotResult1_g2 / dotResult2_g2 ) * temp_output_6_0_g2 ) );
				float3 Point2CenterDir69 = -temp_output_58_0;
				float3 worldToObjDir439 = ASESafeNormalize( mul( GetWorldToObjectMatrix(), float4( Point2CenterDir69, 0.0 ) ).xyz );
				float3 objToWorld217 = mul( GetObjectToWorldMatrix(), float4( ( _DissolvePos * 0.01 ), 1 ) ).xyz;
				float3 OBJ2WRLD413 = objToWorld217;
				float3 objToWorld363 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 CenterPos62 = ( ase_positionWS - temp_output_58_0 );
				float3 OriginWorldPos408 = objToWorld363;
				float dotResult362 = dot( ( OBJ2WRLD413 - objToWorld363 ) , ( CenterPos62 - OriginWorldPos408 ) );
				float ShieldRadius446 = distance( ase_positionWS , OriginWorldPos408 );
				float temp_output_385_0 = ( acos( ( dotResult362 / ( ShieldRadius446 * ShieldRadius446 ) ) ) + _DissolveAmount );
				float clampResult400 = clamp( ( 0.92 + temp_output_385_0 ) , 0.0 , 1.0 );
				float VertOffsetFactor269 = ( 1.0 - clampResult400 );
				float3 WorldPos417 = CenterPos62;
				float3 OriginWorldPos417 = OriginWorldPos408;
				float ShieldRadius417 = ShieldRadius446;
				float3 TestPos417 = _TestPos;
				float HitWaveTest417 = _HitWaveTest;
				float localHitWave417 = HitWave417( WorldPos417 , OriginWorldPos417 , ShieldRadius417 , TestPos417 , HitWaveTest417 );
				float HitWave419 = localHitWave417;
				float3 worldToObjDir438 = ASESafeNormalize( mul( GetWorldToObjectMatrix(), float4( ase_normalWS, 0.0 ) ).xyz );
				float3 temp_output_423_0 = ( HitWave419 * 0.03 * 0.02 * worldToObjDir438 );
				float3 VertOffsset149 = ( ( worldToObjDir439 * _VertOffsetIntense * 0.01 * VertOffsetFactor269 ) + temp_output_423_0 );
				

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = VertOffsset149;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );
				VertexNormalInputs normalInput = GetVertexNormalInputs( input.normalOS );

				float fogFactor = 0;
				#if defined(ASE_FOG) && !defined(_FOG_FRAGMENT)
					fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
				#endif

				output.positionCS = vertexInput.positionCS;
				output.positionWSAndFogFactor = float4( vertexInput.positionWS, fogFactor );
				output.normalWS = normalInput.normalWS;
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag ( PackedVaryings input  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( input );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( input );

				#if defined( _SURFACE_TYPE_TRANSPARENT )
					const bool isTransparent = true;
				#else
					const bool isTransparent = false;
				#endif

				#if defined(MAIN_LIGHT_CALCULATE_SHADOWS) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord = TransformWorldToShadowCoord(input.positionWSAndFogFactor.xyz);
				#else
					float4 shadowCoord = float4(0, 0, 0, 0);
				#endif

				float3 PositionWS = input.positionWSAndFogFactor.xyz;
				float3 PositionRWS = GetCameraRelativePositionWS( PositionWS );
				half3 ViewDirWS = GetWorldSpaceNormalizeViewDir( PositionWS );
				float4 ShadowCoord = shadowCoord;
				float4 ScreenPosNorm = float4( GetNormalizedScreenSpaceUV( input.positionCS ), input.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, input.positionCS.z ) * input.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos );
				half3 NormalWS = normalize( input.normalWS );

				

				float3 Color = float3( 0, 0, 0 );
				float Alpha = 1;
				float AlphaClipThreshold = 0.0;

				#if defined( _ALPHATEST_ON )
					AlphaDiscard( Alpha, AlphaClipThreshold );
				#endif

				InputData inputData = (InputData)0;
				inputData.positionWS = PositionWS;
				inputData.positionCS = float4( input.positionCS.xy, ClipPos.zw / ClipPos.w );
				inputData.normalizedScreenSpaceUV = ScreenPosNorm.xy;
				inputData.normalWS = NormalWS;
				inputData.viewDirectionWS = ViewDirWS;

				#ifdef ASE_FOG
					inputData.fogCoord = InitializeInputDataFog(float4(inputData.positionWS, 1.0), input.positionWSAndFogFactor.w);

					#ifdef TERRAIN_SPLAT_ADDPASS
						Color.rgb = MixFogColor(Color.rgb, half3(0,0,0), inputData.fogCoord);
					#else
						Color.rgb = MixFog(Color.rgb, inputData.fogCoord);
					#endif
				#endif

				#if defined(LOD_FADE_CROSSFADE)
					LODFadeCrossFade( input.positionCS );
				#endif

				#if defined( ASE_OPAQUE_KEEP_ALPHA )
					return half4( Color, Alpha );
				#else
					return half4( Color, OutputAlpha( Alpha, isTransparent ) );
				#endif
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }

			Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
			ZWrite Off
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			

			#pragma multi_compile_local _ALPHATEST_ON
			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma instancing_options renderinglayer
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_VERSION 19904
			#define ASE_SRP_VERSION 140012
			#define REQUIRE_DEPTH_TEXTURE 1


			

			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3

			

			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_UNLIT

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			
			#if ASE_SRP_VERSION >=140010
			#include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
			#endif
		

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_WORLD_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_VIEW_DIR
			#define ASE_NEEDS_WORLD_POSITION
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_FRAG_SCREEN_POSITION_NORMALIZED
			#pragma multi_compile_instancing


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct Attributes
			{
				float4 positionOS : POSITION;
				half3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float4 positionWSAndFogFactor : TEXCOORD0;
				half3 normalWS : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MainColor;
			float3 _DissolvePos;
			float3 _TestPos;
			float _VertOffsetIntense;
			float _HitRimIntense;
			float _Scale;
			float _HitRimTest;
			float _DissolveRimWidth;
			float _HoloBias;
			float _FlowIntensity;
			float _HitWaveIntense;
			float _LineIntensity;
			float _MainColorintensity;
			float _HitWaveTest;
			float _DissolveAmount;
			float _RimPower;
			float _DepthFadeDistance;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float ParticleCrntSize[10];
			float ParticleFinalSize[10];
			float4 HitPos[10];
			sampler2D _Line;
			sampler2D _Grid;
			UNITY_INSTANCING_BUFFER_START(Shield)
				UNITY_DEFINE_INSTANCED_PROP(float, _RimSclae)
			UNITY_INSTANCING_BUFFER_END(Shield)


			float3 ASESafeNormalize(float3 inVec)
			{
				float dp3 = max(1.175494351e-38, dot(inVec, inVec));
				return inVec* rsqrt(dp3);
			}
			
			float HitWave417( float3 WorldPos, float3 OriginWorldPos, float ShieldRadius, float3 TestPos, float HitWaveTest )
			{
				float result = 0.0f;
				for(int j = 0; j < 10; j++)
				{	
					float fade = 1.0f - saturate(1.0f * ParticleCrntSize[j] / ParticleFinalSize[j]);
					float3 newR = normalize(HitPos[j].xyz - OriginWorldPos);
					//float3 newR = normalize(TestPos - OriginWorldPos);
					float3 newPos = OriginWorldPos + newR * ShieldRadius;
					float3 a = newPos - OriginWorldPos;
					float3 b = WorldPos - OriginWorldPos;
					float wave = dot(a, b) / (ShieldRadius * ShieldRadius);
					//wave = acos(wave) - HitWaveTest;
					wave = acos(wave) - ParticleCrntSize[j];
					float mask = 1.0f - step(0.001, wave);
					wave = distance(0, wave) * mask;
					wave = 1.0f - saturate(wave);
					wave *= mask;
					wave = smoothstep(0.3f, 1.05f, wave);	
					result += wave * fade;
					
				}
				return saturate(result);
			}
			
			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			float HitWave498( float3 WorldPos, float3 OriginWorldPos, float ShieldRadius, float3 TestPos, float HitRimTest, float Noise )
			{
				float result = 0.0f;
				for(int j = 0; j < 10; j++)
				{	
					float fade = 1.0f - saturate(1.0f * ParticleCrntSize[j] / ParticleFinalSize[j]);
					float3 newR = normalize(HitPos[j].xyz - OriginWorldPos);
					//float3 newR = normalize(TestPos - OriginWorldPos);
					float3 newPos = OriginWorldPos + newR * ShieldRadius;
					float3 a = newPos - OriginWorldPos;
					float3 b = WorldPos - OriginWorldPos;
					float rim = dot(a, b) / (ShieldRadius * ShieldRadius);
					//rim = acos(rim) - HitRimTest;
					rim = acos(rim) - ParticleCrntSize[j];
					float mask = 1.0f - step(0.001, rim);
					rim = distance(Noise, rim) * mask;
					rim = 1.0f - saturate(rim);
					rim *= mask;
					rim = smoothstep(0.95f, 1.1f, rim);	
					result += rim * fade;
				}
				return saturate(result);
			}
			

			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output = (PackedVaryings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				float3 objToWorld55 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 temp_output_3_0_g1 = ( ase_positionWS - objToWorld55 );
				float3 ase_normalWS = TransformObjectToWorldNormal( input.normalOS );
				float3 temp_output_6_0_g2 = ase_normalWS;
				float dotResult1_g2 = dot( temp_output_3_0_g1 , temp_output_6_0_g2 );
				float dotResult2_g2 = dot( temp_output_6_0_g2 , temp_output_6_0_g2 );
				float3 temp_output_58_0 = ( temp_output_3_0_g1 - ( ( dotResult1_g2 / dotResult2_g2 ) * temp_output_6_0_g2 ) );
				float3 Point2CenterDir69 = -temp_output_58_0;
				float3 worldToObjDir439 = ASESafeNormalize( mul( GetWorldToObjectMatrix(), float4( Point2CenterDir69, 0.0 ) ).xyz );
				float3 objToWorld217 = mul( GetObjectToWorldMatrix(), float4( ( _DissolvePos * 0.01 ), 1 ) ).xyz;
				float3 OBJ2WRLD413 = objToWorld217;
				float3 objToWorld363 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 CenterPos62 = ( ase_positionWS - temp_output_58_0 );
				float3 OriginWorldPos408 = objToWorld363;
				float dotResult362 = dot( ( OBJ2WRLD413 - objToWorld363 ) , ( CenterPos62 - OriginWorldPos408 ) );
				float ShieldRadius446 = distance( ase_positionWS , OriginWorldPos408 );
				float temp_output_385_0 = ( acos( ( dotResult362 / ( ShieldRadius446 * ShieldRadius446 ) ) ) + _DissolveAmount );
				float clampResult400 = clamp( ( 0.92 + temp_output_385_0 ) , 0.0 , 1.0 );
				float VertOffsetFactor269 = ( 1.0 - clampResult400 );
				float3 WorldPos417 = CenterPos62;
				float3 OriginWorldPos417 = OriginWorldPos408;
				float ShieldRadius417 = ShieldRadius446;
				float3 TestPos417 = _TestPos;
				float HitWaveTest417 = _HitWaveTest;
				float localHitWave417 = HitWave417( WorldPos417 , OriginWorldPos417 , ShieldRadius417 , TestPos417 , HitWaveTest417 );
				float HitWave419 = localHitWave417;
				float3 worldToObjDir438 = ASESafeNormalize( mul( GetWorldToObjectMatrix(), float4( ase_normalWS, 0.0 ) ).xyz );
				float3 temp_output_423_0 = ( HitWave419 * 0.03 * 0.02 * worldToObjDir438 );
				float3 VertOffsset149 = ( ( worldToObjDir439 * _VertOffsetIntense * 0.01 * VertOffsetFactor269 ) + temp_output_423_0 );
				
				output.ase_texcoord2.xy = input.ase_texcoord.xy;
				output.ase_texcoord2.zw = input.ase_texcoord1.xy;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = VertOffsset149;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );
				VertexNormalInputs normalInput = GetVertexNormalInputs( input.normalOS );

				float fogFactor = 0;
				#if defined(ASE_FOG) && !defined(_FOG_FRAGMENT)
					fogFactor = ComputeFogFactor(vertexInput.positionCS.z);
				#endif

				output.positionCS = vertexInput.positionCS;
				output.positionWSAndFogFactor = float4( vertexInput.positionWS, fogFactor );
				output.normalWS = normalInput.normalWS;
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.ase_texcoord = input.ase_texcoord;
				output.ase_texcoord1 = input.ase_texcoord1;
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				output.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag ( PackedVaryings input
						#if defined( ASE_DEPTH_WRITE_ON )
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						#ifdef _WRITE_RENDERING_LAYERS
						, out float4 outRenderingLayers : SV_Target1
						#endif
						 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);

				#if defined( _SURFACE_TYPE_TRANSPARENT )
					const bool isTransparent = true;
				#else
					const bool isTransparent = false;
				#endif

				#if defined(LOD_FADE_CROSSFADE)
					LODFadeCrossFade( input.positionCS );
				#endif

				#if defined(MAIN_LIGHT_CALCULATE_SHADOWS)
					float4 shadowCoord = TransformWorldToShadowCoord( input.positionWSAndFogFactor.xyz );
				#else
					float4 shadowCoord = float4(0, 0, 0, 0);
				#endif

				float3 PositionWS = input.positionWSAndFogFactor.xyz;
				float3 PositionRWS = GetCameraRelativePositionWS( PositionWS );
				half3 ViewDirWS = GetWorldSpaceNormalizeViewDir( PositionWS );
				float4 ShadowCoord = shadowCoord;
				float4 ScreenPosNorm = float4( GetNormalizedScreenSpaceUV( input.positionCS ), input.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, input.positionCS.z ) * input.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos );
				half3 NormalWS = normalize( input.normalWS );

				float4 MainColor137 = ( _MainColor * _MainColorintensity );
				
				float2 texCoord35 = input.ase_texcoord2.xy * float2( 1,1 ) + float2( 0,0 );
				float4 tex2DNode34 = tex2D( _Line, texCoord35 );
				float2 texCoord29 = input.ase_texcoord2.zw * float2( 1,1 ) + float2( 0,0 );
				float mulTime33 = _TimeParameters.x * 0.01;
				float smoothstepResult403 = smoothstep( 0.05 , 0.95 , tex2D( _Grid, ( texCoord29 + mulTime33 ) ).r);
				float dotResult15 = dot( NormalWS , ViewDirWS );
				float saferPower19 = abs( ( 1.0 - dotResult15 ) );
				float _RimSclae_Instance = UNITY_ACCESS_INSTANCED_PROP(Shield,_RimSclae);
				float clampResult17 = clamp( ( ( pow( saferPower19 , _RimPower ) * _RimSclae_Instance ) + _HoloBias ) , 0.0 , 1.0 );
				float HoloAlpha26 = clampResult17;
				float BasicAlpha49 = ( ( ( _LineIntensity * tex2DNode34.r ) + ( tex2DNode34.r * ( smoothstepResult403 * _FlowIntensity ) ) ) + HoloAlpha26 );
				float3 objToWorld217 = mul( GetObjectToWorldMatrix(), float4( ( _DissolvePos * 0.01 ), 1 ) ).xyz;
				float3 OBJ2WRLD413 = objToWorld217;
				float3 objToWorld363 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 objToWorld55 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 temp_output_3_0_g1 = ( PositionWS - objToWorld55 );
				float3 temp_output_6_0_g2 = NormalWS;
				float dotResult1_g2 = dot( temp_output_3_0_g1 , temp_output_6_0_g2 );
				float dotResult2_g2 = dot( temp_output_6_0_g2 , temp_output_6_0_g2 );
				float3 temp_output_58_0 = ( temp_output_3_0_g1 - ( ( dotResult1_g2 / dotResult2_g2 ) * temp_output_6_0_g2 ) );
				float3 CenterPos62 = ( PositionWS - temp_output_58_0 );
				float3 OriginWorldPos408 = objToWorld363;
				float dotResult362 = dot( ( OBJ2WRLD413 - objToWorld363 ) , ( CenterPos62 - OriginWorldPos408 ) );
				float ShieldRadius446 = distance( PositionWS , OriginWorldPos408 );
				float temp_output_385_0 = ( acos( ( dotResult362 / ( ShieldRadius446 * ShieldRadius446 ) ) ) + _DissolveAmount );
				float Dissolve91 = step( 0.01 , temp_output_385_0 );
				float DissolveRim351 = ( step( 0.1 , ( temp_output_385_0 + _DissolveRimWidth ) ) - Dissolve91 );
				float3 WorldPos498 = PositionWS;
				float3 OriginWorldPos498 = OriginWorldPos408;
				float ShieldRadius498 = ShieldRadius446;
				float3 TestPos498 = _TestPos;
				float HitRimTest498 = _HitRimTest;
				float Scale283 = _Scale;
				float simplePerlin3D500 = snoise( ( PositionWS * 5.0 * ( 1.0 / Scale283 ) ) );
				simplePerlin3D500 = simplePerlin3D500*0.5 + 0.5;
				float Noise498 = ( simplePerlin3D500 * -0.11 );
				float localHitWave498 = HitWave498( WorldPos498 , OriginWorldPos498 , ShieldRadius498 , TestPos498 , HitRimTest498 , Noise498 );
				float HitRim489 = localHitWave498;
				float3 WorldPos417 = CenterPos62;
				float3 OriginWorldPos417 = OriginWorldPos408;
				float ShieldRadius417 = ShieldRadius446;
				float3 TestPos417 = _TestPos;
				float HitWaveTest417 = _HitWaveTest;
				float localHitWave417 = HitWave417( WorldPos417 , OriginWorldPos417 , ShieldRadius417 , TestPos417 , HitWaveTest417 );
				float HitWave419 = localHitWave417;
				float clampResult523 = clamp(  (-1.0 + ( HitWave419 - 0.0 ) * ( 2.0 - -1.0 ) / ( 1.0 - 0.0 ) ) , 0.0 , 1.0 );
				float screenDepth526 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ScreenPosNorm.xy ),_ZBufferParams);
				float distanceDepth526 = ( screenDepth526 - LinearEyeDepth( ScreenPosNorm.z,_ZBufferParams ) ) / ( _DepthFadeDistance );
				float clampResult536 = clamp( ( 1.0 - distanceDepth526 ) , 0.0 , 1.0 );
				float DepthFade529 = clampResult536;
				float clampResult147 = clamp( ( ( ( BasicAlpha49 * Dissolve91 ) + DissolveRim351 + ( ( HitRim489 * _HitRimIntense ) + ( _HitWaveIntense * clampResult523 ) ) ) + ( step( 0.001 , ( Dissolve91 * DepthFade529 ) ) * DepthFade529 ) ) , 0.0 , 1.0 );
				float FinalAlpha104 = clampResult147;
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = MainColor137.rgb;
				float Alpha = FinalAlpha104;
				float AlphaClipThreshold = 0.0;
				float AlphaClipThresholdShadow = 0.5;

				#if defined( ASE_DEPTH_WRITE_ON )
					float DeviceDepth = input.positionCS.z;
				#endif

				#if defined( _ALPHATEST_ON )
					AlphaDiscard( Alpha, AlphaClipThreshold );
				#endif

				#if defined(MAIN_LIGHT_CALCULATE_SHADOWS) && defined(ASE_CHANGES_WORLD_POS)
					ShadowCoord = TransformWorldToShadowCoord( PositionWS );
				#endif

				InputData inputData = (InputData)0;
				inputData.positionWS = PositionWS;
				inputData.positionCS = float4( input.positionCS.xy, ClipPos.zw / ClipPos.w );
				inputData.normalizedScreenSpaceUV = ScreenPosNorm.xy;
				inputData.normalWS = NormalWS;
				inputData.viewDirectionWS = ViewDirWS;

				#ifdef ASE_FOG
					inputData.fogCoord = InitializeInputDataFog(float4(inputData.positionWS, 1.0), input.positionWSAndFogFactor.w);
				#endif

				#if defined(_DBUFFER)
					ApplyDecalToBaseColor(input.positionCS, Color);
				#endif

				#ifdef ASE_FOG
					#ifdef TERRAIN_SPLAT_ADDPASS
						Color.rgb = MixFogColor(Color.rgb, half3(0,0,0), inputData.fogCoord);
					#else
						Color.rgb = MixFog(Color.rgb, inputData.fogCoord);
					#endif
				#endif

				#if defined( ASE_DEPTH_WRITE_ON )
					outputDepth = DeviceDepth;
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif

				#if defined( ASE_OPAQUE_KEEP_ALPHA )
					return half4( Color, Alpha );
				#else
					return half4( Color, OutputAlpha( Alpha, isTransparent ) );
				#endif
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off
			ColorMask 0

			HLSLPROGRAM

			

			#pragma multi_compile_local _ALPHATEST_ON
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_VERSION 19904
			#define ASE_SRP_VERSION 140012
			#define REQUIRE_DEPTH_TEXTURE 1


			

			#pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_SHADOWCASTER

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_SCREEN_POSITION_NORMALIZED
			#pragma multi_compile_instancing


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct Attributes
			{
				float4 positionOS : POSITION;
				half3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MainColor;
			float3 _DissolvePos;
			float3 _TestPos;
			float _VertOffsetIntense;
			float _HitRimIntense;
			float _Scale;
			float _HitRimTest;
			float _DissolveRimWidth;
			float _HoloBias;
			float _FlowIntensity;
			float _HitWaveIntense;
			float _LineIntensity;
			float _MainColorintensity;
			float _HitWaveTest;
			float _DissolveAmount;
			float _RimPower;
			float _DepthFadeDistance;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float ParticleCrntSize[10];
			float ParticleFinalSize[10];
			float4 HitPos[10];
			sampler2D _Line;
			sampler2D _Grid;
			UNITY_INSTANCING_BUFFER_START(Shield)
				UNITY_DEFINE_INSTANCED_PROP(float, _RimSclae)
			UNITY_INSTANCING_BUFFER_END(Shield)


			float3 ASESafeNormalize(float3 inVec)
			{
				float dp3 = max(1.175494351e-38, dot(inVec, inVec));
				return inVec* rsqrt(dp3);
			}
			
			float HitWave417( float3 WorldPos, float3 OriginWorldPos, float ShieldRadius, float3 TestPos, float HitWaveTest )
			{
				float result = 0.0f;
				for(int j = 0; j < 10; j++)
				{	
					float fade = 1.0f - saturate(1.0f * ParticleCrntSize[j] / ParticleFinalSize[j]);
					float3 newR = normalize(HitPos[j].xyz - OriginWorldPos);
					//float3 newR = normalize(TestPos - OriginWorldPos);
					float3 newPos = OriginWorldPos + newR * ShieldRadius;
					float3 a = newPos - OriginWorldPos;
					float3 b = WorldPos - OriginWorldPos;
					float wave = dot(a, b) / (ShieldRadius * ShieldRadius);
					//wave = acos(wave) - HitWaveTest;
					wave = acos(wave) - ParticleCrntSize[j];
					float mask = 1.0f - step(0.001, wave);
					wave = distance(0, wave) * mask;
					wave = 1.0f - saturate(wave);
					wave *= mask;
					wave = smoothstep(0.3f, 1.05f, wave);	
					result += wave * fade;
					
				}
				return saturate(result);
			}
			
			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			float HitWave498( float3 WorldPos, float3 OriginWorldPos, float ShieldRadius, float3 TestPos, float HitRimTest, float Noise )
			{
				float result = 0.0f;
				for(int j = 0; j < 10; j++)
				{	
					float fade = 1.0f - saturate(1.0f * ParticleCrntSize[j] / ParticleFinalSize[j]);
					float3 newR = normalize(HitPos[j].xyz - OriginWorldPos);
					//float3 newR = normalize(TestPos - OriginWorldPos);
					float3 newPos = OriginWorldPos + newR * ShieldRadius;
					float3 a = newPos - OriginWorldPos;
					float3 b = WorldPos - OriginWorldPos;
					float rim = dot(a, b) / (ShieldRadius * ShieldRadius);
					//rim = acos(rim) - HitRimTest;
					rim = acos(rim) - ParticleCrntSize[j];
					float mask = 1.0f - step(0.001, rim);
					rim = distance(Noise, rim) * mask;
					rim = 1.0f - saturate(rim);
					rim *= mask;
					rim = smoothstep(0.95f, 1.1f, rim);	
					result += rim * fade;
				}
				return saturate(result);
			}
			

			float3 _LightDirection;
			float3 _LightPosition;

			PackedVaryings VertexFunction( Attributes input )
			{
				PackedVaryings output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( output );

				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				float3 objToWorld55 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 temp_output_3_0_g1 = ( ase_positionWS - objToWorld55 );
				float3 ase_normalWS = TransformObjectToWorldNormal( input.normalOS );
				float3 temp_output_6_0_g2 = ase_normalWS;
				float dotResult1_g2 = dot( temp_output_3_0_g1 , temp_output_6_0_g2 );
				float dotResult2_g2 = dot( temp_output_6_0_g2 , temp_output_6_0_g2 );
				float3 temp_output_58_0 = ( temp_output_3_0_g1 - ( ( dotResult1_g2 / dotResult2_g2 ) * temp_output_6_0_g2 ) );
				float3 Point2CenterDir69 = -temp_output_58_0;
				float3 worldToObjDir439 = ASESafeNormalize( mul( GetWorldToObjectMatrix(), float4( Point2CenterDir69, 0.0 ) ).xyz );
				float3 objToWorld217 = mul( GetObjectToWorldMatrix(), float4( ( _DissolvePos * 0.01 ), 1 ) ).xyz;
				float3 OBJ2WRLD413 = objToWorld217;
				float3 objToWorld363 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 CenterPos62 = ( ase_positionWS - temp_output_58_0 );
				float3 OriginWorldPos408 = objToWorld363;
				float dotResult362 = dot( ( OBJ2WRLD413 - objToWorld363 ) , ( CenterPos62 - OriginWorldPos408 ) );
				float ShieldRadius446 = distance( ase_positionWS , OriginWorldPos408 );
				float temp_output_385_0 = ( acos( ( dotResult362 / ( ShieldRadius446 * ShieldRadius446 ) ) ) + _DissolveAmount );
				float clampResult400 = clamp( ( 0.92 + temp_output_385_0 ) , 0.0 , 1.0 );
				float VertOffsetFactor269 = ( 1.0 - clampResult400 );
				float3 WorldPos417 = CenterPos62;
				float3 OriginWorldPos417 = OriginWorldPos408;
				float ShieldRadius417 = ShieldRadius446;
				float3 TestPos417 = _TestPos;
				float HitWaveTest417 = _HitWaveTest;
				float localHitWave417 = HitWave417( WorldPos417 , OriginWorldPos417 , ShieldRadius417 , TestPos417 , HitWaveTest417 );
				float HitWave419 = localHitWave417;
				float3 worldToObjDir438 = ASESafeNormalize( mul( GetWorldToObjectMatrix(), float4( ase_normalWS, 0.0 ) ).xyz );
				float3 temp_output_423_0 = ( HitWave419 * 0.03 * 0.02 * worldToObjDir438 );
				float3 VertOffsset149 = ( ( worldToObjDir439 * _VertOffsetIntense * 0.01 * VertOffsetFactor269 ) + temp_output_423_0 );
				
				output.ase_texcoord1.xyz = ase_normalWS;
				output.ase_texcoord2.xyz = ase_positionWS;
				
				output.ase_texcoord.xy = input.ase_texcoord.xy;
				output.ase_texcoord.zw = input.ase_texcoord1.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord1.w = 0;
				output.ase_texcoord2.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = VertOffsset149;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;

				float3 positionWS = TransformObjectToWorld( input.positionOS.xyz );
				half3 normalWS = TransformObjectToWorldDir(input.normalOS);

				#if _CASTING_PUNCTUAL_LIGHT_SHADOW
					float3 lightDirectionWS = normalize(_LightPosition - positionWS);
				#else
					float3 lightDirectionWS = _LightDirection;
				#endif

				float4 positionCS = TransformWorldToHClip(ApplyShadowBias(positionWS, normalWS, lightDirectionWS));

				#if UNITY_REVERSED_Z
					positionCS.z = min(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#else
					positionCS.z = max(positionCS.z, UNITY_NEAR_CLIP_VALUE);
				#endif

				output.positionCS = positionCS;
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.ase_texcoord = input.ase_texcoord;
				output.ase_texcoord1 = input.ase_texcoord1;
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				output.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag(PackedVaryings input
						#if defined( ASE_DEPTH_WRITE_ON )
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( input );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( input );

				float4 ScreenPosNorm = float4( GetNormalizedScreenSpaceUV( input.positionCS ), input.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, input.positionCS.z ) * input.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos );

				float2 texCoord35 = input.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float4 tex2DNode34 = tex2D( _Line, texCoord35 );
				float2 texCoord29 = input.ase_texcoord.zw * float2( 1,1 ) + float2( 0,0 );
				float mulTime33 = _TimeParameters.x * 0.01;
				float smoothstepResult403 = smoothstep( 0.05 , 0.95 , tex2D( _Grid, ( texCoord29 + mulTime33 ) ).r);
				float3 ase_normalWS = input.ase_texcoord1.xyz;
				float3 ase_positionWS = input.ase_texcoord2.xyz;
				float3 ase_viewVectorWS = ( _WorldSpaceCameraPos.xyz - ase_positionWS );
				float3 ase_viewDirWS = normalize( ase_viewVectorWS );
				float dotResult15 = dot( ase_normalWS , ase_viewDirWS );
				float saferPower19 = abs( ( 1.0 - dotResult15 ) );
				float _RimSclae_Instance = UNITY_ACCESS_INSTANCED_PROP(Shield,_RimSclae);
				float clampResult17 = clamp( ( ( pow( saferPower19 , _RimPower ) * _RimSclae_Instance ) + _HoloBias ) , 0.0 , 1.0 );
				float HoloAlpha26 = clampResult17;
				float BasicAlpha49 = ( ( ( _LineIntensity * tex2DNode34.r ) + ( tex2DNode34.r * ( smoothstepResult403 * _FlowIntensity ) ) ) + HoloAlpha26 );
				float3 objToWorld217 = mul( GetObjectToWorldMatrix(), float4( ( _DissolvePos * 0.01 ), 1 ) ).xyz;
				float3 OBJ2WRLD413 = objToWorld217;
				float3 objToWorld363 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 objToWorld55 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 temp_output_3_0_g1 = ( ase_positionWS - objToWorld55 );
				float3 temp_output_6_0_g2 = ase_normalWS;
				float dotResult1_g2 = dot( temp_output_3_0_g1 , temp_output_6_0_g2 );
				float dotResult2_g2 = dot( temp_output_6_0_g2 , temp_output_6_0_g2 );
				float3 temp_output_58_0 = ( temp_output_3_0_g1 - ( ( dotResult1_g2 / dotResult2_g2 ) * temp_output_6_0_g2 ) );
				float3 CenterPos62 = ( ase_positionWS - temp_output_58_0 );
				float3 OriginWorldPos408 = objToWorld363;
				float dotResult362 = dot( ( OBJ2WRLD413 - objToWorld363 ) , ( CenterPos62 - OriginWorldPos408 ) );
				float ShieldRadius446 = distance( ase_positionWS , OriginWorldPos408 );
				float temp_output_385_0 = ( acos( ( dotResult362 / ( ShieldRadius446 * ShieldRadius446 ) ) ) + _DissolveAmount );
				float Dissolve91 = step( 0.01 , temp_output_385_0 );
				float DissolveRim351 = ( step( 0.1 , ( temp_output_385_0 + _DissolveRimWidth ) ) - Dissolve91 );
				float3 WorldPos498 = ase_positionWS;
				float3 OriginWorldPos498 = OriginWorldPos408;
				float ShieldRadius498 = ShieldRadius446;
				float3 TestPos498 = _TestPos;
				float HitRimTest498 = _HitRimTest;
				float Scale283 = _Scale;
				float simplePerlin3D500 = snoise( ( ase_positionWS * 5.0 * ( 1.0 / Scale283 ) ) );
				simplePerlin3D500 = simplePerlin3D500*0.5 + 0.5;
				float Noise498 = ( simplePerlin3D500 * -0.11 );
				float localHitWave498 = HitWave498( WorldPos498 , OriginWorldPos498 , ShieldRadius498 , TestPos498 , HitRimTest498 , Noise498 );
				float HitRim489 = localHitWave498;
				float3 WorldPos417 = CenterPos62;
				float3 OriginWorldPos417 = OriginWorldPos408;
				float ShieldRadius417 = ShieldRadius446;
				float3 TestPos417 = _TestPos;
				float HitWaveTest417 = _HitWaveTest;
				float localHitWave417 = HitWave417( WorldPos417 , OriginWorldPos417 , ShieldRadius417 , TestPos417 , HitWaveTest417 );
				float HitWave419 = localHitWave417;
				float clampResult523 = clamp(  (-1.0 + ( HitWave419 - 0.0 ) * ( 2.0 - -1.0 ) / ( 1.0 - 0.0 ) ) , 0.0 , 1.0 );
				float screenDepth526 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ScreenPosNorm.xy ),_ZBufferParams);
				float distanceDepth526 = ( screenDepth526 - LinearEyeDepth( ScreenPosNorm.z,_ZBufferParams ) ) / ( _DepthFadeDistance );
				float clampResult536 = clamp( ( 1.0 - distanceDepth526 ) , 0.0 , 1.0 );
				float DepthFade529 = clampResult536;
				float clampResult147 = clamp( ( ( ( BasicAlpha49 * Dissolve91 ) + DissolveRim351 + ( ( HitRim489 * _HitRimIntense ) + ( _HitWaveIntense * clampResult523 ) ) ) + ( step( 0.001 , ( Dissolve91 * DepthFade529 ) ) * DepthFade529 ) ) , 0.0 , 1.0 );
				float FinalAlpha104 = clampResult147;
				

				float Alpha = FinalAlpha104;
				float AlphaClipThreshold = 0.0;
				float AlphaClipThresholdShadow = 0.5;

				#if defined( ASE_DEPTH_WRITE_ON )
					float DeviceDepth = input.positionCS.z;
				#endif

				#if defined( _ALPHATEST_ON )
					#if defined( _ALPHATEST_SHADOW_ON )
						AlphaDiscard( Alpha, AlphaClipThresholdShadow );
					#else
						AlphaDiscard( Alpha, AlphaClipThreshold );
					#endif
				#endif

				#if defined(LOD_FADE_CROSSFADE)
					LODFadeCrossFade( input.positionCS );
				#endif

				#if defined( ASE_DEPTH_WRITE_ON )
					outputDepth = DeviceDepth;
				#endif

				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM

			

			#pragma multi_compile_local _ALPHATEST_ON
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_VERSION 19904
			#define ASE_SRP_VERSION 140012
			#define REQUIRE_DEPTH_TEXTURE 1


			

			#pragma vertex vert
			#pragma fragment frag

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_FRAG_SCREEN_POSITION_NORMALIZED
			#pragma multi_compile_instancing


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct Attributes
			{
				float4 positionOS : POSITION;
				half3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MainColor;
			float3 _DissolvePos;
			float3 _TestPos;
			float _VertOffsetIntense;
			float _HitRimIntense;
			float _Scale;
			float _HitRimTest;
			float _DissolveRimWidth;
			float _HoloBias;
			float _FlowIntensity;
			float _HitWaveIntense;
			float _LineIntensity;
			float _MainColorintensity;
			float _HitWaveTest;
			float _DissolveAmount;
			float _RimPower;
			float _DepthFadeDistance;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float ParticleCrntSize[10];
			float ParticleFinalSize[10];
			float4 HitPos[10];
			sampler2D _Line;
			sampler2D _Grid;
			UNITY_INSTANCING_BUFFER_START(Shield)
				UNITY_DEFINE_INSTANCED_PROP(float, _RimSclae)
			UNITY_INSTANCING_BUFFER_END(Shield)


			float3 ASESafeNormalize(float3 inVec)
			{
				float dp3 = max(1.175494351e-38, dot(inVec, inVec));
				return inVec* rsqrt(dp3);
			}
			
			float HitWave417( float3 WorldPos, float3 OriginWorldPos, float ShieldRadius, float3 TestPos, float HitWaveTest )
			{
				float result = 0.0f;
				for(int j = 0; j < 10; j++)
				{	
					float fade = 1.0f - saturate(1.0f * ParticleCrntSize[j] / ParticleFinalSize[j]);
					float3 newR = normalize(HitPos[j].xyz - OriginWorldPos);
					//float3 newR = normalize(TestPos - OriginWorldPos);
					float3 newPos = OriginWorldPos + newR * ShieldRadius;
					float3 a = newPos - OriginWorldPos;
					float3 b = WorldPos - OriginWorldPos;
					float wave = dot(a, b) / (ShieldRadius * ShieldRadius);
					//wave = acos(wave) - HitWaveTest;
					wave = acos(wave) - ParticleCrntSize[j];
					float mask = 1.0f - step(0.001, wave);
					wave = distance(0, wave) * mask;
					wave = 1.0f - saturate(wave);
					wave *= mask;
					wave = smoothstep(0.3f, 1.05f, wave);	
					result += wave * fade;
					
				}
				return saturate(result);
			}
			
			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			float HitWave498( float3 WorldPos, float3 OriginWorldPos, float ShieldRadius, float3 TestPos, float HitRimTest, float Noise )
			{
				float result = 0.0f;
				for(int j = 0; j < 10; j++)
				{	
					float fade = 1.0f - saturate(1.0f * ParticleCrntSize[j] / ParticleFinalSize[j]);
					float3 newR = normalize(HitPos[j].xyz - OriginWorldPos);
					//float3 newR = normalize(TestPos - OriginWorldPos);
					float3 newPos = OriginWorldPos + newR * ShieldRadius;
					float3 a = newPos - OriginWorldPos;
					float3 b = WorldPos - OriginWorldPos;
					float rim = dot(a, b) / (ShieldRadius * ShieldRadius);
					//rim = acos(rim) - HitRimTest;
					rim = acos(rim) - ParticleCrntSize[j];
					float mask = 1.0f - step(0.001, rim);
					rim = distance(Noise, rim) * mask;
					rim = 1.0f - saturate(rim);
					rim *= mask;
					rim = smoothstep(0.95f, 1.1f, rim);	
					result += rim * fade;
				}
				return saturate(result);
			}
			

			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output = (PackedVaryings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				float3 objToWorld55 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 temp_output_3_0_g1 = ( ase_positionWS - objToWorld55 );
				float3 ase_normalWS = TransformObjectToWorldNormal( input.normalOS );
				float3 temp_output_6_0_g2 = ase_normalWS;
				float dotResult1_g2 = dot( temp_output_3_0_g1 , temp_output_6_0_g2 );
				float dotResult2_g2 = dot( temp_output_6_0_g2 , temp_output_6_0_g2 );
				float3 temp_output_58_0 = ( temp_output_3_0_g1 - ( ( dotResult1_g2 / dotResult2_g2 ) * temp_output_6_0_g2 ) );
				float3 Point2CenterDir69 = -temp_output_58_0;
				float3 worldToObjDir439 = ASESafeNormalize( mul( GetWorldToObjectMatrix(), float4( Point2CenterDir69, 0.0 ) ).xyz );
				float3 objToWorld217 = mul( GetObjectToWorldMatrix(), float4( ( _DissolvePos * 0.01 ), 1 ) ).xyz;
				float3 OBJ2WRLD413 = objToWorld217;
				float3 objToWorld363 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 CenterPos62 = ( ase_positionWS - temp_output_58_0 );
				float3 OriginWorldPos408 = objToWorld363;
				float dotResult362 = dot( ( OBJ2WRLD413 - objToWorld363 ) , ( CenterPos62 - OriginWorldPos408 ) );
				float ShieldRadius446 = distance( ase_positionWS , OriginWorldPos408 );
				float temp_output_385_0 = ( acos( ( dotResult362 / ( ShieldRadius446 * ShieldRadius446 ) ) ) + _DissolveAmount );
				float clampResult400 = clamp( ( 0.92 + temp_output_385_0 ) , 0.0 , 1.0 );
				float VertOffsetFactor269 = ( 1.0 - clampResult400 );
				float3 WorldPos417 = CenterPos62;
				float3 OriginWorldPos417 = OriginWorldPos408;
				float ShieldRadius417 = ShieldRadius446;
				float3 TestPos417 = _TestPos;
				float HitWaveTest417 = _HitWaveTest;
				float localHitWave417 = HitWave417( WorldPos417 , OriginWorldPos417 , ShieldRadius417 , TestPos417 , HitWaveTest417 );
				float HitWave419 = localHitWave417;
				float3 worldToObjDir438 = ASESafeNormalize( mul( GetWorldToObjectMatrix(), float4( ase_normalWS, 0.0 ) ).xyz );
				float3 temp_output_423_0 = ( HitWave419 * 0.03 * 0.02 * worldToObjDir438 );
				float3 VertOffsset149 = ( ( worldToObjDir439 * _VertOffsetIntense * 0.01 * VertOffsetFactor269 ) + temp_output_423_0 );
				
				output.ase_texcoord1.xyz = ase_normalWS;
				output.ase_texcoord2.xyz = ase_positionWS;
				
				output.ase_texcoord.xy = input.ase_texcoord.xy;
				output.ase_texcoord.zw = input.ase_texcoord1.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord1.w = 0;
				output.ase_texcoord2.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = VertOffsset149;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );

				output.positionCS = vertexInput.positionCS;
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.ase_texcoord = input.ase_texcoord;
				output.ase_texcoord1 = input.ase_texcoord1;
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				output.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag(PackedVaryings input
						#if defined( ASE_DEPTH_WRITE_ON )
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( input );

				float4 ScreenPosNorm = float4( GetNormalizedScreenSpaceUV( input.positionCS ), input.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, input.positionCS.z ) * input.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos );

				float2 texCoord35 = input.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float4 tex2DNode34 = tex2D( _Line, texCoord35 );
				float2 texCoord29 = input.ase_texcoord.zw * float2( 1,1 ) + float2( 0,0 );
				float mulTime33 = _TimeParameters.x * 0.01;
				float smoothstepResult403 = smoothstep( 0.05 , 0.95 , tex2D( _Grid, ( texCoord29 + mulTime33 ) ).r);
				float3 ase_normalWS = input.ase_texcoord1.xyz;
				float3 ase_positionWS = input.ase_texcoord2.xyz;
				float3 ase_viewVectorWS = ( _WorldSpaceCameraPos.xyz - ase_positionWS );
				float3 ase_viewDirWS = normalize( ase_viewVectorWS );
				float dotResult15 = dot( ase_normalWS , ase_viewDirWS );
				float saferPower19 = abs( ( 1.0 - dotResult15 ) );
				float _RimSclae_Instance = UNITY_ACCESS_INSTANCED_PROP(Shield,_RimSclae);
				float clampResult17 = clamp( ( ( pow( saferPower19 , _RimPower ) * _RimSclae_Instance ) + _HoloBias ) , 0.0 , 1.0 );
				float HoloAlpha26 = clampResult17;
				float BasicAlpha49 = ( ( ( _LineIntensity * tex2DNode34.r ) + ( tex2DNode34.r * ( smoothstepResult403 * _FlowIntensity ) ) ) + HoloAlpha26 );
				float3 objToWorld217 = mul( GetObjectToWorldMatrix(), float4( ( _DissolvePos * 0.01 ), 1 ) ).xyz;
				float3 OBJ2WRLD413 = objToWorld217;
				float3 objToWorld363 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 objToWorld55 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 temp_output_3_0_g1 = ( ase_positionWS - objToWorld55 );
				float3 temp_output_6_0_g2 = ase_normalWS;
				float dotResult1_g2 = dot( temp_output_3_0_g1 , temp_output_6_0_g2 );
				float dotResult2_g2 = dot( temp_output_6_0_g2 , temp_output_6_0_g2 );
				float3 temp_output_58_0 = ( temp_output_3_0_g1 - ( ( dotResult1_g2 / dotResult2_g2 ) * temp_output_6_0_g2 ) );
				float3 CenterPos62 = ( ase_positionWS - temp_output_58_0 );
				float3 OriginWorldPos408 = objToWorld363;
				float dotResult362 = dot( ( OBJ2WRLD413 - objToWorld363 ) , ( CenterPos62 - OriginWorldPos408 ) );
				float ShieldRadius446 = distance( ase_positionWS , OriginWorldPos408 );
				float temp_output_385_0 = ( acos( ( dotResult362 / ( ShieldRadius446 * ShieldRadius446 ) ) ) + _DissolveAmount );
				float Dissolve91 = step( 0.01 , temp_output_385_0 );
				float DissolveRim351 = ( step( 0.1 , ( temp_output_385_0 + _DissolveRimWidth ) ) - Dissolve91 );
				float3 WorldPos498 = ase_positionWS;
				float3 OriginWorldPos498 = OriginWorldPos408;
				float ShieldRadius498 = ShieldRadius446;
				float3 TestPos498 = _TestPos;
				float HitRimTest498 = _HitRimTest;
				float Scale283 = _Scale;
				float simplePerlin3D500 = snoise( ( ase_positionWS * 5.0 * ( 1.0 / Scale283 ) ) );
				simplePerlin3D500 = simplePerlin3D500*0.5 + 0.5;
				float Noise498 = ( simplePerlin3D500 * -0.11 );
				float localHitWave498 = HitWave498( WorldPos498 , OriginWorldPos498 , ShieldRadius498 , TestPos498 , HitRimTest498 , Noise498 );
				float HitRim489 = localHitWave498;
				float3 WorldPos417 = CenterPos62;
				float3 OriginWorldPos417 = OriginWorldPos408;
				float ShieldRadius417 = ShieldRadius446;
				float3 TestPos417 = _TestPos;
				float HitWaveTest417 = _HitWaveTest;
				float localHitWave417 = HitWave417( WorldPos417 , OriginWorldPos417 , ShieldRadius417 , TestPos417 , HitWaveTest417 );
				float HitWave419 = localHitWave417;
				float clampResult523 = clamp(  (-1.0 + ( HitWave419 - 0.0 ) * ( 2.0 - -1.0 ) / ( 1.0 - 0.0 ) ) , 0.0 , 1.0 );
				float screenDepth526 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ScreenPosNorm.xy ),_ZBufferParams);
				float distanceDepth526 = ( screenDepth526 - LinearEyeDepth( ScreenPosNorm.z,_ZBufferParams ) ) / ( _DepthFadeDistance );
				float clampResult536 = clamp( ( 1.0 - distanceDepth526 ) , 0.0 , 1.0 );
				float DepthFade529 = clampResult536;
				float clampResult147 = clamp( ( ( ( BasicAlpha49 * Dissolve91 ) + DissolveRim351 + ( ( HitRim489 * _HitRimIntense ) + ( _HitWaveIntense * clampResult523 ) ) ) + ( step( 0.001 , ( Dissolve91 * DepthFade529 ) ) * DepthFade529 ) ) , 0.0 , 1.0 );
				float FinalAlpha104 = clampResult147;
				

				float Alpha = FinalAlpha104;
				float AlphaClipThreshold = 0.0;

				#if defined( ASE_DEPTH_WRITE_ON )
					float DeviceDepth = input.positionCS.z;
				#endif

				#if defined( _ALPHATEST_ON )
					AlphaDiscard( Alpha, AlphaClipThreshold );
				#endif

				#if defined(LOD_FADE_CROSSFADE)
					LODFadeCrossFade( input.positionCS );
				#endif

				#if defined( ASE_DEPTH_WRITE_ON )
					outputDepth = DeviceDepth;
				#endif

				return 0;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "SceneSelectionPass"
			Tags { "LightMode"="SceneSelectionPass" }

			Cull Off
			AlphaToMask Off

			HLSLPROGRAM

			

			#pragma multi_compile_local _ALPHATEST_ON
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_VERSION 19904
			#define ASE_SRP_VERSION 140012
			#define REQUIRE_DEPTH_TEXTURE 1


			

			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define SHADERPASS SHADERPASS_DEPTHONLY

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			
			#if ASE_SRP_VERSION >=140010
			#include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
			#endif
		

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#pragma multi_compile_instancing


			struct Attributes
			{
				float4 positionOS : POSITION;
				half3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MainColor;
			float3 _DissolvePos;
			float3 _TestPos;
			float _VertOffsetIntense;
			float _HitRimIntense;
			float _Scale;
			float _HitRimTest;
			float _DissolveRimWidth;
			float _HoloBias;
			float _FlowIntensity;
			float _HitWaveIntense;
			float _LineIntensity;
			float _MainColorintensity;
			float _HitWaveTest;
			float _DissolveAmount;
			float _RimPower;
			float _DepthFadeDistance;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float ParticleCrntSize[10];
			float ParticleFinalSize[10];
			float4 HitPos[10];
			sampler2D _Line;
			sampler2D _Grid;
			UNITY_INSTANCING_BUFFER_START(Shield)
				UNITY_DEFINE_INSTANCED_PROP(float, _RimSclae)
			UNITY_INSTANCING_BUFFER_END(Shield)


			float3 ASESafeNormalize(float3 inVec)
			{
				float dp3 = max(1.175494351e-38, dot(inVec, inVec));
				return inVec* rsqrt(dp3);
			}
			
			float HitWave417( float3 WorldPos, float3 OriginWorldPos, float ShieldRadius, float3 TestPos, float HitWaveTest )
			{
				float result = 0.0f;
				for(int j = 0; j < 10; j++)
				{	
					float fade = 1.0f - saturate(1.0f * ParticleCrntSize[j] / ParticleFinalSize[j]);
					float3 newR = normalize(HitPos[j].xyz - OriginWorldPos);
					//float3 newR = normalize(TestPos - OriginWorldPos);
					float3 newPos = OriginWorldPos + newR * ShieldRadius;
					float3 a = newPos - OriginWorldPos;
					float3 b = WorldPos - OriginWorldPos;
					float wave = dot(a, b) / (ShieldRadius * ShieldRadius);
					//wave = acos(wave) - HitWaveTest;
					wave = acos(wave) - ParticleCrntSize[j];
					float mask = 1.0f - step(0.001, wave);
					wave = distance(0, wave) * mask;
					wave = 1.0f - saturate(wave);
					wave *= mask;
					wave = smoothstep(0.3f, 1.05f, wave);	
					result += wave * fade;
					
				}
				return saturate(result);
			}
			
			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			float HitWave498( float3 WorldPos, float3 OriginWorldPos, float ShieldRadius, float3 TestPos, float HitRimTest, float Noise )
			{
				float result = 0.0f;
				for(int j = 0; j < 10; j++)
				{	
					float fade = 1.0f - saturate(1.0f * ParticleCrntSize[j] / ParticleFinalSize[j]);
					float3 newR = normalize(HitPos[j].xyz - OriginWorldPos);
					//float3 newR = normalize(TestPos - OriginWorldPos);
					float3 newPos = OriginWorldPos + newR * ShieldRadius;
					float3 a = newPos - OriginWorldPos;
					float3 b = WorldPos - OriginWorldPos;
					float rim = dot(a, b) / (ShieldRadius * ShieldRadius);
					//rim = acos(rim) - HitRimTest;
					rim = acos(rim) - ParticleCrntSize[j];
					float mask = 1.0f - step(0.001, rim);
					rim = distance(Noise, rim) * mask;
					rim = 1.0f - saturate(rim);
					rim *= mask;
					rim = smoothstep(0.95f, 1.1f, rim);	
					result += rim * fade;
				}
				return saturate(result);
			}
			

			int _ObjectId;
			int _PassValue;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			PackedVaryings VertexFunction(Attributes input  )
			{
				PackedVaryings output;
				ZERO_INITIALIZE(PackedVaryings, output);

				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				float3 objToWorld55 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 temp_output_3_0_g1 = ( ase_positionWS - objToWorld55 );
				float3 ase_normalWS = TransformObjectToWorldNormal( input.normalOS );
				float3 temp_output_6_0_g2 = ase_normalWS;
				float dotResult1_g2 = dot( temp_output_3_0_g1 , temp_output_6_0_g2 );
				float dotResult2_g2 = dot( temp_output_6_0_g2 , temp_output_6_0_g2 );
				float3 temp_output_58_0 = ( temp_output_3_0_g1 - ( ( dotResult1_g2 / dotResult2_g2 ) * temp_output_6_0_g2 ) );
				float3 Point2CenterDir69 = -temp_output_58_0;
				float3 worldToObjDir439 = ASESafeNormalize( mul( GetWorldToObjectMatrix(), float4( Point2CenterDir69, 0.0 ) ).xyz );
				float3 objToWorld217 = mul( GetObjectToWorldMatrix(), float4( ( _DissolvePos * 0.01 ), 1 ) ).xyz;
				float3 OBJ2WRLD413 = objToWorld217;
				float3 objToWorld363 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 CenterPos62 = ( ase_positionWS - temp_output_58_0 );
				float3 OriginWorldPos408 = objToWorld363;
				float dotResult362 = dot( ( OBJ2WRLD413 - objToWorld363 ) , ( CenterPos62 - OriginWorldPos408 ) );
				float ShieldRadius446 = distance( ase_positionWS , OriginWorldPos408 );
				float temp_output_385_0 = ( acos( ( dotResult362 / ( ShieldRadius446 * ShieldRadius446 ) ) ) + _DissolveAmount );
				float clampResult400 = clamp( ( 0.92 + temp_output_385_0 ) , 0.0 , 1.0 );
				float VertOffsetFactor269 = ( 1.0 - clampResult400 );
				float3 WorldPos417 = CenterPos62;
				float3 OriginWorldPos417 = OriginWorldPos408;
				float ShieldRadius417 = ShieldRadius446;
				float3 TestPos417 = _TestPos;
				float HitWaveTest417 = _HitWaveTest;
				float localHitWave417 = HitWave417( WorldPos417 , OriginWorldPos417 , ShieldRadius417 , TestPos417 , HitWaveTest417 );
				float HitWave419 = localHitWave417;
				float3 worldToObjDir438 = ASESafeNormalize( mul( GetWorldToObjectMatrix(), float4( ase_normalWS, 0.0 ) ).xyz );
				float3 temp_output_423_0 = ( HitWave419 * 0.03 * 0.02 * worldToObjDir438 );
				float3 VertOffsset149 = ( ( worldToObjDir439 * _VertOffsetIntense * 0.01 * VertOffsetFactor269 ) + temp_output_423_0 );
				
				output.ase_texcoord1.xyz = ase_normalWS;
				output.ase_texcoord2.xyz = ase_positionWS;
				float4 ase_positionCS = TransformObjectToHClip( ( input.positionOS ).xyz );
				float4 screenPos = ComputeScreenPos( ase_positionCS );
				output.ase_texcoord3 = screenPos;
				
				output.ase_texcoord.xy = input.ase_texcoord.xy;
				output.ase_texcoord.zw = input.ase_texcoord1.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord1.w = 0;
				output.ase_texcoord2.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = VertOffsset149;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );

				output.positionCS = vertexInput.positionCS;
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.ase_texcoord = input.ase_texcoord;
				output.ase_texcoord1 = input.ase_texcoord1;
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				output.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag(PackedVaryings input ) : SV_Target
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float2 texCoord35 = input.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float4 tex2DNode34 = tex2D( _Line, texCoord35 );
				float2 texCoord29 = input.ase_texcoord.zw * float2( 1,1 ) + float2( 0,0 );
				float mulTime33 = _TimeParameters.x * 0.01;
				float smoothstepResult403 = smoothstep( 0.05 , 0.95 , tex2D( _Grid, ( texCoord29 + mulTime33 ) ).r);
				float3 ase_normalWS = input.ase_texcoord1.xyz;
				float3 ase_positionWS = input.ase_texcoord2.xyz;
				float3 ase_viewVectorWS = ( _WorldSpaceCameraPos.xyz - ase_positionWS );
				float3 ase_viewDirWS = normalize( ase_viewVectorWS );
				float dotResult15 = dot( ase_normalWS , ase_viewDirWS );
				float saferPower19 = abs( ( 1.0 - dotResult15 ) );
				float _RimSclae_Instance = UNITY_ACCESS_INSTANCED_PROP(Shield,_RimSclae);
				float clampResult17 = clamp( ( ( pow( saferPower19 , _RimPower ) * _RimSclae_Instance ) + _HoloBias ) , 0.0 , 1.0 );
				float HoloAlpha26 = clampResult17;
				float BasicAlpha49 = ( ( ( _LineIntensity * tex2DNode34.r ) + ( tex2DNode34.r * ( smoothstepResult403 * _FlowIntensity ) ) ) + HoloAlpha26 );
				float3 objToWorld217 = mul( GetObjectToWorldMatrix(), float4( ( _DissolvePos * 0.01 ), 1 ) ).xyz;
				float3 OBJ2WRLD413 = objToWorld217;
				float3 objToWorld363 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 objToWorld55 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 temp_output_3_0_g1 = ( ase_positionWS - objToWorld55 );
				float3 temp_output_6_0_g2 = ase_normalWS;
				float dotResult1_g2 = dot( temp_output_3_0_g1 , temp_output_6_0_g2 );
				float dotResult2_g2 = dot( temp_output_6_0_g2 , temp_output_6_0_g2 );
				float3 temp_output_58_0 = ( temp_output_3_0_g1 - ( ( dotResult1_g2 / dotResult2_g2 ) * temp_output_6_0_g2 ) );
				float3 CenterPos62 = ( ase_positionWS - temp_output_58_0 );
				float3 OriginWorldPos408 = objToWorld363;
				float dotResult362 = dot( ( OBJ2WRLD413 - objToWorld363 ) , ( CenterPos62 - OriginWorldPos408 ) );
				float ShieldRadius446 = distance( ase_positionWS , OriginWorldPos408 );
				float temp_output_385_0 = ( acos( ( dotResult362 / ( ShieldRadius446 * ShieldRadius446 ) ) ) + _DissolveAmount );
				float Dissolve91 = step( 0.01 , temp_output_385_0 );
				float DissolveRim351 = ( step( 0.1 , ( temp_output_385_0 + _DissolveRimWidth ) ) - Dissolve91 );
				float3 WorldPos498 = ase_positionWS;
				float3 OriginWorldPos498 = OriginWorldPos408;
				float ShieldRadius498 = ShieldRadius446;
				float3 TestPos498 = _TestPos;
				float HitRimTest498 = _HitRimTest;
				float Scale283 = _Scale;
				float simplePerlin3D500 = snoise( ( ase_positionWS * 5.0 * ( 1.0 / Scale283 ) ) );
				simplePerlin3D500 = simplePerlin3D500*0.5 + 0.5;
				float Noise498 = ( simplePerlin3D500 * -0.11 );
				float localHitWave498 = HitWave498( WorldPos498 , OriginWorldPos498 , ShieldRadius498 , TestPos498 , HitRimTest498 , Noise498 );
				float HitRim489 = localHitWave498;
				float3 WorldPos417 = CenterPos62;
				float3 OriginWorldPos417 = OriginWorldPos408;
				float ShieldRadius417 = ShieldRadius446;
				float3 TestPos417 = _TestPos;
				float HitWaveTest417 = _HitWaveTest;
				float localHitWave417 = HitWave417( WorldPos417 , OriginWorldPos417 , ShieldRadius417 , TestPos417 , HitWaveTest417 );
				float HitWave419 = localHitWave417;
				float clampResult523 = clamp(  (-1.0 + ( HitWave419 - 0.0 ) * ( 2.0 - -1.0 ) / ( 1.0 - 0.0 ) ) , 0.0 , 1.0 );
				float4 screenPos = input.ase_texcoord3;
				float4 ase_positionSSNorm = screenPos / screenPos.w;
				ase_positionSSNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_positionSSNorm.z : ase_positionSSNorm.z * 0.5 + 0.5;
				float screenDepth526 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_positionSSNorm.xy ),_ZBufferParams);
				float distanceDepth526 = ( screenDepth526 - LinearEyeDepth( ase_positionSSNorm.z,_ZBufferParams ) ) / ( _DepthFadeDistance );
				float clampResult536 = clamp( ( 1.0 - distanceDepth526 ) , 0.0 , 1.0 );
				float DepthFade529 = clampResult536;
				float clampResult147 = clamp( ( ( ( BasicAlpha49 * Dissolve91 ) + DissolveRim351 + ( ( HitRim489 * _HitRimIntense ) + ( _HitWaveIntense * clampResult523 ) ) ) + ( step( 0.001 , ( Dissolve91 * DepthFade529 ) ) * DepthFade529 ) ) , 0.0 , 1.0 );
				float FinalAlpha104 = clampResult147;
				

				surfaceDescription.Alpha = FinalAlpha104;
				surfaceDescription.AlphaClipThreshold = 0.0;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = half4(_ObjectId, _PassValue, 1.0, 1.0);
				return outColor;
			}
			ENDHLSL
		}

		
		Pass
		{
			
			Name "ScenePickingPass"
			Tags { "LightMode"="Picking" }

			AlphaToMask Off

			HLSLPROGRAM

			

			#pragma multi_compile_local _ALPHATEST_ON
			#define _SURFACE_TYPE_TRANSPARENT 1
			#define ASE_VERSION 19904
			#define ASE_SRP_VERSION 140012
			#define REQUIRE_DEPTH_TEXTURE 1


			

			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT

			#define SHADERPASS SHADERPASS_DEPTHONLY

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			
			#if ASE_SRP_VERSION >=140010
			#include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
			#endif
		

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#pragma multi_compile_instancing


			struct Attributes
			{
				float4 positionOS : POSITION;
				half3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MainColor;
			float3 _DissolvePos;
			float3 _TestPos;
			float _VertOffsetIntense;
			float _HitRimIntense;
			float _Scale;
			float _HitRimTest;
			float _DissolveRimWidth;
			float _HoloBias;
			float _FlowIntensity;
			float _HitWaveIntense;
			float _LineIntensity;
			float _MainColorintensity;
			float _HitWaveTest;
			float _DissolveAmount;
			float _RimPower;
			float _DepthFadeDistance;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float ParticleCrntSize[10];
			float ParticleFinalSize[10];
			float4 HitPos[10];
			sampler2D _Line;
			sampler2D _Grid;
			UNITY_INSTANCING_BUFFER_START(Shield)
				UNITY_DEFINE_INSTANCED_PROP(float, _RimSclae)
			UNITY_INSTANCING_BUFFER_END(Shield)


			float3 ASESafeNormalize(float3 inVec)
			{
				float dp3 = max(1.175494351e-38, dot(inVec, inVec));
				return inVec* rsqrt(dp3);
			}
			
			float HitWave417( float3 WorldPos, float3 OriginWorldPos, float ShieldRadius, float3 TestPos, float HitWaveTest )
			{
				float result = 0.0f;
				for(int j = 0; j < 10; j++)
				{	
					float fade = 1.0f - saturate(1.0f * ParticleCrntSize[j] / ParticleFinalSize[j]);
					float3 newR = normalize(HitPos[j].xyz - OriginWorldPos);
					//float3 newR = normalize(TestPos - OriginWorldPos);
					float3 newPos = OriginWorldPos + newR * ShieldRadius;
					float3 a = newPos - OriginWorldPos;
					float3 b = WorldPos - OriginWorldPos;
					float wave = dot(a, b) / (ShieldRadius * ShieldRadius);
					//wave = acos(wave) - HitWaveTest;
					wave = acos(wave) - ParticleCrntSize[j];
					float mask = 1.0f - step(0.001, wave);
					wave = distance(0, wave) * mask;
					wave = 1.0f - saturate(wave);
					wave *= mask;
					wave = smoothstep(0.3f, 1.05f, wave);	
					result += wave * fade;
					
				}
				return saturate(result);
			}
			
			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			float HitWave498( float3 WorldPos, float3 OriginWorldPos, float ShieldRadius, float3 TestPos, float HitRimTest, float Noise )
			{
				float result = 0.0f;
				for(int j = 0; j < 10; j++)
				{	
					float fade = 1.0f - saturate(1.0f * ParticleCrntSize[j] / ParticleFinalSize[j]);
					float3 newR = normalize(HitPos[j].xyz - OriginWorldPos);
					//float3 newR = normalize(TestPos - OriginWorldPos);
					float3 newPos = OriginWorldPos + newR * ShieldRadius;
					float3 a = newPos - OriginWorldPos;
					float3 b = WorldPos - OriginWorldPos;
					float rim = dot(a, b) / (ShieldRadius * ShieldRadius);
					//rim = acos(rim) - HitRimTest;
					rim = acos(rim) - ParticleCrntSize[j];
					float mask = 1.0f - step(0.001, rim);
					rim = distance(Noise, rim) * mask;
					rim = 1.0f - saturate(rim);
					rim *= mask;
					rim = smoothstep(0.95f, 1.1f, rim);	
					result += rim * fade;
				}
				return saturate(result);
			}
			

			float4 _SelectionID;

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			PackedVaryings VertexFunction(Attributes input  )
			{
				PackedVaryings output;
				ZERO_INITIALIZE(PackedVaryings, output);

				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				float3 objToWorld55 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 temp_output_3_0_g1 = ( ase_positionWS - objToWorld55 );
				float3 ase_normalWS = TransformObjectToWorldNormal( input.normalOS );
				float3 temp_output_6_0_g2 = ase_normalWS;
				float dotResult1_g2 = dot( temp_output_3_0_g1 , temp_output_6_0_g2 );
				float dotResult2_g2 = dot( temp_output_6_0_g2 , temp_output_6_0_g2 );
				float3 temp_output_58_0 = ( temp_output_3_0_g1 - ( ( dotResult1_g2 / dotResult2_g2 ) * temp_output_6_0_g2 ) );
				float3 Point2CenterDir69 = -temp_output_58_0;
				float3 worldToObjDir439 = ASESafeNormalize( mul( GetWorldToObjectMatrix(), float4( Point2CenterDir69, 0.0 ) ).xyz );
				float3 objToWorld217 = mul( GetObjectToWorldMatrix(), float4( ( _DissolvePos * 0.01 ), 1 ) ).xyz;
				float3 OBJ2WRLD413 = objToWorld217;
				float3 objToWorld363 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 CenterPos62 = ( ase_positionWS - temp_output_58_0 );
				float3 OriginWorldPos408 = objToWorld363;
				float dotResult362 = dot( ( OBJ2WRLD413 - objToWorld363 ) , ( CenterPos62 - OriginWorldPos408 ) );
				float ShieldRadius446 = distance( ase_positionWS , OriginWorldPos408 );
				float temp_output_385_0 = ( acos( ( dotResult362 / ( ShieldRadius446 * ShieldRadius446 ) ) ) + _DissolveAmount );
				float clampResult400 = clamp( ( 0.92 + temp_output_385_0 ) , 0.0 , 1.0 );
				float VertOffsetFactor269 = ( 1.0 - clampResult400 );
				float3 WorldPos417 = CenterPos62;
				float3 OriginWorldPos417 = OriginWorldPos408;
				float ShieldRadius417 = ShieldRadius446;
				float3 TestPos417 = _TestPos;
				float HitWaveTest417 = _HitWaveTest;
				float localHitWave417 = HitWave417( WorldPos417 , OriginWorldPos417 , ShieldRadius417 , TestPos417 , HitWaveTest417 );
				float HitWave419 = localHitWave417;
				float3 worldToObjDir438 = ASESafeNormalize( mul( GetWorldToObjectMatrix(), float4( ase_normalWS, 0.0 ) ).xyz );
				float3 temp_output_423_0 = ( HitWave419 * 0.03 * 0.02 * worldToObjDir438 );
				float3 VertOffsset149 = ( ( worldToObjDir439 * _VertOffsetIntense * 0.01 * VertOffsetFactor269 ) + temp_output_423_0 );
				
				output.ase_texcoord1.xyz = ase_normalWS;
				output.ase_texcoord2.xyz = ase_positionWS;
				float4 ase_positionCS = TransformObjectToHClip( ( input.positionOS ).xyz );
				float4 screenPos = ComputeScreenPos( ase_positionCS );
				output.ase_texcoord3 = screenPos;
				
				output.ase_texcoord.xy = input.ase_texcoord.xy;
				output.ase_texcoord.zw = input.ase_texcoord1.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord1.w = 0;
				output.ase_texcoord2.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = VertOffsset149;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );

				output.positionCS = vertexInput.positionCS;
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.ase_texcoord = input.ase_texcoord;
				output.ase_texcoord1 = input.ase_texcoord1;
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				output.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			half4 frag(PackedVaryings input ) : SV_Target
			{
				SurfaceDescription surfaceDescription = (SurfaceDescription)0;

				float2 texCoord35 = input.ase_texcoord.xy * float2( 1,1 ) + float2( 0,0 );
				float4 tex2DNode34 = tex2D( _Line, texCoord35 );
				float2 texCoord29 = input.ase_texcoord.zw * float2( 1,1 ) + float2( 0,0 );
				float mulTime33 = _TimeParameters.x * 0.01;
				float smoothstepResult403 = smoothstep( 0.05 , 0.95 , tex2D( _Grid, ( texCoord29 + mulTime33 ) ).r);
				float3 ase_normalWS = input.ase_texcoord1.xyz;
				float3 ase_positionWS = input.ase_texcoord2.xyz;
				float3 ase_viewVectorWS = ( _WorldSpaceCameraPos.xyz - ase_positionWS );
				float3 ase_viewDirWS = normalize( ase_viewVectorWS );
				float dotResult15 = dot( ase_normalWS , ase_viewDirWS );
				float saferPower19 = abs( ( 1.0 - dotResult15 ) );
				float _RimSclae_Instance = UNITY_ACCESS_INSTANCED_PROP(Shield,_RimSclae);
				float clampResult17 = clamp( ( ( pow( saferPower19 , _RimPower ) * _RimSclae_Instance ) + _HoloBias ) , 0.0 , 1.0 );
				float HoloAlpha26 = clampResult17;
				float BasicAlpha49 = ( ( ( _LineIntensity * tex2DNode34.r ) + ( tex2DNode34.r * ( smoothstepResult403 * _FlowIntensity ) ) ) + HoloAlpha26 );
				float3 objToWorld217 = mul( GetObjectToWorldMatrix(), float4( ( _DissolvePos * 0.01 ), 1 ) ).xyz;
				float3 OBJ2WRLD413 = objToWorld217;
				float3 objToWorld363 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 objToWorld55 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 temp_output_3_0_g1 = ( ase_positionWS - objToWorld55 );
				float3 temp_output_6_0_g2 = ase_normalWS;
				float dotResult1_g2 = dot( temp_output_3_0_g1 , temp_output_6_0_g2 );
				float dotResult2_g2 = dot( temp_output_6_0_g2 , temp_output_6_0_g2 );
				float3 temp_output_58_0 = ( temp_output_3_0_g1 - ( ( dotResult1_g2 / dotResult2_g2 ) * temp_output_6_0_g2 ) );
				float3 CenterPos62 = ( ase_positionWS - temp_output_58_0 );
				float3 OriginWorldPos408 = objToWorld363;
				float dotResult362 = dot( ( OBJ2WRLD413 - objToWorld363 ) , ( CenterPos62 - OriginWorldPos408 ) );
				float ShieldRadius446 = distance( ase_positionWS , OriginWorldPos408 );
				float temp_output_385_0 = ( acos( ( dotResult362 / ( ShieldRadius446 * ShieldRadius446 ) ) ) + _DissolveAmount );
				float Dissolve91 = step( 0.01 , temp_output_385_0 );
				float DissolveRim351 = ( step( 0.1 , ( temp_output_385_0 + _DissolveRimWidth ) ) - Dissolve91 );
				float3 WorldPos498 = ase_positionWS;
				float3 OriginWorldPos498 = OriginWorldPos408;
				float ShieldRadius498 = ShieldRadius446;
				float3 TestPos498 = _TestPos;
				float HitRimTest498 = _HitRimTest;
				float Scale283 = _Scale;
				float simplePerlin3D500 = snoise( ( ase_positionWS * 5.0 * ( 1.0 / Scale283 ) ) );
				simplePerlin3D500 = simplePerlin3D500*0.5 + 0.5;
				float Noise498 = ( simplePerlin3D500 * -0.11 );
				float localHitWave498 = HitWave498( WorldPos498 , OriginWorldPos498 , ShieldRadius498 , TestPos498 , HitRimTest498 , Noise498 );
				float HitRim489 = localHitWave498;
				float3 WorldPos417 = CenterPos62;
				float3 OriginWorldPos417 = OriginWorldPos408;
				float ShieldRadius417 = ShieldRadius446;
				float3 TestPos417 = _TestPos;
				float HitWaveTest417 = _HitWaveTest;
				float localHitWave417 = HitWave417( WorldPos417 , OriginWorldPos417 , ShieldRadius417 , TestPos417 , HitWaveTest417 );
				float HitWave419 = localHitWave417;
				float clampResult523 = clamp(  (-1.0 + ( HitWave419 - 0.0 ) * ( 2.0 - -1.0 ) / ( 1.0 - 0.0 ) ) , 0.0 , 1.0 );
				float4 screenPos = input.ase_texcoord3;
				float4 ase_positionSSNorm = screenPos / screenPos.w;
				ase_positionSSNorm.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? ase_positionSSNorm.z : ase_positionSSNorm.z * 0.5 + 0.5;
				float screenDepth526 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ase_positionSSNorm.xy ),_ZBufferParams);
				float distanceDepth526 = ( screenDepth526 - LinearEyeDepth( ase_positionSSNorm.z,_ZBufferParams ) ) / ( _DepthFadeDistance );
				float clampResult536 = clamp( ( 1.0 - distanceDepth526 ) , 0.0 , 1.0 );
				float DepthFade529 = clampResult536;
				float clampResult147 = clamp( ( ( ( BasicAlpha49 * Dissolve91 ) + DissolveRim351 + ( ( HitRim489 * _HitRimIntense ) + ( _HitWaveIntense * clampResult523 ) ) ) + ( step( 0.001 , ( Dissolve91 * DepthFade529 ) ) * DepthFade529 ) ) , 0.0 , 1.0 );
				float FinalAlpha104 = clampResult147;
				

				surfaceDescription.Alpha = FinalAlpha104;
				surfaceDescription.AlphaClipThreshold = 0.0;

				#if _ALPHATEST_ON
					float alphaClipThreshold = 0.01f;
					#if ALPHA_CLIP_THRESHOLD
						alphaClipThreshold = surfaceDescription.AlphaClipThreshold;
					#endif
					clip(surfaceDescription.Alpha - alphaClipThreshold);
				#endif

				half4 outColor = 0;
				outColor = unity_SelectionID;

				return outColor;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthNormals"
			Tags { "LightMode"="DepthNormalsOnly" }

			ZTest LEqual
			ZWrite On

			HLSLPROGRAM

			

        	#pragma multi_compile_local _ALPHATEST_ON
        	#define _SURFACE_TYPE_TRANSPARENT 1
        	#define ASE_VERSION 19904
        	#define ASE_SRP_VERSION 140012
        	#define REQUIRE_DEPTH_TEXTURE 1


			

        	#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

			

			#pragma vertex vert
			#pragma fragment frag

			#define ATTRIBUTES_NEED_NORMAL
			#define ATTRIBUTES_NEED_TANGENT
			#define VARYINGS_NEED_NORMAL_WS

			#define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

			
            #if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#endif
		

			
			#if ASE_SRP_VERSION >=140007
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#endif
		

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"

			
			#if ASE_SRP_VERSION >=140010
			#include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
			#endif
		

			

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

            #if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_TEXTURE_COORDINATES0
			#define ASE_NEEDS_TEXTURE_COORDINATES1
			#define ASE_NEEDS_WORLD_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_NORMAL
			#define ASE_NEEDS_FRAG_SCREEN_POSITION_NORMALIZED
			#pragma multi_compile_instancing


			#if defined(ASE_EARLY_Z_DEPTH_OPTIMIZE) && (SHADER_TARGET >= 45)
				#define ASE_SV_DEPTH SV_DepthLessEqual
				#define ASE_SV_POSITION_QUALIFIERS linear noperspective centroid
			#else
				#define ASE_SV_DEPTH SV_Depth
				#define ASE_SV_POSITION_QUALIFIERS
			#endif

			struct Attributes
			{
				float4 positionOS : POSITION;
				half3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				ASE_SV_POSITION_QUALIFIERS float4 positionCS : SV_POSITION;
				half3 normalWS : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _MainColor;
			float3 _DissolvePos;
			float3 _TestPos;
			float _VertOffsetIntense;
			float _HitRimIntense;
			float _Scale;
			float _HitRimTest;
			float _DissolveRimWidth;
			float _HoloBias;
			float _FlowIntensity;
			float _HitWaveIntense;
			float _LineIntensity;
			float _MainColorintensity;
			float _HitWaveTest;
			float _DissolveAmount;
			float _RimPower;
			float _DepthFadeDistance;
			#ifdef ASE_TESSELLATION
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			float ParticleCrntSize[10];
			float ParticleFinalSize[10];
			float4 HitPos[10];
			sampler2D _Line;
			sampler2D _Grid;
			UNITY_INSTANCING_BUFFER_START(Shield)
				UNITY_DEFINE_INSTANCED_PROP(float, _RimSclae)
			UNITY_INSTANCING_BUFFER_END(Shield)


			float3 ASESafeNormalize(float3 inVec)
			{
				float dp3 = max(1.175494351e-38, dot(inVec, inVec));
				return inVec* rsqrt(dp3);
			}
			
			float HitWave417( float3 WorldPos, float3 OriginWorldPos, float ShieldRadius, float3 TestPos, float HitWaveTest )
			{
				float result = 0.0f;
				for(int j = 0; j < 10; j++)
				{	
					float fade = 1.0f - saturate(1.0f * ParticleCrntSize[j] / ParticleFinalSize[j]);
					float3 newR = normalize(HitPos[j].xyz - OriginWorldPos);
					//float3 newR = normalize(TestPos - OriginWorldPos);
					float3 newPos = OriginWorldPos + newR * ShieldRadius;
					float3 a = newPos - OriginWorldPos;
					float3 b = WorldPos - OriginWorldPos;
					float wave = dot(a, b) / (ShieldRadius * ShieldRadius);
					//wave = acos(wave) - HitWaveTest;
					wave = acos(wave) - ParticleCrntSize[j];
					float mask = 1.0f - step(0.001, wave);
					wave = distance(0, wave) * mask;
					wave = 1.0f - saturate(wave);
					wave *= mask;
					wave = smoothstep(0.3f, 1.05f, wave);	
					result += wave * fade;
					
				}
				return saturate(result);
			}
			
			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			
			float HitWave498( float3 WorldPos, float3 OriginWorldPos, float ShieldRadius, float3 TestPos, float HitRimTest, float Noise )
			{
				float result = 0.0f;
				for(int j = 0; j < 10; j++)
				{	
					float fade = 1.0f - saturate(1.0f * ParticleCrntSize[j] / ParticleFinalSize[j]);
					float3 newR = normalize(HitPos[j].xyz - OriginWorldPos);
					//float3 newR = normalize(TestPos - OriginWorldPos);
					float3 newPos = OriginWorldPos + newR * ShieldRadius;
					float3 a = newPos - OriginWorldPos;
					float3 b = WorldPos - OriginWorldPos;
					float rim = dot(a, b) / (ShieldRadius * ShieldRadius);
					//rim = acos(rim) - HitRimTest;
					rim = acos(rim) - ParticleCrntSize[j];
					float mask = 1.0f - step(0.001, rim);
					rim = distance(Noise, rim) * mask;
					rim = 1.0f - saturate(rim);
					rim *= mask;
					rim = smoothstep(0.95f, 1.1f, rim);	
					result += rim * fade;
				}
				return saturate(result);
			}
			

			struct SurfaceDescription
			{
				float Alpha;
				float AlphaClipThreshold;
			};

			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output;
				ZERO_INITIALIZE(PackedVaryings, output);

				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float3 ase_positionWS = TransformObjectToWorld( ( input.positionOS ).xyz );
				float3 objToWorld55 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 temp_output_3_0_g1 = ( ase_positionWS - objToWorld55 );
				float3 ase_normalWS = TransformObjectToWorldNormal( input.normalOS );
				float3 temp_output_6_0_g2 = ase_normalWS;
				float dotResult1_g2 = dot( temp_output_3_0_g1 , temp_output_6_0_g2 );
				float dotResult2_g2 = dot( temp_output_6_0_g2 , temp_output_6_0_g2 );
				float3 temp_output_58_0 = ( temp_output_3_0_g1 - ( ( dotResult1_g2 / dotResult2_g2 ) * temp_output_6_0_g2 ) );
				float3 Point2CenterDir69 = -temp_output_58_0;
				float3 worldToObjDir439 = ASESafeNormalize( mul( GetWorldToObjectMatrix(), float4( Point2CenterDir69, 0.0 ) ).xyz );
				float3 objToWorld217 = mul( GetObjectToWorldMatrix(), float4( ( _DissolvePos * 0.01 ), 1 ) ).xyz;
				float3 OBJ2WRLD413 = objToWorld217;
				float3 objToWorld363 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 CenterPos62 = ( ase_positionWS - temp_output_58_0 );
				float3 OriginWorldPos408 = objToWorld363;
				float dotResult362 = dot( ( OBJ2WRLD413 - objToWorld363 ) , ( CenterPos62 - OriginWorldPos408 ) );
				float ShieldRadius446 = distance( ase_positionWS , OriginWorldPos408 );
				float temp_output_385_0 = ( acos( ( dotResult362 / ( ShieldRadius446 * ShieldRadius446 ) ) ) + _DissolveAmount );
				float clampResult400 = clamp( ( 0.92 + temp_output_385_0 ) , 0.0 , 1.0 );
				float VertOffsetFactor269 = ( 1.0 - clampResult400 );
				float3 WorldPos417 = CenterPos62;
				float3 OriginWorldPos417 = OriginWorldPos408;
				float ShieldRadius417 = ShieldRadius446;
				float3 TestPos417 = _TestPos;
				float HitWaveTest417 = _HitWaveTest;
				float localHitWave417 = HitWave417( WorldPos417 , OriginWorldPos417 , ShieldRadius417 , TestPos417 , HitWaveTest417 );
				float HitWave419 = localHitWave417;
				float3 worldToObjDir438 = ASESafeNormalize( mul( GetWorldToObjectMatrix(), float4( ase_normalWS, 0.0 ) ).xyz );
				float3 temp_output_423_0 = ( HitWave419 * 0.03 * 0.02 * worldToObjDir438 );
				float3 VertOffsset149 = ( ( worldToObjDir439 * _VertOffsetIntense * 0.01 * VertOffsetFactor269 ) + temp_output_423_0 );
				
				output.ase_texcoord2.xyz = ase_positionWS;
				
				output.ase_texcoord1.xy = input.ase_texcoord.xy;
				output.ase_texcoord1.zw = input.ase_texcoord1.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord2.w = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = VertOffsset149;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );
				VertexNormalInputs normalInput = GetVertexNormalInputs( input.normalOS );

				output.positionCS = vertexInput.positionCS;
				output.normalWS = normalInput.normalWS;
				return output;
			}

			#if defined(ASE_TESSELLATION)
			struct VertexControl
			{
				float4 positionOS : INTERNALTESSPOS;
				half3 normalOS : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( Attributes input )
			{
				VertexControl output;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				output.positionOS = input.positionOS;
				output.normalOS = input.normalOS;
				output.ase_texcoord = input.ase_texcoord;
				output.ase_texcoord1 = input.ase_texcoord1;
				return output;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> input)
			{
				TessellationFactors output;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(input[0].positionOS, input[1].positionOS, input[2].positionOS, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				output.edge[0] = tf.x; output.edge[1] = tf.y; output.edge[2] = tf.z; output.inside = tf.w;
				return output;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
				return patch[id];
			}

			[domain("tri")]
			PackedVaryings DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				Attributes output = (Attributes) 0;
				output.positionOS = patch[0].positionOS * bary.x + patch[1].positionOS * bary.y + patch[2].positionOS * bary.z;
				output.normalOS = patch[0].normalOS * bary.x + patch[1].normalOS * bary.y + patch[2].normalOS * bary.z;
				output.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				output.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = output.positionOS.xyz - patch[i].normalOS * (dot(output.positionOS.xyz, patch[i].normalOS) - dot(patch[i].positionOS.xyz, patch[i].normalOS));
				float phongStrength = _TessPhongStrength;
				output.positionOS.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * output.positionOS.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], output);
				return VertexFunction(output);
			}
			#else
			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}
			#endif

			void frag(PackedVaryings input
						, out half4 outNormalWS : SV_Target0
						#if defined( ASE_DEPTH_WRITE_ON )
						,out float outputDepth : ASE_SV_DEPTH
						#endif
						#ifdef _WRITE_RENDERING_LAYERS
						, out float4 outRenderingLayers : SV_Target1
						#endif
						 )
			{
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( input );

				half3 NormalWS = normalize( input.normalWS );
				float4 ScreenPosNorm = float4( GetNormalizedScreenSpaceUV( input.positionCS ), input.positionCS.zw );
				float4 ClipPos = ComputeClipSpacePosition( ScreenPosNorm.xy, input.positionCS.z ) * input.positionCS.w;
				float4 ScreenPos = ComputeScreenPos( ClipPos );

				float2 texCoord35 = input.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float4 tex2DNode34 = tex2D( _Line, texCoord35 );
				float2 texCoord29 = input.ase_texcoord1.zw * float2( 1,1 ) + float2( 0,0 );
				float mulTime33 = _TimeParameters.x * 0.01;
				float smoothstepResult403 = smoothstep( 0.05 , 0.95 , tex2D( _Grid, ( texCoord29 + mulTime33 ) ).r);
				float3 ase_positionWS = input.ase_texcoord2.xyz;
				float3 ase_viewVectorWS = ( _WorldSpaceCameraPos.xyz - ase_positionWS );
				float3 ase_viewDirWS = normalize( ase_viewVectorWS );
				float dotResult15 = dot( NormalWS , ase_viewDirWS );
				float saferPower19 = abs( ( 1.0 - dotResult15 ) );
				float _RimSclae_Instance = UNITY_ACCESS_INSTANCED_PROP(Shield,_RimSclae);
				float clampResult17 = clamp( ( ( pow( saferPower19 , _RimPower ) * _RimSclae_Instance ) + _HoloBias ) , 0.0 , 1.0 );
				float HoloAlpha26 = clampResult17;
				float BasicAlpha49 = ( ( ( _LineIntensity * tex2DNode34.r ) + ( tex2DNode34.r * ( smoothstepResult403 * _FlowIntensity ) ) ) + HoloAlpha26 );
				float3 objToWorld217 = mul( GetObjectToWorldMatrix(), float4( ( _DissolvePos * 0.01 ), 1 ) ).xyz;
				float3 OBJ2WRLD413 = objToWorld217;
				float3 objToWorld363 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 objToWorld55 = mul( GetObjectToWorldMatrix(), float4( float3( 0,0,0 ), 1 ) ).xyz;
				float3 temp_output_3_0_g1 = ( ase_positionWS - objToWorld55 );
				float3 temp_output_6_0_g2 = NormalWS;
				float dotResult1_g2 = dot( temp_output_3_0_g1 , temp_output_6_0_g2 );
				float dotResult2_g2 = dot( temp_output_6_0_g2 , temp_output_6_0_g2 );
				float3 temp_output_58_0 = ( temp_output_3_0_g1 - ( ( dotResult1_g2 / dotResult2_g2 ) * temp_output_6_0_g2 ) );
				float3 CenterPos62 = ( ase_positionWS - temp_output_58_0 );
				float3 OriginWorldPos408 = objToWorld363;
				float dotResult362 = dot( ( OBJ2WRLD413 - objToWorld363 ) , ( CenterPos62 - OriginWorldPos408 ) );
				float ShieldRadius446 = distance( ase_positionWS , OriginWorldPos408 );
				float temp_output_385_0 = ( acos( ( dotResult362 / ( ShieldRadius446 * ShieldRadius446 ) ) ) + _DissolveAmount );
				float Dissolve91 = step( 0.01 , temp_output_385_0 );
				float DissolveRim351 = ( step( 0.1 , ( temp_output_385_0 + _DissolveRimWidth ) ) - Dissolve91 );
				float3 WorldPos498 = ase_positionWS;
				float3 OriginWorldPos498 = OriginWorldPos408;
				float ShieldRadius498 = ShieldRadius446;
				float3 TestPos498 = _TestPos;
				float HitRimTest498 = _HitRimTest;
				float Scale283 = _Scale;
				float simplePerlin3D500 = snoise( ( ase_positionWS * 5.0 * ( 1.0 / Scale283 ) ) );
				simplePerlin3D500 = simplePerlin3D500*0.5 + 0.5;
				float Noise498 = ( simplePerlin3D500 * -0.11 );
				float localHitWave498 = HitWave498( WorldPos498 , OriginWorldPos498 , ShieldRadius498 , TestPos498 , HitRimTest498 , Noise498 );
				float HitRim489 = localHitWave498;
				float3 WorldPos417 = CenterPos62;
				float3 OriginWorldPos417 = OriginWorldPos408;
				float ShieldRadius417 = ShieldRadius446;
				float3 TestPos417 = _TestPos;
				float HitWaveTest417 = _HitWaveTest;
				float localHitWave417 = HitWave417( WorldPos417 , OriginWorldPos417 , ShieldRadius417 , TestPos417 , HitWaveTest417 );
				float HitWave419 = localHitWave417;
				float clampResult523 = clamp(  (-1.0 + ( HitWave419 - 0.0 ) * ( 2.0 - -1.0 ) / ( 1.0 - 0.0 ) ) , 0.0 , 1.0 );
				float screenDepth526 = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH( ScreenPosNorm.xy ),_ZBufferParams);
				float distanceDepth526 = ( screenDepth526 - LinearEyeDepth( ScreenPosNorm.z,_ZBufferParams ) ) / ( _DepthFadeDistance );
				float clampResult536 = clamp( ( 1.0 - distanceDepth526 ) , 0.0 , 1.0 );
				float DepthFade529 = clampResult536;
				float clampResult147 = clamp( ( ( ( BasicAlpha49 * Dissolve91 ) + DissolveRim351 + ( ( HitRim489 * _HitRimIntense ) + ( _HitWaveIntense * clampResult523 ) ) ) + ( step( 0.001 , ( Dissolve91 * DepthFade529 ) ) * DepthFade529 ) ) , 0.0 , 1.0 );
				float FinalAlpha104 = clampResult147;
				

				float Alpha = FinalAlpha104;
				float AlphaClipThreshold = 0.0;

				#if defined( ASE_DEPTH_WRITE_ON )
					float DeviceDepth = input.positionCS.z;
				#endif

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#if defined(LOD_FADE_CROSSFADE)
					LODFadeCrossFade( input.positionCS );
				#endif

				#if defined( ASE_DEPTH_WRITE_ON )
					outputDepth = DeviceDepth;
				#endif

				#if defined(_GBUFFER_NORMALS_OCT)
					float2 octNormalWS = PackNormalOctQuadEncode(NormalWS);
					float2 remappedOctNormalWS = saturate(octNormalWS * 0.5 + 0.5);
					half3 packedNormalWS = PackFloat2To888(remappedOctNormalWS);
					outNormalWS = half4(packedNormalWS, 0.0);
				#else
					outNormalWS = half4(NormalizeNormalPerPixel( NormalWS ), 0.0);
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4(EncodeMeshRenderingLayer(renderingLayers), 0, 0, 0);
				#endif
			}
			ENDHLSL
		}

	
	}
	
	CustomEditor "UnityEditor.ShaderGraphUnlitGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback "Hidden/InternalErrorShader"
}
/*ASEBEGIN
Version=19904
Node;AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;63;-2440.854,861.4459;Inherit;False;2095.354;876.9376;Comment;10;69;106;62;61;60;58;59;57;55;56;Point2Center;1,1,1,1;0;0
Node;AmplifyShaderEditor.TransformPositionNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;55;-2231.489,1329.923;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldPosInputsNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;56;-2221.454,1094.981;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;89;976,-2304;Inherit;False;3278.634;1394.758;d = R*theta;41;386;447;316;351;391;91;387;392;390;388;389;269;397;400;394;395;385;93;361;381;362;384;446;443;444;445;408;413;364;219;217;363;243;216;245;449;262;102;393;287;396;Dissolve;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldNormalVector, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;59;-1814.361,1439.517;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;57;-1850.776,1236.903;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;28;-48,-448;Inherit;False;2615.788;665.9414;Comment;12;26;17;21;20;22;19;23;24;25;15;14;16;HoloAlpha;1,1,1,1;0;0
Node;AmplifyShaderEditor.WorldPosInputsNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;60;-1492.673,1051.4;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;245;1072,-1840;Inherit;False;Constant;_Float3;Float 3;13;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;216;1072,-2016;Inherit;False;Property;_DissolvePos;DissolvePos;17;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FunctionNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;58;-1473.561,1250.908;Inherit;False;Rejection;-1;;1;ea6ca936e02c9e74fae837451ff893c3;0;2;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;480;-3574.421,2144;Inherit;False;3335.328;1889.425;Comment;27;504;498;489;283;282;281;280;414;276;503;500;494;499;497;493;419;417;437;448;441;164;436;512;514;513;515;516;HitWave;1,1,1,1;0;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;16;112,-96;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;14;96,-320;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;444;1200,-1184;Inherit;False;408;OriginWorldPos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldPosInputsNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;449;1248,-1392;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;61;-1179.695,1219.485;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;243;1312,-1968;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DotProductOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;15;384,-240;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;276;-2624,2608;Inherit;False;Property;_Scale;Scale;16;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;47;-2923.55,-2390.164;Inherit;False;3398.361;1452.541;Comment;21;270;137;271;27;49;36;38;44;543;45;39;34;46;43;403;35;30;31;33;29;550;Basic Color&Alpha;1,1,1,1;0;0
Node;AmplifyShaderEditor.DistanceOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;443;1472,-1264;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;62;-812.4429,1222.399;Inherit;False;CenterPos;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformPositionNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;217;1488,-1968;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;24;800,-48;Inherit;False;Property;_RimPower;RimPower;4;0;Create;True;0;0;0;False;0;False;3;1.8;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;25;720,-240;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;283;-2432,2608;Inherit;False;Scale;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleTimeNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;33;-2720,-1648;Inherit;False;1;0;FLOAT;0.01;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;29;-2896,-1776;Inherit;False;1;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TransformPositionNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;363;1168,-1696;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;446;1648,-1264;Inherit;False;ShieldRadius;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;408;1568,-1648;Inherit;False;OriginWorldPos;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;413;1728,-1968;Inherit;False;OBJ2WRLD;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;219;1600,-1728;Inherit;False;62;CenterPos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;23;1088,-48;Inherit;False;InstancedProperty;_RimSclae;RimSclae;5;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;19;1008,-240;Inherit;False;True;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;515;-3264,3504;Inherit;False;283;Scale;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;31;-2429.751,-1710.985;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TexturePropertyNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;550;-2512,-1584;Inherit;True;Property;_Grid;Grid;19;0;Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;False;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;386;1808,-1728;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;364;1968,-1968;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;447;2064,-1680;Inherit;False;446;ShieldRadius;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;532;1408,2512;Inherit;False;1374.235;362.9006;Comment;5;529;531;526;527;536;DepthFade;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;22;1328,0;Inherit;False;Property;_HoloBias;HoloBias;3;0;Create;True;0;0;0;False;0;False;0;0.041;0;0.3;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;20;1344,-192;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldPosInputsNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;512;-3200,3120;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;516;-3056,3408;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;514;-3184,3296;Inherit;False;Constant;_5;5;20;0;Create;True;0;0;0;False;0;False;5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;30;-2208,-1664;Inherit;True;Property;_TextureSample1;Texture Sample 1;12;0;Create;True;0;0;0;False;0;False;-1;fe85fc2913584bb418451375ea3eabb5;fe85fc2913584bb418451375ea3eabb5;True;0;False;white;Auto;False;Instance;-1;Auto;Texture2D;False;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;384;2352,-1696;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;362;2352,-1872;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;164;-2144,2208;Inherit;False;62;CenterPos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;441;-2176,2320;Inherit;False;408;OriginWorldPos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;448;-2176,2432;Inherit;False;446;ShieldRadius;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;437;-2160,2688;Inherit;False;Property;_HitWaveTest;HitWaveTest;14;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;513;-2928,3184;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;527;1456,2640;Inherit;False;Property;_DepthFadeDistance;DepthFadeDistance;11;0;Create;True;0;0;0;False;0;False;0.6;0;0;0.6;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;35;-2370.531,-1956.561;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;21;1632,-176;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;403;-1888,-1680;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.05;False;2;FLOAT;0.95;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;43;-1696,-1488;Inherit;False;Property;_FlowIntensity;FlowIntensity;6;0;Create;True;0;0;0;False;0;False;1;30;0;40;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;381;2544,-1872;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;417;-1824,2384;Inherit;False;float result = 0.0f@$for(int j = 0@ j < 10@ j++)${	$	float fade = 1.0f - saturate(1.0f * ParticleCrntSize[j] / ParticleFinalSize[j])@$	float3 newR = normalize(HitPos[j].xyz - OriginWorldPos)@$	//float3 newR = normalize(TestPos - OriginWorldPos)@$	float3 newPos = OriginWorldPos + newR * ShieldRadius@$	float3 a = newPos - OriginWorldPos@$	float3 b = WorldPos - OriginWorldPos@$	float wave = dot(a, b) / (ShieldRadius * ShieldRadius)@$	//wave = acos(wave) - HitWaveTest@$	wave = acos(wave) - ParticleCrntSize[j]@$	float mask = 1.0f - step(0.001, wave)@$	wave = distance(0, wave) * mask@$	wave = 1.0f - saturate(wave)@$	wave *= mask@$	wave = smoothstep(0.3f, 1.05f, wave)@	$	result += wave * fade@$	$}$$return saturate(result)@;1;Create;5;True;WorldPos;FLOAT3;0,0,0;In;;Inherit;False;True;OriginWorldPos;FLOAT3;0,0,0;In;;Inherit;False;True;ShieldRadius;FLOAT;0;In;;Inherit;False;True;TestPos;FLOAT3;0,0,0;In;;Inherit;False;True;HitWaveTest;FLOAT;0;In;;Inherit;False;HitWave;True;False;0;;False;5;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;17;1904,-176;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;46;-1923.566,-2134.908;Inherit;False;Property;_LineIntensity;LineIntensity;7;0;Create;True;0;0;0;False;0;False;0.3090088;0.392;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;34;-2097.754,-1976.23;Inherit;True;Property;_Line;Line;12;0;Create;True;0;0;0;False;0;False;-1;None;c5e18ddc7af71894e875b9335e1c80f8;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;False;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;504;-2464,3264;Inherit;False;Constant;_011;-0.11;20;0;Create;True;0;0;0;False;0;False;-0.11;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DepthFade, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;526;1744,2592;Inherit;False;True;False;False;2;1;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;39;-1376,-1680;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NoiseGeneratorNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;500;-2688,3184;Inherit;True;Simplex3D;True;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ACosOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;361;2784,-1872;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;93;2768,-1760;Inherit;False;Property;_DissolveAmount;DissolveAmount;1;0;Create;True;0;0;0;False;0;False;-0.37;57;-3;-0.37;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;436;-2160,2528;Inherit;False;Property;_TestPos;TestPos;13;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;419;-1216,2400;Inherit;False;HitWave;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;105;306.0753,731.1262;Inherit;False;2860.288;1094.735;Comment;22;539;538;540;537;104;147;530;153;520;141;100;519;505;99;101;490;506;523;521;522;518;541;FinalAlpha;1,1,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;26;2256,-80;Inherit;False;HoloAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;45;-1420.058,-2008.29;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;493;-2208,3040;Inherit;False;408;OriginWorldPos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldPosInputsNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;497;-2208,2880;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;499;-2192,3456;Inherit;False;Property;_HitRimTest;HitRimTest;15;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;494;-2224,3312;Inherit;False;446;ShieldRadius;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;503;-2208,3168;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;531;2176,2608;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;389;3088,-1552;Inherit;False;Property;_DissolveRimWidth;DissolveRimWidth;18;0;Create;True;0;0;0;False;0;False;0.32;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;543;-1264,-1824;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;385;3088,-1872;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;395;3008,-2032;Inherit;False;Constant;_VertOffsetOffset;VertOffsetOffset;9;0;Create;True;0;0;0;False;0;False;0.92;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;44;-1045.145,-1909.83;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;38;-963.0797,-1746.155;Inherit;False;26;HoloAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;388;3328,-1696;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;518;320,1536;Inherit;False;419;HitWave;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;498;-1824,2992;Inherit;False;float result = 0.0f@$for(int j = 0@ j < 10@ j++)${	$	float fade = 1.0f - saturate(1.0f * ParticleCrntSize[j] / ParticleFinalSize[j])@$	float3 newR = normalize(HitPos[j].xyz - OriginWorldPos)@$	//float3 newR = normalize(TestPos - OriginWorldPos)@$	float3 newPos = OriginWorldPos + newR * ShieldRadius@$	float3 a = newPos - OriginWorldPos@$	float3 b = WorldPos - OriginWorldPos@$	float rim = dot(a, b) / (ShieldRadius * ShieldRadius)@$	//rim = acos(rim) - HitRimTest@$	rim = acos(rim) - ParticleCrntSize[j]@$	float mask = 1.0f - step(0.001, rim)@$	rim = distance(Noise, rim) * mask@$	rim = 1.0f - saturate(rim)@$	rim *= mask@$	rim = smoothstep(0.95f, 1.1f, rim)@	$	result += rim * fade@$}$$return saturate(result)@;1;Create;6;True;WorldPos;FLOAT3;0,0,0;In;;Inherit;False;True;OriginWorldPos;FLOAT3;0,0,0;In;;Inherit;False;True;ShieldRadius;FLOAT;0;In;;Inherit;False;True;TestPos;FLOAT3;0,0,0;In;;Inherit;False;True;HitRimTest;FLOAT;0;In;;Inherit;False;True;Noise;FLOAT;0;In;;Inherit;False;HitWave;True;False;0;;False;6;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;5;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;536;2368,2672;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;394;3312,-2032;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;36;-741.14,-1903.184;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;390;3504,-1712;Inherit;False;2;0;FLOAT;0.1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;392;3424,-1536;Inherit;False;91;Dissolve;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;387;3344,-1888;Inherit;False;2;0;FLOAT;0.01;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;489;-1136,2992;Inherit;False;HitRim;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TFHCRemapNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;522;576,1536;Inherit;False;5;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;-1;False;4;FLOAT;2;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;529;2528,2640;Inherit;False;DepthFade;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NegateNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;106;-1227.575,1383.958;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;400;3472,-2032;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;49;-320,-1888;Inherit;False;BasicAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;91;3536,-1888;Inherit;False;Dissolve;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;391;3680,-1648;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;521;320,1456;Inherit;False;Property;_HitWaveIntense;HitWaveIntense;10;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;523;832,1536;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;506;832,1264;Inherit;False;Property;_HitRimIntense;HitRimIntense;9;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;490;816,1168;Inherit;False;489;HitRim;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;530;1424,1248;Inherit;False;529;DepthFade;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;541;1408,1136;Inherit;False;91;Dissolve;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;150;-2449.315,-786.7852;Inherit;False;1370.169;1131.691;Comment;15;517;149;425;108;423;109;110;439;119;438;427;426;422;107;424;VertOffset;1,1,1,1;0;0
Node;AmplifyShaderEditor.OneMinusNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;397;3664,-2032;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;69;-976,1392;Inherit;False;Point2CenterDir;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;351;3856,-1648;Inherit;False;DissolveRim;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;101;554.6394,1016.27;Inherit;False;91;Dissolve;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;99;550.4891,868.4131;Inherit;False;49;BasicAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;505;1056,1168;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;519;1056,1472;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;537;1648,1168;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;424;-2176,96;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;107;-2308,-656;Inherit;False;69;Point2CenterDir;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;269;3888,-2032;Inherit;False;VertOffsetFactor;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;100;816,928;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;141;1088,992;Inherit;False;351;DissolveRim;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;520;1248,1152;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;538;1824,1168;Inherit;False;2;0;FLOAT;0.001;False;1;FLOAT;0.001;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;422;-2096,-224;Inherit;False;419;HitWave;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;438;-1904,96;Inherit;False;World;Object;True;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;110;-2080,-432;Inherit;False;Constant;_Float0;Float 0;10;0;Create;True;0;0;0;False;0;False;0.01;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;109;-2064,-512;Inherit;False;Property;_VertOffsetIntense;VertOffsetIntense;8;0;Create;True;0;0;0;False;0;False;0.12;0.39;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;153;1456,944;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;540;1952,1232;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;119;-2064,-336;Inherit;False;269;VertOffsetFactor;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;439;-2064,-672;Inherit;False;World;Object;True;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;427;-2080,32;Inherit;False;Constant;_Float7;Float 7;18;0;Create;True;0;0;0;False;0;False;0.02;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;426;-2080,-48;Inherit;False;Constant;_Float6;Float 6;18;0;Create;True;0;0;0;False;0;False;0.03;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;423;-1600,-160;Inherit;False;4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;108;-1728.184,-546.3622;Inherit;False;4;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;539;2144,992;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;425;-1488,-416;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ClampOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;147;2384,1024;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;149;-1312,-416;Inherit;False;VertOffsset;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;104;2624,976;Inherit;False;FinalAlpha;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;27;-944,-2256;Inherit;False;Property;_MainColor;MainColor;0;1;[HDR];Create;True;0;0;0;False;0;False;0,0,0,0;2.996078,0.925589,0,0.4588235;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;271;-928,-2016;Inherit;False;Property;_MainColorintensity;MainColorintensity;2;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;137;-400,-2160;Inherit;False;MainColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;270;-624,-2160;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;253;4480,544;Inherit;False;Constant;_Float5;Float 5;16;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;158;4480,656;Inherit;False;149;VertOffsset;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;316;3088,-1664;Inherit;False;DissolveAmount;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;445;1088,-1504;Inherit;False;413;OBJ2WRLD;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GlobalArrayNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;280;-2944,2400;Inherit;False;ParticleCrntSize;0;10;0;False;False;0;1;True;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;281;-2944,2512;Inherit;False;ParticleFinalSize;0;10;0;False;False;0;1;True;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GlobalArrayNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;282;-2944,2640;Inherit;False;HitPos;0;10;2;False;False;0;1;True;Object;-1;4;0;INT;0;False;2;INT;0;False;1;INT;0;False;3;INT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;414;-2512,2816;Inherit;False;413;OBJ2WRLD;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;517;-1355.805,-87.35617;Inherit;False;HitVertOffset;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;103;4480,432;Inherit;False;104;FinalAlpha;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;262;3280,-1168;Inherit;False;91;Dissolve;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;102;3296,-1280;Inherit;False;351;DissolveRim;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;393;3248,-1040;Inherit;False;269;VertOffsetFactor;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;287;3712,-1184;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;396;3504,-1264;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.3;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;542;3930.044,-1159.374;Inherit;False;myVarName;-1;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.GetLocalVarNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;249;4480,304;Inherit;False;137;MainColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;12;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;11;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;13;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;9;4928,816;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;True;True;1;0;False;;1;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;10;5008,448;Float;False;True;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;13;Shield;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;9;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Transparent=RenderType;Queue=Transparent=Queue=0;UniversalMaterialType=Unlit;True;7;True;12;all;0;False;True;2;5;False;;10;False;;1;1;False;;10;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;255;False;;255;False;;255;False;;7;False;;1;False;;1;False;;1;False;;7;False;;1;False;;1;False;;1;False;;False;True;2;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;27;Surface;1;638968194869914225;  Keep Alpha;0;0;  Blend;0;638967881214924220;Two Sided;1;0;Alpha Clipping;1;0;  Use Shadow Threshold;0;0;Forward Only;0;0;Cast Shadows;1;0;Receive Shadows;1;0;Receive SSAO;1;0;GPU Instancing;1;0;LOD CrossFade;0;0;Built-in Fog;0;0;Meta Pass;0;0;Extra Pre Pass;1;0;Tessellation;0;0;  Phong;0;0;  Strength;0.5,False,;0;  Type;0;0;  Tess;16,False,;0;  Min;10,False,;0;  Max;25,False,;0;  Edge Length;16,False,;0;  Max Displacement;25,False,;0;Write Depth;0;0;  Early Z;0;0;Vertex Position;1;0;0;10;True;True;True;True;False;False;True;True;True;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;194;4335.642,-42.16734;Float;False;False;-1;3;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;195;4335.642,-42.16734;Float;False;False;-1;3;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;SceneSelectionPass;0;6;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;196;4335.642,-42.16734;Float;False;False;-1;3;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ScenePickingPass;0;7;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;197;4335.642,-42.16734;Float;False;False;-1;3;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormals;0;8;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode, AmplifyShaderEditor, Version=0.0.0.0, Culture=neutral, PublicKeyToken=null;198;4335.642,-42.16734;Float;False;False;-1;3;UnityEditor.ShaderGraphUnlitGUI;0;13;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthNormalsOnly;0;9;DepthNormalsOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;True;9;d3d11;metal;vulkan;xboxone;xboxseries;playstation;ps4;ps5;switch;0;;0;0;Standard;0;False;0
WireConnection;57;0;56;0
WireConnection;57;1;55;0
WireConnection;58;3;57;0
WireConnection;58;4;59;0
WireConnection;61;0;60;0
WireConnection;61;1;58;0
WireConnection;243;0;216;0
WireConnection;243;1;245;0
WireConnection;15;0;14;0
WireConnection;15;1;16;0
WireConnection;443;0;449;0
WireConnection;443;1;444;0
WireConnection;62;0;61;0
WireConnection;217;0;243;0
WireConnection;25;0;15;0
WireConnection;283;0;276;0
WireConnection;446;0;443;0
WireConnection;408;0;363;0
WireConnection;413;0;217;0
WireConnection;19;0;25;0
WireConnection;19;1;24;0
WireConnection;31;0;29;0
WireConnection;31;1;33;0
WireConnection;386;0;219;0
WireConnection;386;1;408;0
WireConnection;364;0;413;0
WireConnection;364;1;363;0
WireConnection;20;0;19;0
WireConnection;20;1;23;0
WireConnection;516;1;515;0
WireConnection;30;0;550;0
WireConnection;30;1;31;0
WireConnection;384;0;447;0
WireConnection;384;1;447;0
WireConnection;362;0;364;0
WireConnection;362;1;386;0
WireConnection;513;0;512;0
WireConnection;513;1;514;0
WireConnection;513;2;516;0
WireConnection;21;0;20;0
WireConnection;21;1;22;0
WireConnection;403;0;30;1
WireConnection;381;0;362;0
WireConnection;381;1;384;0
WireConnection;417;0;164;0
WireConnection;417;1;441;0
WireConnection;417;2;448;0
WireConnection;417;3;436;0
WireConnection;417;4;437;0
WireConnection;17;0;21;0
WireConnection;34;1;35;0
WireConnection;526;0;527;0
WireConnection;39;0;403;0
WireConnection;39;1;43;0
WireConnection;500;0;513;0
WireConnection;361;0;381;0
WireConnection;419;0;417;0
WireConnection;26;0;17;0
WireConnection;45;0;46;0
WireConnection;45;1;34;1
WireConnection;503;0;500;0
WireConnection;503;1;504;0
WireConnection;531;0;526;0
WireConnection;543;0;34;1
WireConnection;543;1;39;0
WireConnection;385;0;361;0
WireConnection;385;1;93;0
WireConnection;44;0;45;0
WireConnection;44;1;543;0
WireConnection;388;0;385;0
WireConnection;388;1;389;0
WireConnection;498;0;497;0
WireConnection;498;1;493;0
WireConnection;498;2;494;0
WireConnection;498;3;436;0
WireConnection;498;4;499;0
WireConnection;498;5;503;0
WireConnection;536;0;531;0
WireConnection;394;0;395;0
WireConnection;394;1;385;0
WireConnection;36;0;44;0
WireConnection;36;1;38;0
WireConnection;390;1;388;0
WireConnection;387;1;385;0
WireConnection;489;0;498;0
WireConnection;522;0;518;0
WireConnection;529;0;536;0
WireConnection;106;0;58;0
WireConnection;400;0;394;0
WireConnection;49;0;36;0
WireConnection;91;0;387;0
WireConnection;391;0;390;0
WireConnection;391;1;392;0
WireConnection;523;0;522;0
WireConnection;397;0;400;0
WireConnection;69;0;106;0
WireConnection;351;0;391;0
WireConnection;505;0;490;0
WireConnection;505;1;506;0
WireConnection;519;0;521;0
WireConnection;519;1;523;0
WireConnection;537;0;541;0
WireConnection;537;1;530;0
WireConnection;269;0;397;0
WireConnection;100;0;99;0
WireConnection;100;1;101;0
WireConnection;520;0;505;0
WireConnection;520;1;519;0
WireConnection;538;1;537;0
WireConnection;438;0;424;0
WireConnection;153;0;100;0
WireConnection;153;1;141;0
WireConnection;153;2;520;0
WireConnection;540;0;538;0
WireConnection;540;1;530;0
WireConnection;439;0;107;0
WireConnection;423;0;422;0
WireConnection;423;1;426;0
WireConnection;423;2;427;0
WireConnection;423;3;438;0
WireConnection;108;0;439;0
WireConnection;108;1;109;0
WireConnection;108;2;110;0
WireConnection;108;3;119;0
WireConnection;539;0;153;0
WireConnection;539;1;540;0
WireConnection;425;0;108;0
WireConnection;425;1;423;0
WireConnection;147;0;539;0
WireConnection;149;0;425;0
WireConnection;104;0;147;0
WireConnection;137;0;270;0
WireConnection;270;0;27;0
WireConnection;270;1;271;0
WireConnection;316;0;93;0
WireConnection;517;0;423;0
WireConnection;287;0;396;0
WireConnection;287;1;262;0
WireConnection;287;2;393;0
WireConnection;396;0;102;0
WireConnection;542;0;287;0
WireConnection;9;2;253;0
WireConnection;9;3;158;0
WireConnection;10;2;249;0
WireConnection;10;3;103;0
WireConnection;10;4;253;0
WireConnection;10;5;158;0
ASEEND*/
//CHKSM=187D95FF0BBF0956F391496E653868B7591235CD