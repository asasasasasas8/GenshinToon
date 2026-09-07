// ============================================================
//  仿原神角色 Shader 自定义材质 Inspector
//  兼容: Unity 6.x / URP 17+
// ============================================================

using UnityEditor;
using UnityEngine;
using UnityEngine.Rendering;

namespace GenshinToon
{
    public class CharacterToonGUI : ShaderGUI
    {
        // 折叠状态
        private bool _baseGroup = true;
        private bool _ilmGroup = true;
        private bool _diffuseGroup = true;
        private bool _faceSDFGroup = false;
        private bool _specularGroup = true;
        private bool _hairGroup = false;
        private bool _metallicGroup = false;
        private bool _rimGroup = true;
        private bool _emissionGroup = false;
        private bool _outlineGroup = true;
        private bool _normalGroup = false;
        private bool _alphaGroup = false;
        private bool _debugGroup = false;

        // 样式
        private const string BaseMapText = "Base Map";
        private const string LightMapText = "Light Map (ILM)";
        private const string RampMapText = "Ramp Map";

        public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
        {
            Material material = materialEditor.target as Material;
            if (material == null) return;

            // 确保关键字同步
            EnsureKeywords(material);

            EditorGUI.BeginChangeCheck();

            // ==================== 基础贴图 ====================
            _baseGroup = EditorGUILayout.BeginFoldoutHeaderGroup(_baseGroup, "基础贴图 / Base Maps");
            if (_baseGroup)
            {
                materialEditor.TextureProperty(FindProperty("_BaseMap", properties), BaseMapText);
                materialEditor.ColorProperty(FindProperty("_BaseColor", properties), "Base Color");
                EditorGUILayout.Space(4);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            // ==================== ILM 光照贴图 ====================
            _ilmGroup = EditorGUILayout.BeginFoldoutHeaderGroup(_ilmGroup, "ILM 光照控制贴图 / Light Map");
            if (_ilmGroup)
            {
                materialEditor.TextureProperty(FindProperty("_LightMap", properties), LightMapText);
                EditorGUILayout.HelpBox(
                    "通道说明:\n" +
                    "R 通道: 高光类型层 (值越大→金属/特殊高光)\n" +
                    "G 通道: 固有阴影AO (值越小→阴影越重)\n" +
                    "B 通道: 高光形状/强度遮罩\n" +
                    "A 通道: Ramp层选择 (不同材质用不同Ramp行)",
                    MessageType.Info);
                EditorGUILayout.Space(4);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            // ==================== 漫反射 ====================
            _diffuseGroup = EditorGUILayout.BeginFoldoutHeaderGroup(_diffuseGroup, "漫反射 / Diffuse (Ramp)");
            if (_diffuseGroup)
            {
                materialEditor.TextureProperty(FindProperty("_RampMap", properties), RampMapText);
                materialEditor.TextureProperty(FindProperty("_RampMapNight", properties), "Ramp Map Night");
                materialEditor.ShaderProperty(FindProperty("_UseNightRamp", properties), "使用夜晚冷色Ramp");
                EditorGUILayout.Space(4);

                materialEditor.ShaderProperty(FindProperty("_LightThreshold", properties), "明暗分界阈值");
                materialEditor.ShaderProperty(FindProperty("_ShadowSoftness", properties), "阴影边缘柔和度");
                materialEditor.ShaderProperty(FindProperty("_AOSoftness", properties), "固有阴影AO柔和度");
                EditorGUILayout.Space(2);
                materialEditor.ShaderProperty(FindProperty("_RampIntensity", properties), "Ramp颜色强度");
                materialEditor.ShaderProperty(FindProperty("_DarkIntensity", properties), "暗部整体强度");
                materialEditor.ShaderProperty(FindProperty("_BrightIntensity", properties), "亮部整体强度");
                materialEditor.ShaderProperty(FindProperty("_CharacterIntensity", properties), "角色整体亮度");
                EditorGUILayout.Space(4);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            // ==================== 面部 SDF 阴影 ====================
            _faceSDFGroup = EditorGUILayout.BeginFoldoutHeaderGroup(_faceSDFGroup, "面部SDF阴影 / Face SDF Shadow");
            if (_faceSDFGroup)
            {
                materialEditor.ShaderProperty(FindProperty("_FaceSDFOn", properties), "启用面部SDF阴影");
                if (material.IsKeywordEnabled("_FACE_SDF_ON"))
                {
                    materialEditor.TextureProperty(FindProperty("_FaceSDFMap", properties), "Face SDF Map");
                    materialEditor.ShaderProperty(FindProperty("_FaceSDFSoftness", properties), "阴影边缘柔和度");
                    materialEditor.ShaderProperty(FindProperty("_FaceShadowColor", properties), "面部阴影颜色");
                    materialEditor.ShaderProperty(FindProperty("_FaceShadowStrength", properties), "面部阴影强度");
                    EditorGUILayout.HelpBox(
                        "使用方法:\n" +
                        "1. 此材质应仅用于面部Mesh\n" +
                        "2. 角色模型的前向方向应为模型空间+Z\n" +
                        "3. SDF图建议使用EXR格式(高色深), 尺寸可较小\n" +
                        "4. R通道存储阴影阈值数据",
                        MessageType.Info);
                }
                EditorGUILayout.Space(4);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            // ==================== 高光 ====================
            _specularGroup = EditorGUILayout.BeginFoldoutHeaderGroup(_specularGroup, "高光 / Specular");
            if (_specularGroup)
            {
                EditorGUILayout.LabelField("裁边高光 (Step Specular - 服装/皮革)", EditorStyles.boldLabel);
                materialEditor.ShaderProperty(FindProperty("_StepSpecularWidth", properties), "  裁边宽度");
                materialEditor.ShaderProperty(FindProperty("_StepSpecularIntensity", properties), "  裁边强度");
                materialEditor.ColorProperty(FindProperty("_StepSpecularColor", properties), "  裁边颜色");
                EditorGUILayout.Space(4);

                EditorGUILayout.LabelField("Blinn-Phong 高光 (金属/特殊区域)", EditorStyles.boldLabel);
                materialEditor.ShaderProperty(FindProperty("_SpecularIntensity", properties), "  高光强度");
                materialEditor.ShaderProperty(FindProperty("_SpecularExp", properties), "  高光指数");
                materialEditor.ShaderProperty(FindProperty("_MetalThreshold", properties), "  金属区域阈值(LightMap.r>)");
                EditorGUILayout.Space(4);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            // ==================== 头发高光 ====================
            _hairGroup = EditorGUILayout.BeginFoldoutHeaderGroup(_hairGroup, "头发高光 / Hair Specular");
            if (_hairGroup)
            {
                materialEditor.ShaderProperty(FindProperty("_HairSpecularOn", properties), "启用头发高光");
                if (material.IsKeywordEnabled("_HAIR_SPECULAR_ON"))
                {
                    materialEditor.ShaderProperty(FindProperty("_HairSpecularRange", properties), "  高光范围");
                    materialEditor.ShaderProperty(FindProperty("_HairSpecularViewRange", properties), "  视角裁剪范围");
                    materialEditor.ShaderProperty(FindProperty("_HairSpecularIntensity", properties), "  高光强度");
                    materialEditor.ColorProperty(FindProperty("_HairSpecularColor", properties), "  高光颜色");
                    materialEditor.ShaderProperty(FindProperty("_HairSpecularDarkRatio", properties), "  暗部保留比例");
                }
                EditorGUILayout.Space(4);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            // ==================== 金属 Matcap ====================
            _metallicGroup = EditorGUILayout.BeginFoldoutHeaderGroup(_metallicGroup, "金属Matcap高光 / Metallic Matcap");
            if (_metallicGroup)
            {
                materialEditor.ShaderProperty(FindProperty("_MetallicOn", properties), "启用金属Matcap高光");
                if (material.IsKeywordEnabled("_METALLIC_ON"))
                {
                    materialEditor.TextureProperty(FindProperty("_MetalGradientMap", properties), "金属渐变贴图");
                    materialEditor.ShaderProperty(FindProperty("_MetalIntensity", properties), "  金属高光强度");
                }
                EditorGUILayout.Space(4);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            // ==================== 边缘光 ====================
            _rimGroup = EditorGUILayout.BeginFoldoutHeaderGroup(_rimGroup, "边缘光 / Rim Light");
            if (_rimGroup)
            {
                materialEditor.ShaderProperty(FindProperty("_RimOn", properties), "启用边缘光");
                if (material.IsKeywordEnabled("_RIM_ON"))
                {
                    EditorGUILayout.LabelField("亮部 Rim (光源侧)", EditorStyles.boldLabel);
                    materialEditor.ShaderProperty(FindProperty("_RimPow", properties), "  指数");
                    materialEditor.ShaderProperty(FindProperty("_RimSmooth", properties), "  平滑");
                    materialEditor.ShaderProperty(FindProperty("_RimIntensity", properties), "  强度");
                    materialEditor.ColorProperty(FindProperty("_RimColor", properties), "  颜色");
                    EditorGUILayout.Space(2);

                    EditorGUILayout.LabelField("暗部 Rim (背光侧)", EditorStyles.boldLabel);
                    materialEditor.ShaderProperty(FindProperty("_DarkSideRimPow", properties), "  指数");
                    materialEditor.ShaderProperty(FindProperty("_DarkSideRimSmooth", properties), "  平滑");
                    materialEditor.ShaderProperty(FindProperty("_DarkSideRimIntensity", properties), "  强度");
                    materialEditor.ColorProperty(FindProperty("_DarkSideRimColor", properties), "  颜色");
                    EditorGUILayout.Space(2);

                    materialEditor.ShaderProperty(FindProperty("_RimLambertWeight", properties), "Lambert方向权重");
                }
                EditorGUILayout.Space(4);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            // ==================== 自发光 ====================
            _emissionGroup = EditorGUILayout.BeginFoldoutHeaderGroup(_emissionGroup, "自发光 / Emission");
            if (_emissionGroup)
            {
                materialEditor.ColorProperty(FindProperty("_EmissionColor", properties), "自发光颜色 (HDR)");
                materialEditor.ShaderProperty(FindProperty("_EmissionIntensity", properties), "自发光强度");
                EditorGUILayout.HelpBox("自发光遮罩来自 Base Map 的 Alpha 通道", MessageType.Info);
                EditorGUILayout.Space(4);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            // ==================== 描边 ====================
            _outlineGroup = EditorGUILayout.BeginFoldoutHeaderGroup(_outlineGroup, "描边 / Outline");
            if (_outlineGroup)
            {
                materialEditor.ShaderProperty(FindProperty("_OutlineWidth", properties), "描边宽度");
                materialEditor.ColorProperty(FindProperty("_OutlineColor", properties), "描边颜色");
                materialEditor.ShaderProperty(FindProperty("_OutlineZOffset", properties), "深度偏移");
                materialEditor.ShaderProperty(FindProperty("_OutlineColorFromBase", properties), "原神式描边(采样固有色)");
                EditorGUILayout.HelpBox(
                    "描边粗细可通过顶点色 Alpha 通道控制 (0~1)\n" +
                    "原神式描边会采样固有色并自动压暗提饱和",
                    MessageType.Info);
                EditorGUILayout.Space(4);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            // ==================== 法线贴图 ====================
            _normalGroup = EditorGUILayout.BeginFoldoutHeaderGroup(_normalGroup, "法线贴图 / Normal Map");
            if (_normalGroup)
            {
                materialEditor.ShaderProperty(FindProperty("_NormalMapOn", properties), "启用法线贴图");
                if (material.IsKeywordEnabled("_NORMALMAP_ON"))
                {
                    materialEditor.TextureProperty(FindProperty("_NormalMap", properties), "Normal Map");
                    materialEditor.ShaderProperty(FindProperty("_NormalScale", properties), "法线强度");
                }
                EditorGUILayout.Space(4);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            // ==================== Alpha 裁剪 ====================
            _alphaGroup = EditorGUILayout.BeginFoldoutHeaderGroup(_alphaGroup, "Alpha裁剪 / Alpha Test");
            if (_alphaGroup)
            {
                materialEditor.ShaderProperty(FindProperty("_AlphaClipOn", properties), "启用Alpha裁剪");
                if (material.IsKeywordEnabled("_ALPHATEST_ON"))
                {
                    materialEditor.ShaderProperty(FindProperty("_Cutoff", properties), "裁剪阈值");
                }
                EditorGUILayout.Space(4);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            // ==================== 调试 ====================
            _debugGroup = EditorGUILayout.BeginFoldoutHeaderGroup(_debugGroup, "调试 / Debug");
            if (_debugGroup)
            {
                materialEditor.ShaderProperty(FindProperty("_DebugMode", properties), "调试模式");
                EditorGUILayout.Space(4);
            }
            EditorGUILayout.EndFoldoutHeaderGroup();

            // ==================== 通用渲染设置 ====================
            EditorGUILayout.Space(6);
            EditorGUILayout.LabelField("渲染设置 / Render Settings", EditorStyles.boldLabel);
            materialEditor.EnableInstancingField();
            materialEditor.RenderQueueField();

            if (EditorGUI.EndChangeCheck())
            {
                EnsureKeywords(material);
            }
        }

        /// <summary>
        /// 确保材质关键字与 Toggle 属性同步
        /// </summary>
        private static void EnsureKeywords(Material material)
        {
            SetKeyword(material, "_FACE_SDF_ON", material.GetFloat("_FaceSDFOn") > 0.5f);
            SetKeyword(material, "_NORMALMAP_ON", material.GetFloat("_NormalMapOn") > 0.5f);
            SetKeyword(material, "_HAIR_SPECULAR_ON", material.GetFloat("_HairSpecularOn") > 0.5f);
            SetKeyword(material, "_METALLIC_ON", material.GetFloat("_MetallicOn") > 0.5f);
            SetKeyword(material, "_RIM_ON", material.GetFloat("_RimOn") > 0.5f);
            SetKeyword(material, "_ALPHATEST_ON", material.GetFloat("_AlphaClipOn") > 0.5f);
            SetKeyword(material, "_USE_NIGHT_RAMP", material.GetFloat("_UseNightRamp") > 0.5f);
            SetKeyword(material, "_OUTLINE_COLOR_FROM_BASE", material.GetFloat("_OutlineColorFromBase") > 0.5f);
        }

        private static void SetKeyword(Material material, string keyword, bool enabled)
        {
            if (enabled)
                material.EnableKeyword(keyword);
            else
                material.DisableKeyword(keyword);
        }
    }
}
