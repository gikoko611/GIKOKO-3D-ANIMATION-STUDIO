using System;
using System.Collections.Generic;
using System.IO;
using UnityEngine;

namespace GIKOKO.Studio
{
    // Phone-first film-maker foundation. Kept separate from StudioBootstrap so
    // the existing Sculpt+ workspace remains intact.
    public class FilmMakerRuntime : MonoBehaviour
    {
        enum StudioTab { Scene, Character, Timeline, Audio, Export }
        enum Motion { Idle, Walk, Run, Talk, Fight }
        StudioTab tab = StudioTab.Scene;
        Motion motion = Motion.Idle;
        readonly List<GameObject> sceneObjects = new List<GameObject>();
        GameObject activeCharacter;
        Transform characterRoot;
        float playhead;
        float previewDuration = 12f;
        float projectDurationMinutes = 5f;
        float motionClock;
        bool previewPlaying;
        bool cartoonStyle = true;
        string status = "Film Maker ready • create a scene";
        string projectName = "Myanmar Animation Film";
        AudioSource audioSource;
        string dialogueText = "မင်္ဂလာပါ။ ကျွန်တော်တို့ရဲ့ ရွာလေးကို ကြိုဆိုပါတယ်။";
        string englishDialogueText = "Welcome to our beautiful village.";
        string subtitleMyanmar = "မင်္ဂလာပါ။ ကျွန်တော်တို့ရဲ့ ရွာလေးကို ကြိုဆိုပါတယ်။";
        string subtitleEnglish = "Welcome to our beautiful village.";
        bool showMyanmarSubtitle = true;
        bool ttsReady;
        AndroidJavaObject androidTts;
        GUIStyle heading, tiny, button;
        Camera sceneCamera;

        void Start()
        {
            Application.targetFrameRate = 30;
            audioSource = gameObject.AddComponent<AudioSource>();
            audioSource.playOnAwake = false;
            sceneCamera = Camera.main;
            if (sceneCamera == null && Camera.allCameras.Length > 0) sceneCamera = Camera.allCameras[0];
        }

        void Update()
        {
            if (!previewPlaying) return;
            motionClock += Time.deltaTime;
            playhead += Time.deltaTime;
            if (playhead >= previewDuration) playhead = 0f;
            AnimateCharacter();
        }

        void AnimateCharacter()
        {
            if (characterRoot == null) return;
            float phase = motionClock * (motion == Motion.Run ? 11f : 6f);
            Transform body = characterRoot.Find("Body");
            Transform leftLeg = characterRoot.Find("LeftLeg");
            Transform rightLeg = characterRoot.Find("RightLeg");
            Transform leftArm = characterRoot.Find("LeftArm");
            Transform rightArm = characterRoot.Find("RightArm");
            if (motion == Motion.Walk || motion == Motion.Run)
            {
                float swing = Mathf.Sin(phase) * (motion == Motion.Run ? 38f : 24f);
                if (leftLeg) leftLeg.localRotation = Quaternion.Euler(swing, 0, 0);
                if (rightLeg) rightLeg.localRotation = Quaternion.Euler(-swing, 0, 0);
                if (leftArm) leftArm.localRotation = Quaternion.Euler(-swing * .7f, 0, 0);
                if (rightArm) rightArm.localRotation = Quaternion.Euler(swing * .7f, 0, 0);
                characterRoot.position = new Vector3(Mathf.Sin(motionClock * .45f) * 1.4f, Mathf.Abs(Mathf.Sin(phase * 2f)) * .035f, 0);
            }
            else
            {
                if (leftLeg) leftLeg.localRotation = Quaternion.identity;
                if (rightLeg) rightLeg.localRotation = Quaternion.identity;
                if (leftArm) leftArm.localRotation = Quaternion.Euler(0, 0, motion == Motion.Talk ? Mathf.Sin(phase) * 12f : 0);
                if (rightArm) rightArm.localRotation = Quaternion.Euler(0, 0, motion == Motion.Fight ? -18f : 0);
                if (body && motion == Motion.Talk) body.localRotation = Quaternion.Euler(0, Mathf.Sin(phase) * 3f, 0);
            }
        }

        void OnGUI()
        {
            if (heading == null)
            {
                heading = new GUIStyle(GUI.skin.label) { fontSize = 13, fontStyle = FontStyle.Bold };
                tiny = new GUIStyle(GUI.skin.label) { fontSize = 10, wordWrap = true };
                button = new GUIStyle(GUI.skin.button) { fontSize = 10, wordWrap = true };
            }
            float top = 164f;
            float bottom = Screen.height - 146f;
            float h = Mathf.Max(88f, bottom - top);
            GUI.color = new Color(.025f, .065f, .085f, .96f);
            GUI.Box(new Rect(8, top, Screen.width - 16, h), GUIContent.none);
            GUI.color = new Color(.25f, 1f, .68f);
            GUI.Label(new Rect(16, top + 5, 180, 20), "FILM MAKER  /  " + tab.ToString().ToUpperInvariant(), heading);
            GUI.color = Color.white;
            string[] tabs = { "Scene", "Character", "Timeline", "Audio", "Export" };
            float tabW = (Screen.width - 36f) / 5f;
            for (int i = 0; i < tabs.Length; i++)
                if (GUI.Button(new Rect(14 + i * tabW, top + 27, tabW - 4, 25), tabs[i], button)) tab = (StudioTab)i;

            float y = top + 59;
            float w = (Screen.width - 40f) / 3f;
            if (tab == StudioTab.Scene)
            {
                GUI.Label(new Rect(16, y, Screen.width - 32, 18), "MYANMAR ENVIRONMENT • place reusable primitives", tiny); y += 20;
                AddButton("Ground", 0, y, w, () => AddGround());
                AddButton("Wood House", 1, y, w, () => AddHouse());
                AddButton("Pagoda", 2, y, w, () => AddPagoda());
                y += 29;
                AddButton("Tree", 0, y, w, () => AddTree());
                AddButton("Road", 1, y, w, () => AddRoad());
                AddButton("Clear Scene", 2, y, w, () => ClearScene());
            }
            else if (tab == StudioTab.Character)
            {
                GUI.Label(new Rect(16, y, Screen.width - 32, 18), "CHARACTER BLOCKOUT • stylized / realistic material", tiny); y += 20;
                AddButton("Create Human", 0, y, w, () => CreateCharacter());
                AddButton("Cartoon Style", 1, y, w, () => { cartoonStyle = true; status = "Cartoon style selected"; });
                AddButton("Realistic Style", 2, y, w, () => { cartoonStyle = false; status = "Realistic material style selected"; });
                y += 29;
                string[] moves = { "Idle", "Walk", "Run", "Talk", "Fight" };
                for (int i = 0; i < moves.Length; i++)
                {
                    int index = i;
                    AddButton(moves[i], i % 3, y + (i / 3) * 29, w, () => { Enum.TryParse(moves[index], out motion); status = "Motion preview: " + motion; AnimateCharacter(); });
                }
            }
            else if (tab == StudioTab.Timeline)
            {
                GUI.Label(new Rect(16, y, Screen.width - 32, 18), "SEQUENCE TIMELINE • project length", tiny); y += 20;
                if (GUI.Button(new Rect(14, y, w, 28), "5 Minutes", button)) projectDurationMinutes = 5;
                if (GUI.Button(new Rect(18 + w, y, w, 28), "10 Minutes", button)) projectDurationMinutes = 10;
                if (GUI.Button(new Rect(22 + 2 * w, y, w, 28), previewPlaying ? "Pause" : "Play Preview", button)) { previewPlaying = !previewPlaying; status = previewPlaying ? "Preview playing" : "Preview paused"; }
                y += 32;
                GUI.Label(new Rect(16, y, Screen.width - 32, 18), "Preview " + playhead.ToString("0.0") + "s / " + previewDuration.ToString("0") + "s  •  Film " + projectDurationMinutes.ToString("0") + " min", tiny);
                playhead = GUI.HorizontalSlider(new Rect(16, y + 20, Screen.width - 32, 18), playhead, 0, previewDuration);
                y += 39;
                AddButton("Idle Clip", 0, y, w, () => SetMotion(Motion.Idle));
                AddButton("Walk Clip", 1, y, w, () => SetMotion(Motion.Walk));
                AddButton("Talk Clip", 2, y, w, () => SetMotion(Motion.Talk));
            }
            else if (tab == StudioTab.Audio)
            {
                GUI.Label(new Rect(16, y, Screen.width - 32, 18), "VOICE • SOUND FX • SUBTITLES", tiny); y += 20;
                GUI.Label(new Rect(16, y, 55, 20), "Dialogue", tiny);
                dialogueText = GUI.TextField(new Rect(72, y, Screen.width - 90, 23), dialogueText);
                y += 25;
                GUI.Label(new Rect(16, y, 55, 20), "English", tiny);
                englishDialogueText = GUI.TextField(new Rect(72, y, Screen.width - 90, 23), englishDialogueText);
                y += 27;
                AddButton("Speak Myanmar", 0, y, w, () => SpeakAndroidTts(dialogueText, "my", "MM"));
                AddButton("Speak English", 1, y, w, () => SpeakAndroidTts(englishDialogueText, "en", "US"));
                AddButton("Stop Voice", 2, y, w, () => StopTts());
                y += 29;
                AddButton("Footsteps", 0, y, w, () => PlayGeneratedSound("footsteps"));
                AddButton("Rain", 1, y, w, () => PlayGeneratedSound("rain"));
                AddButton("Fight FX", 2, y, w, () => PlayGeneratedSound("fight"));
                y += 29;
                AddButton("Wind", 0, y, w, () => PlayGeneratedSound("wind"));
                AddButton("Ambient Music", 1, y, w, () => PlayGeneratedSound("music"));
                AddButton("Stop Audio", 2, y, w, () => { if (audioSource) audioSource.Stop(); status = "Audio stopped"; });
                AddButton(showMyanmarSubtitle ? "Subtitle: Myanmar" : "Subtitle: English", 2, y, w, () => { showMyanmarSubtitle = !showMyanmarSubtitle; status = "Subtitle language changed"; });
                y += 29;
                GUI.Label(new Rect(16, y, Screen.width - 32, 30), "MY: " + subtitleMyanmar, tiny); y += 28;
                GUI.Label(new Rect(16, y, Screen.width - 32, 30), "EN: " + subtitleEnglish, tiny);
            }
            else
            {
                GUI.Label(new Rect(16, y, Screen.width - 32, 30), "EXPORT PLAN • scene chunks → encode → merge", tiny); y += 32;
                GUI.Label(new Rect(16, y, Screen.width - 32, 34), "Target: " + projectDurationMinutes.ToString("0") + " min  |  480p / 720p  |  24 / 30 fps  |  MP4 H.264", tiny); y += 36;
                AddButton("Save Project", 0, y, w, () => SaveFilmProject());
                AddButton("Preview Camera", 1, y, w, () => FrameCamera());
                AddButton("Render Status", 2, y, w, () => status = "Runtime MP4 encoder is a next-stage module; no fake export is shown.");
            }
            GUI.color = new Color(.65f, .85f, .9f);
            GUI.Label(new Rect(16, top + h - 18, Screen.width - 32, 16), status, tiny);
            if (showMyanmarSubtitle) GUI.Label(new Rect(12, Screen.height - 139, Screen.width - 24, 28), subtitleMyanmar, heading);
            else GUI.Label(new Rect(12, Screen.height - 139, Screen.width - 24, 28), subtitleEnglish, heading);
            GUI.color = Color.white;
        }


        void PlayGeneratedSound(string kind)
        {
            if (!audioSource) audioSource = gameObject.AddComponent<AudioSource>();
            int rate = 22050;
            int seconds = kind == "music" ? 8 : (kind == "rain" ? 5 : 2);
            int count = rate * seconds;
            float[] samples = new float[count];
            System.Random rng = new System.Random(kind.GetHashCode());
            float phase = 0f;
            for (int i = 0; i < count; i++)
            {
                float t = (float)i / rate;
                float noise = (float)(rng.NextDouble() * 2.0 - 1.0);
                float value;
                if (kind == "footsteps") value = Mathf.Pow(Mathf.Max(0f, Mathf.Sin(t * Mathf.PI * 3f)), 12f) * noise * .55f;
                else if (kind == "rain") value = noise * .13f + Mathf.Sin(t * 83f) * .025f;
                else if (kind == "wind") value = noise * .08f + Mathf.Sin(t * 1.8f) * .12f;
                else if (kind == "fight") { float env = Mathf.Exp(-t * 2.5f); value = noise * env * .6f + Mathf.Sin(t * 95f) * env * .2f; }
                else { float[] notes = { 110f, 138.59f, 164.81f, 220f }; float note = notes[Mathf.FloorToInt(t * .5f) % notes.Length]; phase += 2f * Mathf.PI * note / rate; value = (Mathf.Sin(phase) + .35f * Mathf.Sin(phase * 2f)) * .10f; }
                float fade = kind == "music" || kind == "rain" || kind == "wind" ? 1f : Mathf.Clamp01((seconds - t) * 3f);
                samples[i] = Mathf.Clamp(value * fade, -.8f, .8f);
            }
            AudioClip clip = AudioClip.Create("GIKOKO_" + kind, count, 1, rate, false);
            clip.SetData(samples, 0);
            audioSource.Stop(); audioSource.clip = clip;
            audioSource.loop = kind == "music" || kind == "rain" || kind == "wind";
            audioSource.Play(); status = "Generated local audio: " + kind;
        }

        void SpeakAndroidTts(string text, string language, string country)
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            try
            {
                if (androidTts == null)
                {
                    using (var unityPlayer = new AndroidJavaClass("com.unity3d.player.UnityPlayer"))
                    using (var activity = unityPlayer.GetStatic<AndroidJavaObject>("currentActivity"))
                        androidTts = new AndroidJavaObject("android.speech.tts.TextToSpeech", activity, new TtsInitListener(this));
                }
                if (!ttsReady) { status = "Android TTS initializing; tap Speak again shortly"; return; }
                using (var locale = new AndroidJavaObject("java.util.Locale", language, country))
                using (var bundle = new AndroidJavaObject("android.os.Bundle"))
                {
                    int result = androidTts.Call<int>("setLanguage", locale);
                    if (result < 0) { status = "Voice pack unavailable: " + language + "-" + country; return; }
                    androidTts.Call<int>("speak", text, 0, bundle, "gikoko_dialogue");
                    status = "Speaking with Android system TTS • " + language;
                }
            }
            catch (Exception e) { status = "TTS unavailable: " + e.Message; }
#else
            status = "Android system TTS is available in the APK";
#endif
        }

        void StopTts()
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            try { if (androidTts != null) androidTts.Call<int>("stop"); } catch { }
#endif
            status = "Voice-over stopped";
        }

        class TtsInitListener : AndroidJavaProxy
        {
            readonly FilmMakerRuntime owner;
            public TtsInitListener(FilmMakerRuntime runtime) : base("android.speech.tts.TextToSpeech$OnInitListener") { owner = runtime; }
            void onInit(int statusCode) { owner.ttsReady = statusCode == 0; owner.status = owner.ttsReady ? "Android TTS ready" : "Android TTS initialization failed"; }
        }

        void OnDestroy()
        {
#if UNITY_ANDROID && !UNITY_EDITOR
            try { if (androidTts != null) { androidTts.Call<int>("stop"); androidTts.Call("shutdown"); androidTts.Dispose(); } } catch { }
#endif
        }

        void AddButton(string label, int column, float y, float width, Action action)
        {
            if (GUI.Button(new Rect(14 + column * (width + 4), y, width, 25), label, button)) action();
        }

        GameObject MakePrimitive(PrimitiveType type, string label, Vector3 position, Vector3 scale, Color color)
        {
            var go = GameObject.CreatePrimitive(type);
            go.name = label; go.transform.position = position; go.transform.localScale = scale;
            var renderer = go.GetComponent<Renderer>();
            var mat = new Material(Shader.Find("Standard"));
            mat.color = color; mat.SetFloat("_Glossiness", .25f);
            renderer.sharedMaterial = mat;
            sceneObjects.Add(go);
            return go;
        }

        void AddGround()
        {
            MakePrimitive(PrimitiveType.Cube, "Myanmar Village Ground", new Vector3(0, -.18f, 0), new Vector3(18, .3f, 18), new Color(.30f, .39f, .22f));
            status = "Village ground added";
        }
        void AddHouse()
        {
            var wall = MakePrimitive(PrimitiveType.Cube, "Myanmar Teak House", new Vector3(2, 1, 1), new Vector3(3, 2, 2.5f), new Color(.42f, .22f, .10f));
            MakePrimitive(PrimitiveType.Cube, "Teak Roof Left", new Vector3(2, 2.25f, .35f), new Vector3(3.5f, .18f, 1.55f), new Color(.22f, .12f, .09f)).transform.rotation = Quaternion.Euler(0, 0, 18);
            MakePrimitive(PrimitiveType.Cube, "Teak Roof Right", new Vector3(2, 2.25f, 1.65f), new Vector3(3.5f, .18f, 1.55f), new Color(.22f, .12f, .09f)).transform.rotation = Quaternion.Euler(0, 0, -18);
            status = "Myanmar wooden house blockout added";
        }
        void AddPagoda()
        {
            MakePrimitive(PrimitiveType.Cylinder, "Pagoda Base", new Vector3(-3, .18f, 1), new Vector3(2.4f, .35f, 2.4f), new Color(.78f, .62f, .25f));
            MakePrimitive(PrimitiveType.Cylinder, "Pagoda Bell", new Vector3(-3, 1.1f, 1), new Vector3(1.25f, 1.55f, 1.25f), new Color(.82f, .68f, .34f));
            MakePrimitive(PrimitiveType.Sphere, "Pagoda Hti", new Vector3(-3, 2.25f, 1), new Vector3(.45f, .7f, .45f), new Color(.95f, .78f, .3f));
            status = "Myanmar pagoda blockout added";
        }
        void AddTree()
        {
            MakePrimitive(PrimitiveType.Cylinder, "Tree Trunk", new Vector3(4, .8f, -2), new Vector3(.28f, 1.6f, .28f), new Color(.25f, .13f, .07f));
            MakePrimitive(PrimitiveType.Sphere, "Tree Canopy", new Vector3(4, 2.1f, -2), new Vector3(1.5f, 1.6f, 1.5f), new Color(.13f, .38f, .18f));
            status = "Tree prop added";
        }
        void AddRoad()
        {
            MakePrimitive(PrimitiveType.Cube, "Village Road", new Vector3(0, .01f, -4), new Vector3(16, .08f, 1.8f), new Color(.28f, .25f, .20f));
            status = "Village road added";
        }
        void ClearScene()
        {
            for (int i = sceneObjects.Count - 1; i >= 0; i--) if (sceneObjects[i]) Destroy(sceneObjects[i]);
            sceneObjects.Clear(); status = "Film scene props cleared";
        }

        void CreateCharacter()
        {
            if (activeCharacter) Destroy(activeCharacter);
            activeCharacter = new GameObject("GIKOKO Character Blockout");
            characterRoot = activeCharacter.transform;
            Color skin = new Color(.65f, .42f, .28f);
            Color cloth = cartoonStyle ? new Color(.08f, .55f, .38f) : new Color(.35f, .25f, .16f);
            MakePart("Body", PrimitiveType.Capsule, new Vector3(0, 1.15f, 0), new Vector3(.55f, .72f, .35f), cloth);
            MakePart("Head", PrimitiveType.Sphere, new Vector3(0, 2.12f, 0), new Vector3(.48f, .48f, .44f), skin);
            MakePart("LeftLeg", PrimitiveType.Capsule, new Vector3(-.18f, .42f, 0), new Vector3(.19f, .48f, .2f), new Color(.12f,.13f,.16f));
            MakePart("RightLeg", PrimitiveType.Capsule, new Vector3(.18f, .42f, 0), new Vector3(.19f, .48f, .2f), new Color(.12f,.13f,.16f));
            MakePart("LeftArm", PrimitiveType.Capsule, new Vector3(-.43f, 1.25f, 0), new Vector3(.15f, .52f, .16f), cloth);
            MakePart("RightArm", PrimitiveType.Capsule, new Vector3(.43f, 1.25f, 0), new Vector3(.15f, .52f, .16f), cloth);
            status = "Character blockout created • procedural motion clips";
        }
        void MakePart(string name, PrimitiveType type, Vector3 pos, Vector3 scale, Color color)
        {
            var part = GameObject.CreatePrimitive(type);
            part.name = name; part.transform.SetParent(characterRoot, false);
            part.transform.localPosition = pos; part.transform.localScale = scale;
            var mat = new Material(Shader.Find("Standard")); mat.color = color;
            part.GetComponent<Renderer>().sharedMaterial = mat;
            var collider = part.GetComponent<Collider>(); if (collider) Destroy(collider);
        }
        void SetMotion(Motion next) { motion = next; status = "Timeline clip: " + next; AnimateCharacter(); }
        void FrameCamera()
        {
            if (sceneCamera == null) return;
            sceneCamera.transform.position = new Vector3(7, 6, -10);
            sceneCamera.transform.LookAt(new Vector3(0, 1, 0));
            status = "Camera framed on film scene";
        }
        void SaveFilmProject()
        {
            try
            {
                var data = new FilmSave();
                data.projectName = projectName;
                data.durationMinutes = projectDurationMinutes;
                data.previewDurationSeconds = previewDuration;
                data.motion = motion.ToString();
                data.objects = new string[sceneObjects.Count];
                for (int i = 0; i < sceneObjects.Count; i++) data.objects[i] = sceneObjects[i] ? sceneObjects[i].name : "missing";
                string path = Path.Combine(Application.persistentDataPath, "gi_koko_film_project.json");
                File.WriteAllText(path, JsonUtility.ToJson(data, true));
                status = "Film project saved locally";
            }
            catch (Exception e) { status = "Save error: " + e.Message; }
        }
        [Serializable] class FilmSave
        {
            public string projectName;
            public float durationMinutes;
            public float previewDurationSeconds;
            public string motion;
            public string[] objects;
        }
    }
}
