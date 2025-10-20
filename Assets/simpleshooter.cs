using UnityEngine;

public class SimpleShooter : MonoBehaviour
{
    public Camera cam;                // Assign your main camera here
    public float shootDistance = 100f;
    public ParticleSystem muzzleFlash; // Optional
    public LayerMask hitLayers;        // Choose which layers can be hit

    void Update()
    {
        if (Input.GetMouseButtonDown(0)) // Left click to shoot
        {
            Shoot();
        }
    }

    void Shoot()
    {
        if (muzzleFlash) muzzleFlash.Play();

        Ray ray = cam.ViewportPointToRay(new Vector3(0.5f, 0.5f, 0)); // Center of screen
        if (Physics.Raycast(ray, out RaycastHit hit, shootDistance, hitLayers))
        {
            Debug.Log("Hit: " + hit.collider.name);

            // Check if we hit a fish
            FishTarget fish = hit.collider.GetComponentInParent<FishTarget>();
            if (fish != null)
            {
                fish.OnShot(hit.point); // ✅ pass hit point to FishTarget
            }

            // Optional: Add bullet impact effect
            var impact = GameObject.CreatePrimitive(PrimitiveType.Sphere);
            impact.transform.position = hit.point;
            impact.transform.localScale = Vector3.one * 0.05f;
            Destroy(impact, 0.2f);
        }
    }
}
