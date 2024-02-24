Shader "Tecnocampus/WaterShader"
{
	Properties
	{
		_MainTex("Main Texture", 2D) = "defaulttexture"{}
		_WaterDepthTex("_WaterDepthTex", 2D) = "defaulttexture"{}
		_FoamTex("_FoamTex", 2D) = "defaulttexture"{}
		_NoiseTex("_NoiseTexture", 2D) = "defaulttexture"{}
		_WaterHeightmapTex("_WaterHeightmapTex", 2D) = "defaulttexture"{}
		_DeepWaterColor("Deep Water Color", Color) = (1, 1, 1, 1)
		_WaterColor("Water Color", Color) = (1, 1, 1, 1)
		_SpeedWater1("_SpeedWater1", Float) = 0.05
		[ShowAsVector2] _DirectionWater1("_DirectionWater1", Vector) = (0.3, -0.1, 0, 0)
		_SpeedWater2("_SpeedWater2", Float) = 0.01
		[ShowAsVector2] _DirectionWater2("_DirectionWater2", Vector) = (-0.4, 0.02, 0, 0)
		[ShowAsVector2] _DirectionNoise("_DirectionNoise", Vector) = (-0.18, 0.3, 0, 0)
		_FoamDistance("_FoamDistance", Range(0.0, 1.0)) = 0.57
		_SpeedFoam("_SpeedFoam", Float) = 0.03
		_DirectionFoam("_DirectionFoam", Vector) = (1.5, 0, -0.3, 0.4)
		_FoamMultiplier("_FoamMultiplier", Range(0.0, 5.0)) = 0.4
		_MaxHeightWater("_MaxHeightWater", Float) = 0.02
		_SpeedWaves("_SpeedWaves", Float) = 0.03
		_WaterDirection("_WaterDirection", Vector) = (0.01, 0, -0.005, 0.03)
	}
	SubShader
	{
		Tags{ "Queue" = "Transparent" "RenderType" = "Transparent" "IgnoreProjector" = "True" }
		LOD 100

		Pass
		{
			Blend SrcAlpha OneMinusSrcAlpha
			ZWrite Off

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

			v2f MyVS(appdata v)
			{
				v2f o;
				
				o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));

				float2 wavesUV = TRANSFORM_TEX(v.uv, _WaterHeightmapTex);
				float2 movedWaterUV = wavesUV + normalize(_WaterDirection.xy) * _SpeedWaves * _Time.y;
				float l_Height = tex2Dlod(_WaterHeightmapTex, float4(movedWaterUV, 0, 0)).x * _MaxHeightWater;
				o.vertex.y += l_Height;

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
					

					//float smooth = smoothstep(_FoamMultiplier, _FoamMultiplier - waterDepth, noiseColor);
					//foamColor = foamColor * smooth;
					foamColor = lerp(foamColor, 0, (1 - waterDepth) / (1 - _FoamDistance));
					
					//foamColor =  waterDepth - _FoamDistance;
				}


				return float4(texColor.xyz * depthColor.xyz + foamColor,1);
			}
			ENDCG
		}
	}
}
