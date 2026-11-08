using System.IO;
using UnityEditor;
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

            const string scenePath = "Assets/Scenes/Main.unity";
            if (!File.Exists(scenePath))
            {
                Directory.CreateDirectory("Assets/Scenes");
                var scene = EditorSceneManager.NewScene(NewSceneSetup.EmptyScene, NewSceneMode.Single);
                var root = new GameObject("GIKOKO_Studio");
                root.AddComponent<GIKOKO.Studio.StudioBootstrap>();
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
