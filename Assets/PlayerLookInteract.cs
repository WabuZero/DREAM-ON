using UnityEngine;
using UnityEngine.UI;

public class PlayerLookInteract : MonoBehaviour
{
    public float interactDistance = 3.5f;
    public KeyCode interactKey = KeyCode.E;
    public LayerMask interactMask = ~0;   // set to Interactable layer if you make one
    public Image crosshair;               // optional

    InteractablePhoneBox current;

    void Update()
    {
        // Ray from camera forward
        var ray = new Ray(transform.position, transform.forward);
        var hitSomething = Physics.Raycast(ray, out RaycastHit hit, interactDistance, interactMask);

        var next = hitSomething ? hit.collider.GetComponentInParent<InteractablePhoneBox>() : null;

        if (current != next)
        {
            if (current) current.SetHighlighted(false);
            current = next;
            if (current) current.SetHighlighted(true);

            if (crosshair)
                crosshair.color = current ? Color.white : new Color(1, 1, 1, 0.5f);
        }

        if (current && Input.GetKeyDown(interactKey))
            current.Interact();
    }
}
