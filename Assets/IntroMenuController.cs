
using UnityEngine;
using UnityEngine.UI;
using TMPro;
using System.Collections;

public class IntroMenuController : MonoBehaviour
{
    [Header("References")]
    [SerializeField] private TextMeshProUGUI titleText;
    [SerializeField] private TextMeshProUGUI continuePromptText;
    [SerializeField] private CanvasGroup titleGroup;
    [SerializeField] private CanvasGroup buttonGroup;
    [SerializeField] private Button continueButton;
    [SerializeField] private AudioSource audioSource;

    [Header("Config")]
    [SerializeField] private TMP_FontAsset titleFont;
    [SerializeField] private string titleOverride;
    [SerializeField] private string continuePrompt = "Press Space";

    [Header("Timings")]
    [Min(0f)] public float titleFadeInDuration = 1.25f;
    [Min(0f)] public float buttonFadeInDelay = 0.35f;
    [Min(0f)] public float buttonFadeInDuration = 0.85f;
    [Min(0f)] public float fadeOutDuration = 0.85f;
    [Tooltip("Use unscaled time so fades work even when Time.timeScale == 0 (recommended for menus).")]
    public bool useUnscaledTime = true;

    [Header("Pulse Prompt")]
    public bool pulsePrompt = true;
    [Min(0.1f)] public float pulseDuration = 1.5f;
    [Range(0f,1f)] public float pulseMinAlpha = 0.25f;
    [Range(0f,1f)] public float pulseMaxAlpha = 1f;

    [Header("Behavior")]
    [Tooltip("Only Spacebar advances. If false, Enter/Return advances.")]
    public bool spaceToContinue = true;
    [Tooltip("If true, Space is only accepted after the prompt has completed its initial fade-in.")]
    public bool requirePromptLoaded = true;
    public GameObject enableAfterFadeOut;
    public bool disableMenuAfterFadeOut = true;
    public bool autoStart = true;

    [Header("Audio")]
    public AudioClip clickSfx;
    [Range(0f, 1f)] public float clickVolume = 1f;

    [Header("Debug")]
    public bool debugLogs = false;

    private bool _canContinue = false;
    private bool _sequenceFinished = false;
    private bool _promptLoaded = false; // becomes true after initial button fade-in completes
    private Coroutine _pulseRoutine;
    private Coroutine _sequenceRoutine;

    private void Awake()
    {
        if (!audioSource && clickSfx)
        {
            audioSource = gameObject.AddComponent<AudioSource>();
            audioSource.playOnAwake = false;
        }
    }

    private void Start()
    {
        if (titleText && titleFont) titleText.font = titleFont;
        if (titleText && !string.IsNullOrEmpty(titleOverride)) titleText.text = titleOverride;
        if (continuePromptText) continuePromptText.text = continuePrompt;

        if (!titleGroup && titleText) titleGroup = titleText.GetComponent<CanvasGroup>();
        if (!buttonGroup && continuePromptText) buttonGroup = continuePromptText.GetComponent<CanvasGroup>();

        if (titleGroup) { titleGroup.alpha = 0f; titleGroup.interactable = false; titleGroup.blocksRaycasts = false; }
        if (buttonGroup) { buttonGroup.alpha = 0f; buttonGroup.interactable = false; buttonGroup.blocksRaycasts = false; }

        if (continueButton)
        {
            continueButton.onClick.RemoveAllListeners();
            continueButton.onClick.AddListener(OnContinuePressed);
            continueButton.interactable = false;
        }

        if (autoStart) StartSequence();
    }

    private void Update()
    {
        if (!_canContinue || _sequenceFinished) return;

        bool keyPressed = false;
        if (spaceToContinue) keyPressed = Input.GetKeyDown(KeyCode.Space);
        else keyPressed = Input.GetKeyDown(KeyCode.Return) || Input.GetKeyDown(KeyCode.KeypadEnter);

        if (keyPressed)
        {
            if (!requirePromptLoaded || _promptLoaded)
            {
                if (debugLogs) Debug.Log("[IntroMenuController] Continue input accepted.");
                OnContinuePressed();
            }
            else
            {
                if (debugLogs) Debug.Log("[IntroMenuController] Continue input ignored (prompt not loaded yet).");
            }
        }
    }

    public void StartSequence()
    {
        if (_pulseRoutine != null) { StopCoroutine(_pulseRoutine); _pulseRoutine = null; }
        if (_sequenceRoutine != null) { StopCoroutine(_sequenceRoutine); _sequenceRoutine = null; }
        StopAllCoroutines();

        _canContinue = false;
        _sequenceFinished = false;
        _promptLoaded = false;

        if (titleGroup) { titleGroup.alpha = 0f; titleGroup.interactable = false; titleGroup.blocksRaycasts = false; }
        if (buttonGroup) { buttonGroup.alpha = 0f; buttonGroup.interactable = false; buttonGroup.blocksRaycasts = false; }
        if (continueButton) continueButton.interactable = false;

        _sequenceRoutine = StartCoroutine(RunSequence());
    }

    private IEnumerator RunSequence()
    {
        // Title fade-in
        if (titleGroup)
        {
            yield return FadeCanvasGroup(titleGroup, 0f, 1f, titleFadeInDuration, useUnscaledTime);
        }

        // Delay before showing prompt
        if (buttonFadeInDelay > 0f)
        {
            if (useUnscaledTime) yield return new WaitForSecondsRealtime(buttonFadeInDelay);
            else yield return new WaitForSeconds(buttonFadeInDelay);
        }

        // Prompt fade-in
        if (buttonGroup)
        {
            yield return FadeCanvasGroup(buttonGroup, 0f, 1f, buttonFadeInDuration, useUnscaledTime);

            // Mark prompt as loaded ONCE after initial fade-in completes
            _promptLoaded = true;

            buttonGroup.interactable = true;
            buttonGroup.blocksRaycasts = true;
        }

        if (continueButton) continueButton.interactable = true;
        _canContinue = true;

        // Start pulsing loop (runs until press)
        if (pulsePrompt && buttonGroup)
            _pulseRoutine = StartCoroutine(PulsePrompt());
    }

    private IEnumerator PulsePrompt()
    {
        float t = 0f;
        while (_canContinue && !_sequenceFinished)
        {
            float dt = useUnscaledTime ? Time.unscaledDeltaTime : Time.deltaTime;
            t += dt * (1f / Mathf.Max(pulseDuration, 0.0001f)) * 2f; // full in+out ≈ duration
            float s = Mathf.PingPong(t, 1f);
            float targetAlpha = Mathf.Lerp(pulseMinAlpha, pulseMaxAlpha, s);
            buttonGroup.alpha = targetAlpha;
            yield return null;
        }
    }

    public void OnContinuePressed()
    {
        if (!_canContinue || _sequenceFinished) return;

        _canContinue = false;
        if (_pulseRoutine != null) { StopCoroutine(_pulseRoutine); _pulseRoutine = null; }

        PlayClick();
        StartCoroutine(FadeOutThenEnableTarget());
    }

    private IEnumerator FadeOutThenEnableTarget()
    {
        _sequenceFinished = true;

        float t = 0f;
        float startTitle = titleGroup ? titleGroup.alpha : 0f;
        float startButton = buttonGroup ? buttonGroup.alpha : 0f;

        while (t < fadeOutDuration)
        {
            float dt = useUnscaledTime ? Time.unscaledDeltaTime : Time.deltaTime;
            t += dt;
            float k = (fadeOutDuration <= 0f) ? 1f : Mathf.Clamp01(t / fadeOutDuration);

            if (titleGroup) titleGroup.alpha = Mathf.Lerp(startTitle, 0f, k);
            if (buttonGroup) buttonGroup.alpha = Mathf.Lerp(startButton, 0f, k);

            yield return null;
        }

        if (titleGroup) { titleGroup.alpha = 0f; titleGroup.interactable = false; titleGroup.blocksRaycasts = false; }
        if (buttonGroup) { buttonGroup.alpha = 0f; buttonGroup.interactable = false; buttonGroup.blocksRaycasts = false; }
        if (continueButton) continueButton.interactable = false;

        if (enableAfterFadeOut) enableAfterFadeOut.SetActive(true);

        if (disableMenuAfterFadeOut) gameObject.SetActive(false);
    }

    private void PlayClick()
    {
        if (!clickSfx) return;

        if (!audioSource)
        {
            AudioSource.PlayClipAtPoint(clickSfx, Camera.main ? Camera.main.transform.position : Vector3.zero, clickVolume);
            return;
        }

        audioSource.PlayOneShot(clickSfx, clickVolume);
    }

    private static IEnumerator FadeCanvasGroup(CanvasGroup group, float from, float to, float duration, bool unscaled)
    {
        if (!group) yield break;

        if (duration <= 0f)
        {
            group.alpha = to;
            yield break;
        }

        float t = 0f;
        group.alpha = from;
        while (t < duration)
        {
            float dt = unscaled ? Time.unscaledDeltaTime : Time.deltaTime;
            t += dt;
            group.alpha = Mathf.Lerp(from, to, Mathf.Clamp01(t / duration));
            yield return null;
        }
        group.alpha = to;
    }

#if UNITY_EDITOR
    private void OnValidate()
    {
        if (continuePromptText && !Application.isPlaying)
            continuePromptText.text = continuePrompt;
        if (titleText && titleFont && !Application.isPlaying)
            titleText.font = titleFont;
        if (titleText && !string.IsNullOrEmpty(titleOverride) && !Application.isPlaying)
            titleText.text = titleOverride;

        pulseMinAlpha = Mathf.Clamp01(pulseMinAlpha);
        pulseMaxAlpha = Mathf.Clamp01(pulseMaxAlpha);
        if (pulseMaxAlpha < pulseMinAlpha) pulseMaxAlpha = pulseMinAlpha;
    }
#endif
}
