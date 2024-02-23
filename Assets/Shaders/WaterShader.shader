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
		_FoamMultiplier("_FoamMultiplier", Range(1.0, 5.0)) = 2.5
		_MaxHeightWater("_MaxHeightWater", Float) = 0.02
		_WaterDirection("_DirectionFoam", Vector) = (0.01, 0, -0.005, 0.03)
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
			float4 _WaterDirection;

			v2f MyVS(appdata v)
			{
				v2f o;
				
				o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));
				o.vertex = mul(UNITY_MATRIX_V, o.vertex);
				o.vertex = mul(UNITY_MATRIX_P, o.vertex);


				o.waterUV = TRANSFORM_TEX(v.uv, _MainTex);
				o.uv = v.uv;
				
				return o;
			}

			fixed4 MyPS(v2f i) : SV_Target
			{
				//Water Color
				float2 movedWaterUV = i.waterUV + normalize(_DirectionWater1.xy) * _SpeedWater1 * _Time.y;
				float4 waterColor = tex2D(_MainTex,movedWaterUV);
				//Depth Color
				float waterDepth = tex2D(_WaterDepthTex,i.uv);
				float4 depthColor = float4(waterDepth * _WaterColor.xyz + (1-waterColor) * _DeepWaterColor.xyz,1);



				return waterColor + depthColor;
			}
			ENDCG
		}
	}
}
