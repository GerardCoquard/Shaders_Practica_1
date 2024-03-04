Shader "Tecnocampus/WaterShader"
{
	Properties
	{
		[Header(TEXTURES)]
		_MainTex("Main Texture", 2D) = "defaulttexture"{}
		_WaterDepthTex("_WaterDepthTex", 2D) = "defaulttexture"{}
		_FoamTex("_FoamTex", 2D) = "defaulttexture"{}
		_NoiseTex("_NoiseTexture", 2D) = "defaulttexture"{}
		_WaterHeightmapTex("_WaterHeightmapTex", 2D) = "defaulttexture"{}
		[Header(COLOR)]
		_DeepWaterColor("Deep Water Color", Color) = (1, 1, 1, 1)
		_WaterColor("Water Color", Color) = (1, 1, 1, 1)
		[Header(WATER)]
		_SpeedWater1("_SpeedWater1", Float) = 0.05
		[ShowAsVector2] _DirectionWater1("_DirectionWater1", Vector) = (0.3, -0.1, 0, 0)
		_SpeedWater2("_SpeedWater2", Float) = 0.01
		[ShowAsVector2] _DirectionWater2("_DirectionWater2", Vector) = (-0.4, 0.02, 0, 0)
		[Header(FOAM)]
		[ShowAsVector2] _DirectionNoise("_DirectionNoise", Vector) = (-0.18, 0.3, 0, 0)
		_FoamDistance("_FoamDistance", Range(0.0, 1.0)) = 0.57
		_SpeedFoam("_SpeedFoam", Float) = 0.03
		_DirectionFoam("_DirectionFoam", Vector) = (1.5, 0, -0.3, 0.4)
		_FoamMultiplier("_FoamMultiplier", Range(0.0, 5.0)) = 0.4
		[Header(WAVES)]
		_MaxHeightWater("_MaxHeightWater", Float) = 0.02
		_SpeedWaves("_SpeedWaves", Float) = 0.03
		_WaterDirection("_WaterDirection", Vector) = (0.01, 0, -0.005, 0.03)
		//
		[Toggle]_UseHeightmap("Use Heightmap", Float) = 1
		[Header(First Wave)]
		[ShowAsVector2] _Wave1Direction("_Direction", Vector) = (-0.4, 0.02, 0, 0)
		_Amplitude1("Amplitude", Float) = 0.2
		_WaveLength1("Wave Length", Float) = 2
		_WaveSpeed1("Wave Speed", Float) = 2
		_Wave1Weight("Weight", Range(0.0, 1.0)) = 1
		[Header(Second Wave)]
		[ShowAsVector2] _Wave2Direction("_Direction", Vector) = (-0.4, 0.02, 0, 0)
		_Amplitude2("Amplitude", Float) = 0.2
		_WaveLength2("Wave Length", Float) = 2
		_WaveSpeed2("Wave Speed", Float) = 2
		_Wave2Weight("Weight", Range(0.0, 1.0)) = 1
		[Header(Center Direction Wave)]
		_Amplitude3("Amplitude", Float) = 0.2
		_WaveLength3("Wave Length", Float) = 2
		_WaveSpeed3("Wave Speed", Float) = 2
		_Wave3Weight("Weight", Range(0.0, 1.0)) = 1
		//AlphaBlend
		[Header(Alpha Blend)]
		_Transparency("Transparency", Range(0.0, 1.0)) = 1
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" }
		LOD 100
		ZWrite Off

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			

			CGPROGRAM
			#pragma vertex MyVS
			#pragma fragment MyPS

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float2 waterUV : TEXCOORD0;
				float2 uv : TEXCOORD1;
				float2 foamUV : TEXCOORD2;
				float2 noiseUV : TEXCOORD3;
			};
			
			//Uniforms
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _WaterDepthTex;
			float4 _WaterDepthTex_ST;
			sampler2D _FoamTex;
			float4 _FoamTex_ST;
			sampler2D _NoiseTex;
			float4 _NoiseTex_ST;
			sampler2D _WaterHeightmapTex;
			float4 _WaterHeightmapTex_ST;
			float4 _DeepWaterColor;
			float4 _WaterColor;
			float _SpeedWater1;
			float4 _DirectionWater1;
			float _SpeedWater2;
			float4 _DirectionWater2;
			float4 _DirectionNoise;
			float _FoamDistance;
			float _SpeedFoam;
			float4 _DirectionFoam;
			float _FoamMultiplier;
			float _MaxHeightWater;
			float _SpeedWaves;
			float4 _WaterDirection;
			int _UseHeightmap;

			float4 _Wave1Direction;
			float _Amplitude1;
			float _WaveLength1;
			float _WaveSpeed1;
			float _Wave1Weight;

			float4 _Wave2Direction;
			float _Amplitude2;
			float _WaveLength2;
			float _WaveSpeed2;
			float _Wave2Weight;

			
			float _Amplitude3;
			float _WaveLength3;
			float _WaveSpeed3;
			float _Wave3Weight;

			float _Transparency;

			v2f MyVS(appdata v)
			{
				v2f o;
				
				o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));

				if (_UseHeightmap)
				{
					float2 wavesUV = TRANSFORM_TEX(v.uv, _WaterHeightmapTex);
					float2 movedWaterUV = wavesUV + normalize(_WaterDirection.xy) * _SpeedWaves * _Time.y;
					float l_Height = tex2Dlod(_WaterHeightmapTex, float4(movedWaterUV, 0, 0)).x * _MaxHeightWater;
					o.vertex.y += l_Height;
				}
				else
				{
					float l_frequency1 = 2 / _WaveLength1;
					float l_frequency2 = 2 / _WaveLength2;
					float l_frequency3 = 2 / _WaveLength3;
					float2 l_CenterPosition = mul(unity_ObjectToWorld, float4(0.5, 0.5, 0.5, 1.0)).xz;
					float2 dir = l_CenterPosition - o.vertex.xz;

					float wave = (_Amplitude1 * sin(dot(o.vertex.xz, normalize(_Wave1Direction)) * l_frequency1 + _Time.y * l_frequency1 * _WaveSpeed1)) * _Wave1Weight
								+ (_Amplitude2 * sin(dot(o.vertex.xz, normalize(_Wave2Direction)) * l_frequency2 + _Time.y * l_frequency2 * _WaveSpeed2)) * _Wave2Weight
								+ (_Amplitude3 * sin(dot(o.vertex.xz,normalize(dir)) * l_frequency3 + _Time.y * l_frequency3 * _WaveSpeed3)) * _Wave3Weight;

					o.vertex.y += wave;
				}

				o.vertex = mul(UNITY_MATRIX_V, o.vertex);
				o.vertex = mul(UNITY_MATRIX_P, o.vertex);


				o.waterUV = TRANSFORM_TEX(v.uv, _MainTex);
				o.foamUV = TRANSFORM_TEX(v.uv, _FoamTex);
				o.noiseUV = TRANSFORM_TEX(v.uv, _NoiseTex);
				o.uv = v.uv;
				
				return o;
			}

			fixed4 MyPS(v2f i) : SV_Target
			{
				//Water Color
				float2 movedWaterUV1 = i.waterUV + normalize(_DirectionWater1.xy) * _SpeedWater1 * _Time.y;
				float2 movedWaterUV2 = i.waterUV + normalize(_DirectionWater2.xy) * _SpeedWater2 * _Time.y;
				float4 texColor1 = tex2D(_MainTex,movedWaterUV1);
				float4 texColor2 = tex2D(_MainTex, movedWaterUV2);
				float4 texColor = texColor1 + texColor2;
				//Depth Color
				float waterDepth = tex2D(_WaterDepthTex,i.uv);
				float4 depthColor = float4(waterDepth * _WaterColor.xyz + (1- waterDepth) * _DeepWaterColor.xyz,1);
				//Foam
				float foamColor = 0;
				if (waterDepth > _FoamDistance)
				{
					float2 movedFoamUV = i.foamUV + normalize(_DirectionFoam.xy) * _SpeedFoam * _Time.y;
					float foamTex = tex2D(_FoamTex, movedFoamUV);
					float2 noiseUV = i.noiseUV + normalize(_DirectionNoise.xy) * _SpeedFoam * _FoamMultiplier * _Time.y;
					float noiseTex = tex2D(_NoiseTex, noiseUV);

					foamColor = (1- noiseTex) * foamTex;
					foamColor = lerp(foamColor, 0, (1 - waterDepth) / (1 - _FoamDistance));
				}


				return float4(texColor.xyz * depthColor.xyz + foamColor,_Transparency);
			}
			ENDCG
		}
	}
}
