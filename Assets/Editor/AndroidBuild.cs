using System.IO;
using UnityEditor;
using UnityEditor.Build;
using UnityEditor.Build.Reporting;
using UnityEditor.SceneManagement;
using UnityEngine;

namespace GIKOKO.Editor
{
    public static class AndroidBuild
    {
        public static void BuildAndroid()
        {
            PlayerSettings.productName = "G.I KO KO 3D ANIMATION STUDIO";
            PlayerSettings.companyName = "G.I KO KO";
            PlayerSettings.applicationIdentifier = "com.gikoko.threedanimationstudio";
            PlayerSettings.bundleVersion = "0.2.0";
            PlayerSettings.Android.bundleVersionCode = 2;
            PlayerSettings.Android.minSdkVersion = AndroidSdkVersions.AndroidApiLevel23;
            PlayerSettings.Android.targetArchitectures = AndroidArchitecture.ARMv7;
            PlayerSettings.SetScriptingBackend(BuildTargetGroup.Android, ScriptingImplementation.IL2CPP);
            PlayerSettings.colorSpace = ColorSpace.Gamma;
            PlayerSettings.defaultInterfaceOrientation = UIOrientation.AutoRotation;
            PlayerSettings.allowedAutorotateToPortrait = true;
            PlayerSettings.allowedAutorotateToPortraitUpsideDown = false;
            PlayerSettings.allowedAutorotateToLandscapeLeft = true;
            PlayerSettings.allowedAutorotateToLandscapeRight = true;
            EditorUserBuildSettings.buildAppBundle = false;

            // Normalize the supplied icon for Android launcher use before assigning it.
            const string iconPath = "Assets/Art/AppIcon.jpg";
            var iconImporter = AssetImporter.GetAtPath(iconPath) as TextureImporter;
            if (iconImporter != null)
            {
                iconImporter.textureType = TextureImporterType.Default;
                iconImporter.mipmapEnabled = false;
                iconImporter.maxTextureSize = 512;
                iconImporter.textureCompression = TextureImporterCompression.Compressed;
                iconImporter.compressionQuality = 90;
                iconImporter.SaveAndReimport();
            }
            var appIcon = AssetDatabase.LoadAssetAtPath<Texture2D>(iconPath);
            if (appIcon != null)
            {
                if (appIcon.width != appIcon.height)
                    Debug.LogWarning("AppIcon.jpg is not square. Unity will fit it into launcher icon slots; a square 512x512 source is recommended.");
                PlayerSettings.SetIcons(NamedBuildTarget.Android, new[] { appIcon }, IconKind.Application);
                Debug.Log("Android launcher icon assigned: " + appIcon.width + "x" + appIcon.height);
            }
            else
                Debug.LogWarning("App icon not found. Add Assets/Art/AppIcon.jpg to include the custom icon.");

            const string scenePath = "Assets/Scenes/Main.unity";
            Directory.CreateDirectory("Assets/Scenes");
            if (!File.Exists(scenePath))
            {
                var newScene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
                var root = new GameObject("GIKOKO_Studio");
                root.AddComponent<GIKOKO.Studio.StudioBootstrap>();
                root.AddComponent<GIKOKO.Studio.FilmMakerRuntime>();
                root.AddComponent<GIKOKO.Studio.FilmMakerRuntime>();
                EditorSceneManager.SaveScene(newScene, scenePath);
            }
            else
            {
                var scene = EditorSceneManager.OpenScene(scenePath, OpenSceneMode.Single);
                GameObject root = null;
                foreach (var candidate in scene.GetRootGameObjects())
                {
                    if (candidate.GetComponent<GIKOKO.Studio.StudioBootstrap>() != null)
                    {
                        root = candidate;
                        break;
                    }
                }
                if (root == null) root = new GameObject("GIKOKO_Studio");
                if (root.GetComponent<GIKOKO.Studio.StudioBootstrap>() == null)
                    root.AddComponent<GIKOKO.Studio.StudioBootstrap>();
                if (root.GetComponent<GIKOKO.Studio.FilmMakerRuntime>() == null)
                    root.AddComponent<GIKOKO.Studio.FilmMakerRuntime>();
                EditorSceneManager.SaveScene(scene, scenePath);
            }
            Directory.CreateDirectory("Build");
            var options = new BuildPlayerOptions
            {
                scenes = new[] { scenePath },
                locationPathName = "Build/GI-KO-KO-3D-ANIMATION-STUDIO-ARMv7.apk",
                target = BuildTarget.Android,
                options = BuildOptions.None
            };
            var report = BuildPipeline.BuildPlayer(options);
            if (report.summary.result != BuildResult.Succeeded)
                throw new System.Exception("Android build failed: " + report.summary.result + " / " + report.summary.totalErrors + " errors");
            Debug.Log("APK_BUILD_SUCCESS: " + options.locationPathName);
        }
    }
}