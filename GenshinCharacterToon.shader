// ============================================================
//  仿原神角色卡通渲染 Shader (Genshin-Style Character Toon)
//  兼容: Unity 6.x / URP 17+
//  特性: Ramp漫反射 / 面部SDF阴影 / 多层高光 / 头发高光 /
//        双侧边缘光 / 法线外扩描边 / 自发光 / Alpha裁剪
// ============================================================

Shader "GenshinToon/CharacterToon"
{
    Properties
    {
        // ==================== 基础贴图 ====================
        _BaseMap("Base Map (RGB:固有色 A:自发光遮罩)", 2D) = "white" {}
        _BaseColor("Base Color", Color) = (1,1,1,1)

        // ==================== ILM 光照控制贴图 ====================
        // R: 高光类型层  G: 阴影AO遮罩  B: 高光形状/强度  A: Ramp层选择
        _LightMap("Light Map (ILM)  R:高光层 G:AO B:高光形 A:Ramp层", 2D) = "white" {}

        // ==================== Ramp 阴影色贴图 ====================
        // 横轴: Half-Lambert (暗→亮)  纵轴: 不同材质层 (由LightMap.a选择)
        _RampMap("Ramp Map (阴影色渐变)", 2D) = "white" {}
        _RampMapNight("Ramp Map Night (冷色调,可选)", 2D) = "white" {}
        [Toggle(_USE_NIGHT_RAMP)] _UseNightRamp("使用夜晚冷色Ramp", Float) = 0

        // ==================== 面部 SDF 阴影 ====================
        [Toggle(_FACE_SDF_ON)] _FaceSDFOn("启用面部SDF阴影", Float) = 0
        _FaceSDFMap("Face SDF Map (面部阴影阈值图)", 2D) = "grey" {}
        _FaceSDFSoftness("面部阴影边缘柔和度", Range(0.001, 0.2)) = 0.02
        _FaceShadowColor("面部阴影颜色", Color) = (0.5,0.5,0.6,1)
        _FaceShadowStrength("面部阴影强度", Range(0, 1)) = 0.6

        // ==================== 法线贴图 ====================
        [Toggle(_NORMALMAP_ON)] _NormalMapOn("启用法线贴图", Float) = 0
        _NormalMap("Normal Map", 2D) = "bump" {}
        _NormalScale("法线强度", Range(0, 2)) = 1.0

        // ==================== 漫反射参数 ====================
        _LightThreshold("明暗分界阈值", Range(0, 1)) = 0.5
        _ShadowSoftness("阴影边缘柔和度", Range(0.001, 0.3)) = 0.05
        _RampIntensity("Ramp颜色强度", Range(0, 3)) = 1.0
        _DarkIntensity("暗部整体强度", Range(0, 1)) = 0.6
        _BrightIntensity("亮部整体强度", Range(0.5, 2)) = 1.0
        _CharacterIntensity("角色整体亮度", Range(0.1, 3)) = 1.0
        _AOSoftness("固有阴影AO柔和度", Range(0.01, 0.5)) = 0.2

        // ==================== 通用高光参数 ====================
        _SpecularIntensity("Blinn-Phong高光强度", Range(0, 10)) = 1.0
        _SpecularExp("Blinn-Phong高光指数", Range(1, 500)) = 200
        _StepSpecularWidth("裁边高光宽度", Range(0.001, 0.3)) = 0.05
        _StepSpecularIntensity("裁边高光强度", Range(0, 5)) = 1.0
        _StepSpecularColor("裁边高光颜色", Color) = (1,1,1,1)

        // ==================== 头发高光 ====================
        [Toggle(_HAIR_SPECULAR_ON)] _HairSpecularOn("启用头发高光", Float) = 0
        _HairSpecularRange("头发高光范围", Range(0.001, 0.2)) = 0.03
        _HairSpecularViewRange("视角裁剪范围", Range(0.001, 0.3)) = 0.08
        _HairSpecularIntensity("头发高光强度", Range(0, 10)) = 3.0
        _HairSpecularColor("头发高光颜色", Color) = (1,1,1,1)
        _HairSpecularDarkRatio("暗部头发高光保留比例", Range(0, 1)) = 0.3

        // ==================== 金属 Matcap 高光 ====================
        [Toggle(_METALLIC_ON)] _MetallicOn("启用金属Matcap高光", Float) = 0
        _MetalGradientMap("金属渐变贴图 (Matcap式)", 2D) = "grey" {}
        _MetalIntensity("金属高光强度", Range(0, 5)) = 1.0
        _MetalThreshold("金属区域阈值(LightMap.r>?)", Range(0, 1)) = 0.9

        // ==================== 边缘光 (Rim) ====================
        [Toggle(_RIM_ON)] _RimOn("启用边缘光", Float) = 1
        _RimPow("亮部Rim指数", Range(0.1, 10)) = 2.0
        _RimSmooth("亮部Rim平滑", Range(0.001, 1)) = 0.3
        _RimColor("亮部Rim颜色", Color) = (1,0.95,0.85,1)
        _RimIntensity("亮部Rim强度", Range(0, 5)) = 1.0
        _DarkSideRimPow("暗部Rim指数", Range(0.1, 10)) = 3.0
        _DarkSideRimSmooth("暗部Rim平滑", Range(0.001, 1)) = 0.3
        _DarkSideRimColor("暗部Rim颜色", Color) = (0.5,0.6,1,1)
        _DarkSideRimIntensity("暗部Rim强度", Range(0, 5)) = 0.8
        _RimLambertWeight("Rim的Lambert方向权重", Range(0, 1)) = 0.5

        // ==================== 自发光 ====================
        _EmissionColor("自发光颜色 (HDR)", Color) = (0,0,0,1)
        _EmissionIntensity("自发光强度", Range(0, 20)) = 1.0

        // ==================== 描边 ====================
        _OutlineWidth("描边宽度", Range(0, 20)) = 2.0
        _OutlineColor("描边颜色", Color) = (0,0,0,1)
        _OutlineZOffset("描边深度偏移", Range(-0.01, 0.01)) = 0.0
        [Toggle(_OUTLINE_COLOR_FROM_BASE)] _OutlineColorFromBase("描边颜色采样固有色(原神式)", Float) = 1

        // ==================== Alpha 裁剪 ====================
        [Toggle(_ALPHATEST_ON)] _AlphaClipOn("启用Alpha裁剪", Float) = 0
        _Cutoff("Alpha裁剪阈值", Range(0, 1)) = 0.5

        // ==================== 调试 ====================
        [KeywordEnum(None, Diffuse, Ramp, AO, Specular, Rim, FaceSDF)] _DebugMode("调试模式", Float) = 0
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

        // ==================== 材质属性 CBuffer (SRP Batcher 兼容) ====================
        CBUFFER_START(UnityPerMaterial)
            float4 _BaseMap_ST;
            float4 _BaseColor;
            float4 _LightMap_ST;
            float4 _RampMap_ST;
            float4 _RampMapNight_ST;
            float4 _FaceSDFMap_ST;
            float4 _FaceShadowColor;
            float4 _NormalMap_ST;
            float4 _StepSpecularColor;
            float4 _HairSpecularColor;
            float4 _MetalGradientMap_ST;
            float4 _RimColor;
            float4 _DarkSideRimColor;
            float4 _EmissionColor;
            float4 _OutlineColor;

            float _FaceSDFSoftness;
            float _FaceShadowStrength;
            float _NormalScale;
            float _LightThreshold;
            float _ShadowSoftness;
            float _RampIntensity;
            float _DarkIntensity;
            float _BrightIntensity;
            float _CharacterIntensity;
            float _AOSoftness;
            float _SpecularIntensity;
            float _SpecularExp;
            float _StepSpecularWidth;
            float _StepSpecularIntensity;
            float _HairSpecularRange;
            float _HairSpecularViewRange;
            float _HairSpecularIntensity;
            float _HairSpecularDarkRatio;
            float _MetalIntensity;
            float _MetalThreshold;
            float _RimPow;
            float _RimSmooth;
            float _RimIntensity;
            float _DarkSideRimPow;
            float _DarkSideRimSmooth;
            float _DarkSideRimIntensity;
            float _RimLambertWeight;
            float _EmissionIntensity;
            float _OutlineWidth;
            float _OutlineZOffset;
            float _Cutoff;
        CBUFFER_END

        // ==================== 贴图声明 ====================
        TEXTURE2D(_BaseMap);       SAMPLER(sampler_BaseMap);
        TEXTURE2D(_LightMap);      SAMPLER(sampler_LightMap);
        TEXTURE2D(_RampMap);       SAMPLER(sampler_RampMap);
        TEXTURE2D(_RampMapNight);  SAMPLER(sampler_RampMapNight);
        TEXTURE2D(_FaceSDFMap);    SAMPLER(sampler_FaceSDFMap);
        TEXTURE2D(_NormalMap);     SAMPLER(sampler_NormalMap);
        TEXTURE2D(_MetalGradientMap); SAMPLER(sampler_MetalGradientMap);

        // ==================== 辅助函数 ====================

        // 安全平滑步进 (避免除零)
        float SafeSmoothstep(float edge0, float edge1, float x)
        {
            float d = edge1 - edge0;
            return d > 1e-5 ? smoothstep(edge0, edge1, x) : step(edge0, x);
        }

        // 获取物体前向方向 (模型空间+Z → 世界空间)
        float3 GetObjectForwardWS()
        {
            return normalize(mul((float3x3)UNITY_MATRIX_M, float3(0, 0, 1)));
        }

        ENDHLSL

        // ================================================================
        //  Pass 0: 描边 (Outline) — 相机空间法线外扩
        // ================================================================
        Pass
        {
            Name "Outline"
            Tags { "LightMode" = "SRPDefaultUnlit" }
            Cull Front
            ZWrite On

            HLSLPROGRAM
            #pragma vertex OutlineVert
            #pragma fragment OutlineFrag
            #pragma shader_feature_local _OUTLINE_COLOR_FROM_BASE

            struct OutlineAttr
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
                float4 color      : COLOR;
            };

            struct OutlineVary
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
            };

            OutlineVary OutlineVert(OutlineAttr input)
            {
                OutlineVary output;

                // 模型空间 → 世界空间 → 观察空间
                float3 posWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 posVS = TransformWorldToView(posWS);

                // 法线转到观察空间
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);
                float3 normalVS = normalize(mul((float3x3)UNITY_MATRIX_V, normalWS));

                // 顶点色.a 控制描边粗细 (原神式)
                float outlineWidth = _OutlineWidth * 0.001 * max(0.01, input.color.a);

                // 相机空间法线外扩
                posVS += normalVS * outlineWidth;

                output.positionHCS = TransformWViewToHClip(posVS);
                // 深度偏移, 防止描边与本体穿插
                output.positionHCS.z += _OutlineZOffset;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);

                return output;
            }

            half4 OutlineFrag(OutlineVary input) : SV_Target
            {
                #if defined(_OUTLINE_COLOR_FROM_BASE)
                    // 原神式描边: 采样固有色, 压暗并提高饱和度
                    float3 baseCol = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).rgb;
                    float maxComp = max(max(baseCol.r, baseCol.g), baseCol.b) - 0.004;
                    float3 saturated = step(maxComp.rrr, baseCol) * baseCol;
                    saturated = lerp(baseCol, saturated, 0.6);
                    float3 outlineCol = 0.8 * saturated * baseCol * _OutlineColor.rgb;
                    return half4(outlineCol, 1.0);
                #else
                    return half4(_OutlineColor.rgb, 1.0);
                #endif
            }
            ENDHLSL
        }

        // ================================================================
        //  Pass 1: 前向光照主 Pass (Forward Lit)
        // ================================================================
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForward" }
            Cull Back
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex ForwardVert
            #pragma fragment ForwardFrag

            // ==================== 编译变体 ====================
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT
            #pragma multi_compile_fog
            #pragma multi_compile_instancing

            #pragma shader_feature_local _FACE_SDF_ON
            #pragma shader_feature_local _NORMALMAP_ON
            #pragma shader_feature_local _HAIR_SPECULAR_ON
            #pragma shader_feature_local _METALLIC_ON
            #pragma shader_feature_local _RIM_ON
            #pragma shader_feature_local _ALPHATEST_ON
            #pragma shader_feature_local _USE_NIGHT_RAMP
            #pragma shader_feature_local _OUTLINE_COLOR_FROM_BASE
            #pragma shader_feature_local _DEBUGMODE_DIFFUSE _DEBUGMODE_RAMP _DEBUGMODE_AO _DEBUGMODE_SPECULAR _DEBUGMODE_RIM _DEBUGMODE_FACESDF

            // ==================== 顶点输入结构 ====================
            struct Attributes
            {
                float4 positionOS   : POSITION;
                float3 normalOS     : NORMAL;
                float4 tangentOS    : TANGENT;
                float2 uv           : TEXCOORD0;
                float4 color        : COLOR;      // vertexColor.g = Ramp偏移, .a = 描边宽度
            };

            // ==================== 顶点输出结构 ====================
            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                float3 positionWS   : TEXCOORD1;
                float3 normalWS     : TEXCOORD2;
                float3 viewDirWS    : TEXCOORD3;
                float4 vertexColor  : TEXCOORD4;
                float3 tangentWS    : TEXCOORD5;
                float3 bitangentWS  : TEXCOORD6;
                float4 shadowCoord  : TEXCOORD7;
            };

            // ==================== 顶点 Shader ====================
            Varyings ForwardVert(Attributes input)
            {
                Varyings output;

                VertexPositionInputs posInputs = GetVertexPositionInputs(input.positionOS.xyz);
                output.positionHCS = posInputs.positionCS;
                output.positionWS  = posInputs.positionWS;

                VertexNormalInputs normInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);
                output.normalWS    = normInputs.normalWS;
                output.tangentWS   = normInputs.tangentWS;
                output.bitangentWS = normInputs.bitangentWS;

                output.viewDirWS   = GetWorldSpaceViewDir(posInputs.positionWS);
                output.uv          = TRANSFORM_TEX(input.uv, _BaseMap);
                output.vertexColor = input.color;

                // 阴影坐标
                output.shadowCoord = TransformWorldToShadowCoord(posInputs.positionWS);

                return output;
            }

            // ==================== 片元 Shader ====================
            half4 ForwardFrag(Varyings input) : SV_Target
            {
                // ---------- 基础向量 ----------
                float3 N = normalize(input.normalWS);
                float3 V = normalize(input.viewDirWS);
                float3 L = float3(0, 1, 0);
                float3 lightColor = float3(1, 1, 1);
                float shadowAtten = 1.0;

                // 获取主光源
                Light mainLight = GetMainLight(input.shadowCoord);
                L = normalize(mainLight.direction);
                lightColor = mainLight.color;
                shadowAtten = mainLight.shadowAttenuation;

                float3 H = normalize(L + V); // 半角向量
                float NdotL = dot(N, L);
                float NdotV = dot(N, V);
                float NdotH = dot(N, H);

                // ---------- 法线贴图 ----------
                #if defined(_NORMALMAP_ON)
                    float3 normalTS = UnpackNormalScale(SAMPLE_TEXTURE2D(_NormalMap, sampler_NormalMap, input.uv), _NormalScale);
                    float3x3 TBN = float3x3(normalize(input.tangentWS), normalize(input.bitangentWS), N);
                    N = normalize(mul(normalTS, TBN));
                    NdotL = dot(N, L);
                    NdotV = dot(N, V);
                    NdotH = dot(N, H);
                #endif

                // ---------- 贴图采样 ----------
                float4 baseTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv);
                float3 baseCol = baseTex.rgb * _BaseColor.rgb;
                float emissionMask = baseTex.a;

                float4 ilm = SAMPLE_TEXTURE2D(_LightMap, sampler_LightMap, input.uv);
                float specularLayerMask = ilm.r;   // 高光类型层
                float shadowAOMask     = ilm.g;    // 固有阴影AO
                float specularShapeMask = ilm.b;   // 高光形状/强度
                float rampLayerMask     = ilm.a;   // Ramp层选择

                // 顶点色.g = Ramp偏移 (值越大越容易"感光")
                float rampOffset = input.vertexColor.g;

                // ---------- Alpha 裁剪 ----------
                #if defined(_ALPHATEST_ON)
                    clip(baseTex.a - _Cutoff);
                #endif

                // ================================================================
                //  一、漫反射 (Diffuse) — Half-Lambert + Ramp 分层
                // ================================================================

                // 1. Half-Lambert: 将 NdotL 从 [-1,1] 映射到 [0,1]
                float halfLambert = NdotL * 0.5 + 0.5;

                // 2. 加上 Ramp 偏移 (顶点色控制)
                halfLambert = saturate(halfLambert + rampOffset * 0.3);

                // 3. 固有阴影AO: 值越小(越暗)阴影越重, 平滑处理去除杂色
                float aoMask = SafeSmoothstep(0.0, _AOSoftness, shadowAOMask);

                // 4. 截断 Half-Lambert: 大于阈值的部分全部变亮, 形成硬边
                float halfLambertStep = SafeSmoothstep(0.0, _ShadowSoftness, halfLambert - _LightThreshold + 0.5);
                halfLambertStep = saturate(halfLambertStep * aoMask * shadowAtten);

                // 5. 采样 Ramp 贴图
                //    U轴: Half-Lambert (暗→亮)
                //    V轴: LightMap.a 选择不同材质层 (映射到 0.55~1.0 区域, 暖色白天)
                float rampU = saturate(halfLambert);
                float rampV = rampLayerMask * 0.45 + 0.55; // 白天暖色区

                #if defined(_USE_NIGHT_RAMP)
                    float3 rampColor = SAMPLE_TEXTURE2D(_RampMapNight, sampler_RampMapNight, float2(rampU, rampV * 0.45)).rgb;
                #else
                    float3 rampColor = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(rampU, rampV)).rgb;
                #endif

                // 6. 混合亮部与暗部
                //    亮部: 固有色 (BrightSide = Albedo)
                //    暗部: 固有色 × Ramp色 (DarkSide = Albedo × RampColor)
                float3 brightCol = baseCol * _BrightIntensity;
                float3 darkCol   = baseCol * rampColor * _RampIntensity * _DarkIntensity;

                // 固有阴影区域(AO)使用Ramp色
                float3 baseColShadowed = lerp(darkCol, brightCol, aoMask);

                float3 diffuse = lerp(darkCol, baseColShadowed, halfLambertStep);
                diffuse *= _CharacterIntensity;

                // 明暗区域遮罩 (用于高光等后续计算)
                float isBrightSide = halfLambertStep;

                // ================================================================
                //  二、面部 SDF 阴影 (Face SDF Shadow)
                // ================================================================
                #if defined(_FACE_SDF_ON)
                {
                    // 获取物体前向方向 (模型空间+Z → 世界空间)
                    float3 forwardWS = GetObjectForwardWS();

                    // 将光源方向投影到 XZ 平面 (L 指向光源方向, 取反得到从物体指向光源)
                    float3 lightXZ = normalize(float3(L.x, 0.0, L.z));

                    // 构造角色局部空间基矩阵 (Left, Up, Forward), 将光源变换到局部空间
                    float3 leftWS = normalize(cross(float3(0,1,0), forwardWS));
                    float3x4 faceMatrix = float3x4(leftWS, float3(0,1,0), forwardWS, float3(0,0,0));
                    float3 lightLocal = mul(faceMatrix, float4(-lightXZ, 0)).xyz;
                    lightLocal.xz = normalize(lightLocal.xz);

                    // atan2 求光源在角色局部 XZ 平面的角度 → 转为角度制
                    float angleRad = atan2(lightLocal.x, lightLocal.z);
                    float angleDeg = degrees(angleRad); // [-180, 180]
                    if (angleDeg < 0) angleDeg += 360.0; // [0, 360]

                    // 判断光源在左侧还是右侧, 决定是否翻转 SDF UV
                    bool flipUV = angleDeg > 180.0;

                    // 将角度映射到 [0,1] 作为 SDF 步进值
                    // 0°(正前方)=0, 90°(侧面)=0.5, 180°(正后方)=1
                    float sdfValue = (angleDeg <= 180.0)
                        ? angleDeg / 180.0
                        : 1.0 - (angleDeg - 180.0) / 180.0;

                    // 采样 SDF 阈值图, 根据光源左右决定是否翻转 U
                    float2 sdfUV = input.uv;
                    if (flipUV) sdfUV.x = 1.0 - sdfUV.x;
                    float sdfThreshold = SAMPLE_TEXTURE2D(_FaceSDFMap, sampler_FaceSDFMap, sdfUV).r;

                    // 步进生成面部阴影遮罩 (sdfValue > threshold → 阴影)
                    float faceShadowMask = 1.0 - SafeSmoothstep(
                        sdfThreshold - _FaceSDFSoftness,
                        sdfThreshold + _FaceSDFSoftness,
                        sdfValue
                    );

                    // 面部阴影主要在背光侧, 亮部减弱
                    faceShadowMask *= lerp(0.5, 1.0, 1.0 - isBrightSide);
                    faceShadowMask = saturate(faceShadowMask);

                    // 混合面部阴影颜色
                    float3 faceShadowCol = baseCol * _FaceShadowColor.rgb;
                    diffuse = lerp(diffuse, faceShadowCol, faceShadowMask * _FaceShadowStrength);
                }
                #endif

                // ================================================================
                //  三、高光 (Specular)
                // ================================================================
                float3 specular = float3(0, 0, 0);

                // --- 3.1 裁边高光 (Step Specular) — 服装/皮革等 ---
                // 基于 NdotV 的视角相关高光, 类似硬边 Fresnel
                float stepSpec = step(1.0 - _StepSpecularWidth, saturate(NdotV));
                float3 stepSpecular = stepSpec * _StepSpecularIntensity * _StepSpecularColor.rgb;
                // 裁边高光只在亮部出现
                stepSpecular *= isBrightSide;
                specular += stepSpecular * baseCol;

                // --- 3.2 Blinn-Phong 高光 (金属/特殊区域) ---
                // LightMap.r > 阈值的区域使用 Blinn-Phong
                float metalAreaMask = step(_MetalThreshold, specularLayerMask);
                float blinnSpec = pow(saturate(NdotH), _SpecularExp) * _SpecularIntensity * 300.0;
                blinnSpec = saturate(blinnSpec) * specularShapeMask * metalAreaMask;
                specular += blinnSpec * baseCol * 0.6;

                // --- 3.3 金属 Matcap 式渐变高光 ---
                #if defined(_METALLIC_ON)
                {
                    // Matcap 式: 用观察空间法线构造 UV, 采样金属渐变图
                    float2 matcapUV = mul((float3x3)UNITY_MATRIX_V, N).xy * 0.5 + 0.5;
                    float metalGrad = SAMPLE_TEXTURE2D(_MetalGradientMap, sampler_MetalGradientMap, matcapUV).r;
                    float metalMatcap = metalGrad * _MetalIntensity * metalAreaMask;
                    specular += metalMatcap * baseCol;
                }
                #endif

                // --- 3.4 头发高光 (Hair Specular) ---
                #if defined(_HAIR_SPECULAR_ON)
                {
                    // Blinn-Phong 变种: 硬边范围 + 视角裁剪
                    float hairRange = step(1.0 - _HairSpecularRange, saturate(NdotH));
                    float viewRange = step(1.0 - _HairSpecularViewRange, saturate(NdotV));
                    float3 hairSpec = specularShapeMask * _HairSpecularIntensity * hairRange * viewRange * _HairSpecularColor.rgb;

                    // 暗部保留部分头发高光 (原神式: 暗部不完全消失)
                    float hairBrightMask = isBrightSide;
                    float hairDarkMask = (1.0 - isBrightSide) * _HairSpecularDarkRatio;
                    hairSpec *= (hairBrightMask + hairDarkMask);

                    specular += hairSpec * baseCol;
                }
                #endif

                specular = saturate(specular);

                // ================================================================
                //  四、边缘光 (Rim Light) — 亮部/暗部分离
                // ================================================================
                float3 rimLight = float3(0, 0, 0);

                #if defined(_RIM_ON)
                {
                    float rim = 1.0 - saturate(NdotV); // Fresnel

                    // Lambert 方向控制: 区分光源侧与背光侧
                    float lambertF = max(0.0, NdotL);  // 光源侧
                    float lambertD = max(0.0, -NdotL); // 背光侧

                    // --- 亮部 Rim (光源侧) ---
                    float rimBright = pow(rim, _RimPow);
                    rimBright = lerp(rimBright, rimBright * lambertF, _RimLambertWeight);
                    rimBright = SafeSmoothstep(0.0, _RimSmooth, rimBright);
                    rimBright = pow(rimBright, 5.0); // 收紧
                    float3 rimBrightCol = rimBright * _RimColor.rgb * _RimIntensity * baseCol;

                    // --- 暗部 Rim (背光侧) ---
                    float rimDark = pow(rim, _DarkSideRimPow);
                    rimDark = lerp(rimDark, rimDark * lambertD, _RimLambertWeight);
                    rimDark = SafeSmoothstep(0.0, _DarkSideRimSmooth, rimDark);
                    rimDark = pow(rimDark, 5.0);
                    float3 rimDarkCol = rimDark * _DarkSideRimColor.rgb * _DarkSideRimIntensity * baseCol;

                    rimLight = rimBrightCol + rimDarkCol;
                }
                #endif

                // ================================================================
                //  五、自发光 (Emission)
                // ================================================================
                float3 emission = _EmissionColor.rgb * _EmissionIntensity * emissionMask;

                // ================================================================
                //  六、最终颜色合成
                // ================================================================
                float3 finalColor = diffuse + specular + rimLight + emission;

                // 乘以光源颜色
                finalColor *= lightColor;

                // 雾效
                float fogCoord = ComputeFogFactor(input.positionHCS.z);
                finalColor = MixFog(finalColor, fogCoord);

                // ================================================================
                //  调试模式
                // ================================================================
                #if defined(_DEBUGMODE_DIFFUSE)
                    finalColor = diffuse;
                #elif defined(_DEBUGMODE_RAMP)
                    finalColor = rampColor;
                #elif defined(_DEBUGMODE_AO)
                    finalColor = float3(aoMask, aoMask, aoMask);
                #elif defined(_DEBUGMODE_SPECULAR)
                    finalColor = specular;
                #elif defined(_DEBUGMODE_RIM)
                    finalColor = rimLight;
                #elif defined(_DEBUGMODE_FACESDF)
                    #if defined(_FACE_SDF_ON)
                        finalColor = float3(faceShadowMask, faceShadowMask, faceShadowMask);
                    #else
                        finalColor = float3(0,0,0);
                    #endif
                #endif

                return half4(finalColor, 1.0);
            }
            ENDHLSL
        }

        // ================================================================
        //  Pass 2: 深度法线 (DepthNormals) — 自定义实现
        // ================================================================
        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }
            Cull Back
            ZWrite On
            ZTest LEqual

            HLSLPROGRAM
            #pragma vertex DepthNormalsVert
            #pragma fragment DepthNormalsFrag
            #pragma shader_feature_local _ALPHATEST_ON

            struct DepthNormalsAttr
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct DepthNormalsVary
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
            };

            DepthNormalsVary DepthNormalsVert(DepthNormalsAttr input)
            {
                DepthNormalsVary output;
                output.positionCS = TransformObjectToHClip(input.positionOS.xyz);
                output.normalWS = TransformObjectToWorldNormal(input.normalOS);
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                return output;
            }

            float4 DepthNormalsFrag(DepthNormalsVary input) : SV_TARGET
            {
                #if defined(_ALPHATEST_ON)
                    float alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).a;
                    clip(alpha - _Cutoff);
                #endif
                return float4(normalize(input.normalWS) * 0.5 + 0.5, 0.0);
            }
            ENDHLSL
        }

        // ================================================================
        //  Pass 3: 阴影投射 (ShadowCaster) — 自定义实现
        // ================================================================
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            Cull Back
            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex ShadowCasterVert
            #pragma fragment ShadowCasterFrag
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma shader_feature_local _ALPHATEST_ON

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float3 _LightDirection;
            float3 _LightPosition;

            struct ShadowCasterAttr
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct ShadowCasterVary
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
            };

            float4 GetShadowPositionHClip(ShadowCasterAttr input)
            {
                float3 positionWS = TransformObjectToWorld(input.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(input.normalOS);

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

                return positionCS;
            }

            ShadowCasterVary ShadowCasterVert(ShadowCasterAttr input)
            {
                ShadowCasterVary output;
                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.positionCS = GetShadowPositionHClip(input);
                return output;
            }

            half4 ShadowCasterFrag(ShadowCasterVary input) : SV_TARGET
            {
                #if defined(_ALPHATEST_ON)
                    float alpha = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, input.uv).a;
                    clip(alpha - _Cutoff);
                #endif
                return 0;
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/Universal Render Pipeline/FallbackError"
    CustomEditor "GenshinToon.CharacterToonGUI"
}
