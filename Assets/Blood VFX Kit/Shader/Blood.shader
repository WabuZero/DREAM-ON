// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Particles/Blood"
{
	Properties
	{
		_Color("Color", Color) = (0,0,0,0)
		_MainTex("MainTex", 2D) = "white" {}
		[NoScaleOffset][Normal]_Normal("Normal", 2D) = "bump" {}
		_NormalScale("Normal Scale", Float) = 0
		_AlphaTexture("Alpha Texture", Range( 0 , 1)) = 0
		_SmoothTexture("Smooth Texture", Float) = 1
		_Smothness("Smothness", Range( 0 , 1)) = 0.9529412
		_SpecularColor("SpecularColor", Color) = (0.4528301,0.4528301,0.4528301,1)
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] _tex4coord( "", 2D ) = "white" {}
		[HideInInspector] _tex4coord2( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Transparent"  "Queue" = "Transparent+0" "IgnoreProjector" = "True" }
		Cull Off
		CGINCLUDE
		#include "UnityStandardUtils.cginc"
		#include "UnityPBSLighting.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#undef TRANSFORM_TEX
		#define TRANSFORM_TEX(tex,name) float4(tex.xy * name##_ST.xy + name##_ST.zw, tex.z, tex.w)
		struct Input
		{
			float2 uv_texcoord;
			float4 vertexColor : COLOR;
			float4 uv_tex4coord;
			float4 uv2_tex4coord2;
		};

		uniform sampler2D _Normal;
		uniform sampler2D _MainTex;
		uniform float4 _MainTex_ST;
		uniform float _NormalScale;
		uniform float4 _Color;
		uniform float4 _SpecularColor;
		uniform float _Smothness;
		uniform float _AlphaTexture;
		uniform float _SmoothTexture;

		void surf( Input i , inout SurfaceOutputStandardSpecular o )
		{
			float2 uv_MainTex = i.uv_texcoord * _MainTex_ST.xy + _MainTex_ST.zw;
			o.Normal = UnpackScaleNormal( tex2D( _Normal, uv_MainTex ), _NormalScale );
			o.Albedo = ( i.vertexColor * _Color ).rgb;
			o.Specular = _SpecularColor.rgb;
			o.Smoothness = _Smothness;
			float clampResult27 = clamp( ( -i.uv2_tex4coord2.y / i.uv_tex4coord.w ) , 0.0 , 1.0 );
			o.Alpha = ( i.vertexColor.a * saturate( ( ( tex2D( _MainTex, uv_MainTex ).r - ( _AlphaTexture + i.uv_tex4coord.z + clampResult27 ) ) / _SmoothTexture ) ) );
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardSpecular alpha:fade keepalpha fullforwardshadows nolightmap  

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			sampler3D _DitherMaskLOD;
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float2 customPack1 : TEXCOORD1;
				float4 customPack2 : TEXCOORD2;
				float4 customPack3 : TEXCOORD3;
				float3 worldPos : TEXCOORD4;
				float4 tSpace0 : TEXCOORD5;
				float4 tSpace1 : TEXCOORD6;
				float4 tSpace2 : TEXCOORD7;
				half4 color : COLOR0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.customPack2.xyzw = customInputData.uv_tex4coord;
				o.customPack2.xyzw = v.texcoord;
				o.customPack3.xyzw = customInputData.uv2_tex4coord2;
				o.customPack3.xyzw = v.texcoord1;
				o.worldPos = worldPos;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				o.color = v.color;
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				surfIN.uv_tex4coord = IN.customPack2.xyzw;
				surfIN.uv2_tex4coord2 = IN.customPack3.xyzw;
				float3 worldPos = IN.worldPos;
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.vertexColor = IN.color;
				SurfaceOutputStandardSpecular o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputStandardSpecular, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				half alphaRef = tex3D( _DitherMaskLOD, float3( vpos.xy * 0.25, o.Alpha * 0.9375 ) ).a;
				clip( alphaRef - 0.01 );
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18900
179;776;2005;501;3156.843;516.5956;2.570359;True;True
Node;AmplifyShaderEditor.TextureCoordinatesNode;26;-2215.772,824.1569;Inherit;False;1;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NegateNode;31;-1912.564,841.5752;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;23;-2119.985,456.5066;Inherit;False;0;-1;4;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;28;-1680.679,861.8186;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;20;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;38;-1100.824,637.5962;Inherit;False;0;1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;4;-1741.222,378.5788;Float;False;Property;_AlphaTexture;Alpha Texture;4;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;27;-1501.788,817.6922;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;1;-865.3353,167.249;Inherit;True;Property;_MainTex;MainTex;1;0;Create;True;0;0;0;False;0;False;-1;None;91127f3e664c4d4489781fa0415b9ff3;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;24;-1431.612,397.3494;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;5;-491.5,287;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;7;-527.5,478;Float;False;Property;_SmoothTexture;Smooth Texture;5;0;Create;True;0;0;0;False;0;False;1;0.01;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;6;-316.5,347;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;20;-362.198,-395.6074;Float;False;Property;_Color;Color;0;0;Create;True;0;0;0;False;0;False;0,0,0,0;0.2156862,0,0,1;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;8;-174.5,379;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;14;-570.8016,766.4295;Float;False;Property;_NormalScale;Normal Scale;3;0;Create;True;0;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.VertexColorNode;9;-317.184,-125.701;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;25;43.6898,124.1661;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;59;1323.109,284.7001;Float;False;Property;_SpecularColor;SpecularColor;7;0;Create;True;0;0;0;False;0;False;0.4528301,0.4528301,0.4528301,1;0,0,0,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;12;1162.777,5.652431;Float;False;Property;_Smothness;Smothness;6;0;Create;True;0;0;0;False;0;False;0.9529412;0.25;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;2;-322.6856,639.651;Inherit;True;Property;_Normal;Normal;2;2;[NoScaleOffset];[Normal];Create;True;0;0;0;False;0;False;-1;None;f20d887c9a1fc004fa2bf33b8102ddcb;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;10;97.12164,-176.5482;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;0;1642.9,-197.6;Float;False;True;-1;2;ASEMaterialInspector;0;0;StandardSpecular;Particles/Blood;False;False;False;False;False;False;True;False;False;False;False;False;False;False;True;False;False;False;False;False;False;Off;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Transparent;0.5;True;True;0;False;Transparent;;Transparent;All;14;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;2;5;False;-1;10;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;16;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;31;0;26;2
WireConnection;28;0;31;0
WireConnection;28;1;23;4
WireConnection;27;0;28;0
WireConnection;1;1;38;0
WireConnection;24;0;4;0
WireConnection;24;1;23;3
WireConnection;24;2;27;0
WireConnection;5;0;1;1
WireConnection;5;1;24;0
WireConnection;6;0;5;0
WireConnection;6;1;7;0
WireConnection;8;0;6;0
WireConnection;25;0;9;4
WireConnection;25;1;8;0
WireConnection;2;1;38;0
WireConnection;2;5;14;0
WireConnection;10;0;9;0
WireConnection;10;1;20;0
WireConnection;0;0;10;0
WireConnection;0;1;2;0
WireConnection;0;3;59;0
WireConnection;0;4;12;0
WireConnection;0;9;25;0
ASEEND*/
//CHKSM=310CA89B493BF0F6FA9506E4DDD5EE18BE8E8D67