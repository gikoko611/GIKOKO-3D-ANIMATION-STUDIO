using System;
using System.IO;
using UnityEngine;

namespace GIKOKO.Studio
{
    public class StudioBootstrap : MonoBehaviour
    {
        private GameObject selected;
        private int primitiveCount;
        private string status = "Ready • Unity 6 / ARMv7";

        private void Start()
        {
            Application.targetFrameRate = 30;
            QualitySettings.vSyncCount = 0;
            QualitySettings.antiAliasing = 0;
            RenderSettings.ambientLight = new Color(0.30f, 0.36f, 0.42f);
            var cameraObject = new GameObject("Studio Camera");
            var camera = cameraObject.AddComponent<Camera>();
            camera.clearFlags = CameraClearFlags.SolidColor;
            camera.backgroundColor = new Color(0.025f, 0.045f, 0.065f);
            cameraObject.transform.position = new Vector3(0, 2.7f, -6f);
            cameraObject.transform.LookAt(Vector3.zero);
            var lightObject = new GameObject("Key Light");
            var light = lightObject.AddComponent<Light>();
            light.type = LightType.Directional;
            light.intensity = 1.15f;
            lightObject.transform.rotation = Quaternion.Euler(45f, -30f, 0f);
            var ground = GameObject.CreatePrimitive(PrimitiveType.Plane);
            ground.name = "Studio Ground";
            ground.transform.localScale = new Vector3(3, 1, 3);
            var groundMat = new Material(Shader.Find("Standard"));
            groundMat.color = new Color(0.055f, 0.10f, 0.13f);
            ground.GetComponent<Renderer>().material = groundMat;
            AddPrimitive("Cube");
        }

        private void AddPrimitive(string kind)
        {
            PrimitiveType type = PrimitiveType.Cube;
            if (kind == "Sphere") type = PrimitiveType.Sphere;
            if (kind == "Capsule") type = PrimitiveType.Capsule;
            var item = GameObject.CreatePrimitive(type);
            item.name = kind + "_" + (++primitiveCount).ToString("00");
            item.transform.position = new Vector3(0, 0.7f, 0);
            var material = new Material(Shader.Find("Standard"));
            material.color = new Color(0.12f, 0.88f, 0.58f);
            material.SetFloat("_Metallic", 0.22f);
            material.SetFloat("_Glossiness", 0.55f);
            item.GetComponent<Renderer>().material = material;
            selected = item;
            status = "Added " + item.name;
        }

        private void OnGUI()
        {
            GUI.color = new Color(0.04f, 0.08f, 0.11f, 0.94f);
            GUI.Box(new Rect(12, 12, Screen.width - 24, 58), GUIContent.none);
            GUI.color = new Color(0.25f, 1f, 0.68f);
            GUI.Label(new Rect(26, 20, Screen.width - 52, 26), "G.I / KO KO 3D ANIMATION STUDIO");
            GUI.color = Color.white;
            GUI.Label(new Rect(26, 44, Screen.width - 52, 20), "UNITY 6 • POWERED BY အိုင်ကိုကို");
            float y = Screen.height - 190;
            GUI.color = new Color(0.04f, 0.08f, 0.11f, 0.96f);
            GUI.Box(new Rect(12, y, Screen.width - 24, 178), GUIContent.none);
            GUI.color = Color.white;
            float w = (Screen.width - 52) / 3f;
            if (GUI.Button(new Rect(20, y + 12, w, 42), "+ Cube")) AddPrimitive("Cube");
            if (GUI.Button(new Rect(28 + w, y + 12, w, 42), "+ Sphere")) AddPrimitive("Sphere");
            if (GUI.Button(new Rect(36 + w * 2, y + 12, w, 42), "+ Capsule")) AddPrimitive("Capsule");
            if (GUI.Button(new Rect(20, y + 62, w, 38), "Rotate")) { if (selected) selected.transform.Rotate(0, 15, 0); }
            if (GUI.Button(new Rect(28 + w, y + 62, w, 38), "Scale +")) { if (selected) selected.transform.localScale *= 1.1f; }
            if (GUI.Button(new Rect(36 + w * 2, y + 62, w, 38), "Save Project")) SaveProject();
            GUI.Label(new Rect(22, y + 112, Screen.width - 44, 24), status);
            GUI.Label(new Rect(22, y + 136, Screen.width - 44, 28), "Foundation preview • more tools are planned in phases.");
        }

        private void SaveProject()
        {
            try
            {
                var data = new StudioProject { app = "G.I KO KO 3D ANIMATION STUDIO", version = 1 };
                foreach (var item in FindObjectsOfType<MeshFilter>())
                {
                    var t = item.transform;
                    data.objects.Add(new StudioObject { name = item.name, x = t.position.x, y = t.position.y, z = t.position.z, sx = t.localScale.x, sy = t.localScale.y, sz = t.localScale.z });
                }
                string path = Path.Combine(Application.persistentDataPath, "gi_koko_project.json");
                File.WriteAllText(path, JsonUtility.ToJson(data, true));
                status = "Saved locally: " + path;
            }
            catch (Exception ex) { status = "Save failed: " + ex.Message; }
        }

        [Serializable] private class StudioProject { public string app; public int version; public System.Collections.Generic.List<StudioObject> objects = new System.Collections.Generic.List<StudioObject>(); }
        [Serializable] private class StudioObject { public string name; public float x,y,z,sx,sy,sz; }
    }
}
