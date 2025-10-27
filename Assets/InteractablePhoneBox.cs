using UnityEngine;

public class InteractablePhoneBox : MonoBehaviour
{
    [Header("State Objects")]
    public GameObject RingingState;
    public GameObject AnsweredState;

    [Header("Audio")]
    public AudioSource RingingLoop;
    public AudioSource VoiceLine;      // one-shot
    public AudioClip VoiceClip;        // optional override

    [Header("Highlight (emission)")]
    public Renderer[] HighlightRenderers;
    public Color HighlightColor = Color.white;
    [Range(0f, 5f)] public float EmissionStrength = 2f;

    bool answered;
    bool highlighted;
    MaterialPropertyBlock mpb;
    static readonly int EmissionID = Shader.PropertyToID("_EmissionColor");

    void Awake()
    {
        mpb = new MaterialPropertyBlock();
        SetAnswered(false, true);
        SetHighlighted(false);
        // Do NOT auto-play the ring here; cutscene will call StartRinging()
    }

    public void StartRinging()
    {
        if (answered) return;
        if (RingingState) RingingState.SetActive(true);
        if (AnsweredState) AnsweredState.SetActive(false);
        if (RingingLoop && !RingingLoop.isPlaying) RingingLoop.Play();
    }

    public void SetHighlighted(bool on)
    {
        if (highlighted == on) return;
        highlighted = on;

        if (HighlightRenderers == null) return;
        var col = on ? HighlightColor * Mathf.LinearToGammaSpace(EmissionStrength) : Color.black;

        foreach (var r in HighlightRenderers)
        {
            if (!r) continue;
            r.GetPropertyBlock(mpb);
            mpb.SetColor(EmissionID, col);
            r.SetPropertyBlock(mpb);
        }
    }

    public void Interact()
    {
        if (answered) return;
        SetAnswered(true, false);
        if (VoiceLine)
        {
            if (VoiceClip) VoiceLine.clip = VoiceClip;
            VoiceLine.Play();
        }
    }

    void SetAnswered(bool state, bool force)
    {
        if (!force && answered == state) return;
        answered = state;

        if (RingingState) RingingState.SetActive(!state);
        if (AnsweredState) AnsweredState.SetActive(state);

        if (RingingLoop)
        {
            if (state && RingingLoop.isPlaying) RingingLoop.Stop();
            if (!state && !RingingLoop.isPlaying) RingingLoop.Play();
        }
    }
}
