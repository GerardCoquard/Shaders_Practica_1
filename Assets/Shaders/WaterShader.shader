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

		[Header(Water Depth)]
		_MinTransparency("Min Transparency", Range(0.0, 1.0)) = 0.4
		_MaxTransparency("Max Transparency", Range(0.0, 1.0)) = 0.8
		_StartDistance("Start Distance", Float) = 1
		_EndDistance("End Distance", Float) = 1
		
		[Header(Lightning)]
		_SpecularPower("_SpecularPower", Float) = 0
		_AmbientIntensity("_AmbientIntensity", Float) = 0
		_AmbientColor("_AmbientColor", Color) = (1.0, 1.0, 1.0, 1.0)
		_normalCheckDistance("Normal Check Distance", Float) = 1
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
			#define MAX_LIGHTS 4

			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal : NORMAL;
			};
			struct v2f
			{
				float4 vertex : SV_POSITION;
				float3 normal : NORMAL;
				float2 waterUV : TEXCOORD0;
				float2 uv : TEXCOORD1;
				float2 foamUV : TEXCOORD2;
				float2 noiseUV : TEXCOORD3;
				float3 worldPosition : TEXCOORD4;
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

			float _MinTransparency;
			float _MaxTransparency;
			float _StartDistance;
			float _EndDistance;

			float4 _AmbientColor;
			float _AmbientIntensity;
			float _SpecularPower;
			int _LightsCount;
			int _LightTypes[MAX_LIGHTS]; //0=Spot, 1=Directional, 2=Point
			float4 _LightColors[MAX_LIGHTS];
			float4 _LightPositions[MAX_LIGHTS];
			float4 _LightDirections[MAX_LIGHTS];
			float4 _LightProperties[MAX_LIGHTS]; //x=Range, y=Intensity, z=Spot Angle, w=cos(Half Spot Angle)
			float _normalCheckDistance;

			float GetHeight(float3 pos, float2 _uv)
			{
				if (_UseHeightmap)
				{
					//Use heightmap texture to create waves
					float2 wavesUV = TRANSFORM_TEX(_uv, _WaterHeightmapTex);
					float2 movedWaterUV = wavesUV + normalize(_WaterDirection.xy) * _SpeedWaves * _Time.y;
					float l_Height = tex2Dlod(_WaterHeightmapTex, float4(movedWaterUV, 0, 0)).x * _MaxHeightWater;
					return l_Height;
				}
				else
				{
					//Use sin to create waves
					float l_frequency1 = 2 / _WaveLength1;
					float l_frequency2 = 2 / _WaveLength2;
					float l_frequency3 = 2 / _WaveLength3;
					float2 l_CenterPosition = mul(unity_ObjectToWorld, float4(0.5, 0.5, 0.5, 0.5)).xz;
					float2 dir = l_CenterPosition/4 - pos.xz;

					//Sum all waves together
					float wave = (_Amplitude1 * sin(dot(pos.xz, normalize(_Wave1Direction)) * l_frequency1 + _Time.y * l_frequency1 * _WaveSpeed1)) * _Wave1Weight
						+ (_Amplitude2 * sin(dot(pos.xz, normalize(_Wave2Direction)) * l_frequency2 + _Time.y * l_frequency2 * _WaveSpeed2)) * _Wave2Weight
						+ (_Amplitude3 * sin(dot(pos.xz, normalize(-dir)) * l_frequency3 + _Time.y * l_frequency3 * _WaveSpeed3)) * _Wave3Weight;

					return wave;
				}
			}

			v2f MyVS(appdata v)
			{
				v2f o;
				
				o.vertex = mul(unity_ObjectToWorld, float4(v.vertex.xyz, 1.0));

				//Create Waves by modifying height
				o.vertex.y += GetHeight(o.vertex, v.uv);
				
				o.worldPosition = o.vertex;

				//Read neightbor heights
				float3 off = float3(_normalCheckDistance, _normalCheckDistance, 0.0);
				float hL = GetHeight(o.vertex.xyz - float3(off.xz, 0), v.uv);
				float hR = GetHeight(o.vertex.xyz + float3(off.xz, 0), v.uv);
				float hD = GetHeight(o.vertex.xyz - float3(off.zy, 0), v.uv);
				float hU = GetHeight(o.vertex.xyz + float3(off.zy, 0), v.uv);

				//Aproximate normal
				o.normal.x = hL - hR;
				o.normal.y = hD - hU;
				o.normal.z = 2.0;
				o.normal = normalize(o.normal);
				o.normal = -o.normal;
				
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

				//Depth Alpha
				float l_Depth = length(i.worldPosition - _WorldSpaceCameraPos);
				float l_AlphaIntensity = saturate((l_Depth - _StartDistance) / (_EndDistance - _StartDistance));

				//Lightning
				float3 Nn = normalize(i.normal);
				float4 l_color = float4(texColor.xyz * depthColor.xyz + foamColor, lerp(_MinTransparency, _MaxTransparency, l_AlphaIntensity));
				float3 l_DifuseLighting = float3(0, 0, 0);
				float3 l_Specular = float3(0, 0, 0);
				float3 l_FullLighting = float3(0, 0, 0);

				for (int x = 0; x < _LightsCount; x++)
				{
					float3 l_LightDirection = _LightDirections[x].xyz;

					float l_distance = length(i.worldPosition - _LightPositions[x].xyz);
					float l_Attenuation = 1.0;

					if (_LightTypes[x] == 2)
					{
						l_LightDirection = normalize(i.worldPosition - _LightPositions[x].xyz);
						l_Attenuation = saturate(1 - l_distance / _LightProperties[x].x);
					}
					if (_LightTypes[x] == 0)
					{
						l_LightDirection = normalize(i.worldPosition - _LightPositions[x].xyz);
						l_Attenuation = saturate(1 - l_distance / _LightProperties[x].x);
						float l_DotSpot = dot(_LightDirections[x].xyz, l_LightDirection);
						float l_AngleAttenuation = saturate((l_DotSpot - _LightProperties[x].w) / (1.0 - _LightProperties[x].w));
						l_Attenuation *= l_AngleAttenuation;

					}
					float Kd = saturate(dot(Nn, -l_LightDirection));

					l_DifuseLighting += Kd * l_color.xyz * _LightColors[x].xyz * _LightProperties[x].y * l_Attenuation;
					float3 l_CameraVector = normalize(i.worldPosition - _WorldSpaceCameraPos);
					float3 l_ReflectedVector = normalize(reflect(l_CameraVector, normalize(i.normal)));
					float l_Ks = pow(saturate(dot(-_LightDirections[x].xyz, l_ReflectedVector)), _SpecularPower);

					l_Specular = l_Ks * _LightColors[x].xyz * l_Attenuation * _LightProperties[x].y;

					float3 l_AmbientLighting = l_color.xyz * _AmbientColor.xyz * _AmbientIntensity;
					l_FullLighting = l_Specular + l_DifuseLighting + l_AmbientLighting;
				}

				return float4(l_FullLighting, l_color.a);
			}
			ENDCG
		}
	}
}
