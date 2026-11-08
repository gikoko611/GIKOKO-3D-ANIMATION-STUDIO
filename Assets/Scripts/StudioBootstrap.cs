using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace GIKOKO.Studio
{
    public class StudioBootstrap : MonoBehaviour
    {
        enum Brush { Standard, Clay, Smooth, Inflate, Move, Flatten, Crease, Mask }
        GameObject sculptObject;
        Mesh sculptMesh;
        Camera cam;
        Brush brush = Brush.Standard;
        float radius = 0.42f, strength = 0.22f, distance = 5.2f, yaw = 25f, pitch = 12f;
        Vector2 lastPointer;
        bool pointerWasDown;
        string status = "Ready • Sculpt workspace";
        int meshResolution = 28;
        Color sculptColor = new Color(.63f,.39f,.25f);
        readonly HashSet<int> masked = new HashSet<int>();
        GUIStyle titleStyle, smallStyle, toolStyle, activeToolStyle;

        void Start()
        {
            Application.targetFrameRate = 30;
            QualitySettings.vSyncCount = 0;
            QualitySettings.antiAliasing = 0;
            QualitySettings.shadows = ShadowQuality.HardOnly;
            RenderSettings.ambientLight = new Color(.38f,.40f,.44f);
            var c = new GameObject("Sculpt Camera");
            cam = c.AddComponent<Camera>();
            cam.clearFlags = CameraClearFlags.SolidColor;
            cam.backgroundColor = new Color(.035f,.045f,.065f);
            cam.fieldOfView = 42;
            var lightObj = new GameObject("Sculpt Key Light");
            var light = lightObj.AddComponent<Light>();
            light.type = LightType.Directional; light.intensity = 1.25f;
            lightObj.transform.rotation = Quaternion.Euler(42,-28,0);
            var fillObj = new GameObject("Sculpt Fill Light");
            var fill = fillObj.AddComponent<Light>();
            fill.type = LightType.Directional; fill.intensity = .45f;
            fillObj.transform.rotation = Quaternion.Euler(20,145,0);
            CreateSculptSphere();
            UpdateCamera();
        }

        void CreateSculptSphere()
        {
            if (sculptObject) Destroy(sculptObject);
            sculptObject = new GameObject("Sculpt Mesh");
            var filter = sculptObject.AddComponent<MeshFilter>();
            var renderer = sculptObject.AddComponent<MeshRenderer>();
            sculptMesh = BuildSphere(meshResolution, meshResolution * 2);
            filter.sharedMesh = sculptMesh;
            var mat = new Material(Shader.Find("Standard"));
            mat.color = sculptColor; mat.SetFloat("_Metallic", .08f); mat.SetFloat("_Glossiness", .34f);
            renderer.sharedMaterial = mat;
            sculptObject.AddComponent<MeshCollider>().sharedMesh = sculptMesh;
            masked.Clear();
            status = "New sculpt • UV sphere";
        }

        Mesh BuildSphere(int lat, int lon)
        {
            var vertices = new List<Vector3>(); var uv = new List<Vector2>(); var triangles = new List<int>();
            for(int y=0;y<=lat;y++) {
                float v=(float)y/lat, phi=v*Mathf.PI;
                for(int x=0;x<=lon;x++) {
                    float u=(float)x/lon, theta=u*Mathf.PI*2;
                    vertices.Add(new Vector3(Mathf.Sin(phi)*Mathf.Cos(theta),Mathf.Cos(phi),Mathf.Sin(phi)*Mathf.Sin(theta)));
                    uv.Add(new Vector2(u,v));
                }
            }
            for(int y=0;y<lat;y++) for(int x=0;x<lon;x++) {
                int i=y*(lon+1)+x, n=i+lon+1;
                triangles.Add(i); triangles.Add(n); triangles.Add(i+1);
                triangles.Add(i+1); triangles.Add(n); triangles.Add(n+1);
            }
            var m=new Mesh(); m.indexFormat=vertices.Count>65000?UnityEngine.Rendering.IndexFormat.UInt32:UnityEngine.Rendering.IndexFormat.UInt16;
            m.SetVertices(vertices); m.SetUVs(0,uv); m.SetTriangles(triangles,0); m.RecalculateNormals(); m.RecalculateBounds(); return m;
        }

        void UpdateCamera()
        {
            if (!cam) return;
            var rot=Quaternion.Euler(pitch,yaw,0);
            cam.transform.position=rot*new Vector3(0,0,-distance);
            cam.transform.rotation=rot;
        }

        void Update()
        {
            if (Input.touchCount>0) {
                var t=Input.GetTouch(0);
                if(t.phase==TouchPhase.Began){lastPointer=t.position;pointerWasDown=true;}
                else if(t.phase==TouchPhase.Moved && pointerWasDown){
                    if(t.position.y>Screen.height*.25f && t.position.x<Screen.width*.82f) SculptAt(t.position);
                    else { yaw+=t.deltaPosition.x*.22f; pitch=Mathf.Clamp(pitch-t.deltaPosition.y*.18f,-75,75); UpdateCamera(); }
                    lastPointer=t.position;
                }
                else if(t.phase==TouchPhase.Ended || t.phase==TouchPhase.Canceled) pointerWasDown=false;
                if(Input.touchCount==2){float d=Vector2.Distance(Input.GetTouch(0).position,Input.GetTouch(1).position); distance=Mathf.Clamp(distance-d*.002f,2.2f,10f);UpdateCamera();}
            } else if(Input.GetMouseButton(0) && Input.mousePosition.y>Screen.height*.25f) SculptAt(Input.mousePosition);
            if(Input.GetMouseButtonDown(1)){lastPointer=Input.mousePosition;}
            if(Input.GetMouseButton(1)){var d=(Vector2)Input.mousePosition-lastPointer;yaw+=d.x*.2f;pitch=Mathf.Clamp(pitch-d.y*.15f,-75,75);lastPointer=Input.mousePosition;UpdateCamera();}
            if(Input.mouseScrollDelta.y!=0){distance=Mathf.Clamp(distance-Input.mouseScrollDelta.y*.35f,2.2f,10f);UpdateCamera();}
        }

        void SculptAt(Vector2 screen)
        {
            if(!cam || !sculptObject) return;
            var ray=cam.ScreenPointToRay(screen);
            if(Physics.Raycast(ray,out var hit,30f)) ApplyBrush(hit.point,hit.normal);
        }

        void ApplyBrush(Vector3 worldPoint, Vector3 worldNormal)
        {
            var verts=sculptMesh.vertices; var normals=sculptMesh.normals;
            Vector3 local= sculptObject.transform.InverseTransformPoint(worldPoint);
            Vector3 localNormal=sculptObject.transform.InverseTransformDirection(worldNormal).normalized;
            float r=Mathf.Max(.035f,radius);
            for(int i=0;i<verts.Length;i++){
                float d=Vector3.Distance(verts[i],local); if(d>r || masked.Contains(i)) continue;
                float fall=1f-d/r; fall=fall*fall*(3f-2f*fall);
                switch(brush){
                    case Brush.Standard: case Brush.Clay: verts[i]+=localNormal*(strength*fall*.35f); break;
                    case Brush.Inflate: verts[i]+=verts[i].normalized*(strength*fall*.35f); break;
                    case Brush.Move: verts[i]+=localNormal*(strength*fall*.8f); break;
                    case Brush.Flatten: verts[i]=Vector3.Lerp(verts[i],local+localNormal*.02f,fall*strength); break;
                    case Brush.Crease: verts[i]-=localNormal*(strength*fall*.25f); break;
                    case Brush.Smooth:
                        Vector3 avg=Vector3.zero; int count=0;
                        for(int j=0;j<verts.Length;j++) if(Vector3.Distance(verts[i],verts[j])<.12f){avg+=verts[j];count++;}
                        if(count>0) verts[i]=Vector3.Lerp(verts[i],avg/count,fall*.35f);
                        break;
                    case Brush.Mask: masked.Add(i); break;
                }
            }
            sculptMesh.vertices=verts; sculptMesh.RecalculateNormals(); sculptMesh.RecalculateBounds();
            var col=sculptObject.GetComponent<MeshCollider>(); col.sharedMesh=null; col.sharedMesh=sculptMesh;
            status=brush+" • radius "+radius.ToString("0.00");
        }

        void OnGUI()
        {
            if(titleStyle==null){
                titleStyle=new GUIStyle(GUI.skin.label){fontSize=18,fontStyle=FontStyle.Bold};
                smallStyle=new GUIStyle(GUI.skin.label){fontSize=11};
                toolStyle=new GUIStyle(GUI.skin.button){fontSize=11,wordWrap=true};
                activeToolStyle=new GUIStyle(toolStyle){fontStyle=FontStyle.Bold};
            }
            GUI.color=new Color(.025f,.045f,.065f,.96f); GUI.Box(new Rect(0,0,Screen.width,76),GUIContent.none);
            GUI.color=new Color(.25f,1f,.68f); GUI.Label(new Rect(14,8,Screen.width-28,28),"G.I KO KO  /  SCULPT+",titleStyle);
            GUI.color=Color.white; GUI.Label(new Rect(16,39,Screen.width-32,22),"MODELING WORKSPACE  •  "+status,smallStyle);
            float top=84, bw=Mathf.Min(76,(Screen.width-36)/4f);
            GUI.color=new Color(.05f,.09f,.13f,.96f); GUI.Box(new Rect(8,top,Screen.width-16,74),GUIContent.none);
            GUI.color=Color.white;
            string[] names={"Sphere","Cube","Head","Save"};
            for(int i=0;i<4;i++) if(GUI.Button(new Rect(14+i*(bw+4),top+9,bw,52),names[i],toolStyle)){
                if(i==0)CreateSculptSphere(); if(i==1)CreatePrimitive(PrimitiveType.Cube); if(i==2){CreateSculptSphere();status="Head base • sculpt facial forms";} if(i==3)SaveProject();
            }
            float panelH=128, y=Screen.height-panelH-8;
            GUI.color=new Color(.025f,.045f,.065f,.97f); GUI.Box(new Rect(8,y,Screen.width-16,panelH),GUIContent.none);
            GUI.color=new Color(.25f,1f,.68f); GUI.Label(new Rect(16,y+6,200,20),"SCULPT BRUSHES",smallStyle);
            string[] tools={"Standard","Clay","Smooth","Inflate","Move","Flatten","Crease","Mask"};
            float tw=(Screen.width-36)/4f;
            for(int i=0;i<tools.Length;i++){
                bool active=brush.ToString()==tools[i];
                GUI.color=active?new Color(.12f,.72f,.48f):Color.white;
                if(GUI.Button(new Rect(14+(i%4)*tw,y+27+(i/4)*34,tw-4,30),tools[i],active?activeToolStyle:toolStyle)) Enum.TryParse(tools[i],out brush);
            }
            GUI.color=Color.white;
            GUI.Label(new Rect(16,y+99,62,22),"Size",smallStyle);
            radius=GUI.HorizontalSlider(new Rect(62,y+106,Screen.width*.30f,18),radius,.08f,1.0f);
            GUI.Label(new Rect(Screen.width*.39f,y+99,70,22),"Strength",smallStyle);
            strength=GUI.HorizontalSlider(new Rect(Screen.width*.57f,y+106,Screen.width*.30f,18),strength,.02f,.8f);
        }

        void CreatePrimitive(PrimitiveType type)
        {
            var go=GameObject.CreatePrimitive(type); go.name=type+" Sculpt Base"; go.transform.position=Vector3.zero;
            var mat=new Material(Shader.Find("Standard"));mat.color=sculptColor;go.GetComponent<Renderer>().material=mat;
            if(sculptObject)Destroy(sculptObject);sculptObject=go;sculptMesh=go.GetComponent<MeshFilter>().mesh;masked.Clear();
            status="Primitive base • "+type;
        }

        void SaveProject()
        {
            try{
                var m=sculptMesh; var data=new SculptSave{label="G.I KO KO Sculpt Project",vertices=m.vertices,triangles=m.triangles};
                string path=Path.Combine(Application.persistentDataPath,"gi_koko_sculpt_project.json");
                File.WriteAllText(path,JsonUtility.ToJson(data));status="Saved • "+Path.GetFileName(path);
            }catch(Exception e){status="Save error: "+e.Message;}
        }
        [Serializable] class SculptSave{public string label;public Vector3[] vertices;public int[] triangles;}
    }
}