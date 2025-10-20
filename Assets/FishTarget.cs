using UnityEngine;

public class FishTarget : MonoBehaviour
{
    [Header("References")]
    public ParticleSystem bloodVFX;  // assign your blood prefab
    public MonoBehaviour pathFollower; // assign spline/path component if any
    public Collider mainCollider; // drag root collider here
    public Rigidbody mainRigidbody; // drag root rigidbody here

    bool dead;

    public void OnShot(Vector3 hitPoint)
    {
        if (dead) return;
        dead = true;

        // 1. Stop path movement
        if (pathFollower != null) pathFollower.enabled = false;

        // 2. Disable collider to prevent double-hits
        if (mainCollider != null) mainCollider.enabled = false;

        // 3. Play blood effect at hit point
        if (bloodVFX != null)
        {
            var vfx = Instantiate(bloodVFX, hitPoint, Quaternion.identity);
            vfx.Play();
            Destroy(vfx.gameObject, vfx.main.duration + 0.5f);
        }

        // 4. Fake ragdoll effect: drop fish
        if (mainRigidbody != null)
        {
            mainRigidbody.isKinematic = false;
            mainRigidbody.useGravity = true;
            mainRigidbody.AddExplosionForce(200f, hitPoint, 5f);
        }

        // 5. Destroy fish after short delay
        Destroy(gameObject, 2f);
    }
}
