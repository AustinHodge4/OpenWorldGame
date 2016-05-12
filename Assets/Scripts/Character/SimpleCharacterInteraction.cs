using UnityEngine;
using System.Collections;
using RootMotion.FinalIK;

public class SimpleCharacterInteraction : MonoBehaviour {

    private SimpleCharacterController characterController;
    private InteractionSystem interactionSystem; // Reference to the InteractionSystem of the character
    public bool disableInputInInteraction = true; // If true, will keep the character stopped while an interaction is in progress
    public float enableInputAtProgress = 0.8f; // The normalized interaction progress after which the character is able to move again

    public void Start()
    {
        characterController = GetComponent<SimpleCharacterController>();
        interactionSystem = CharacterInputController.interactionSystem;
    }
    public void Update()
    {
        // Disable input when in interaction
        if (disableInputInInteraction && interactionSystem != null && (interactionSystem.inInteraction || interactionSystem.IsPaused()))
        {

            // Get the least interaction progress
            float progress = interactionSystem.GetMinActiveProgress();

            // Keep the character in place
            if (progress > 0f && progress < enableInputAtProgress)
            {
                characterController.disableControl = true;
                return;
            }
        }
        characterController.disableControl = false;

    }

    // Triggering the interactions
    void OnGUI()
    {
        // If jumping or falling, do nothing
        if (!GetComponent<SimpleCharacterController>().grounded) return;

        // If an interaction is paused, resume on user input
        if (interactionSystem.IsPaused() && interactionSystem.IsInSync())
        {
            GUILayout.Label("Press E to resume interaction");

            if (Input.GetKey(KeyCode.E))
            {
                interactionSystem.ResumeAll();
                characterController.disableControl = false;
            }

            return;
        }

        // If not paused, find the closest InteractionTrigger that the character is in contact with
        int closestTriggerIndex = interactionSystem.GetClosestTriggerIndex();

        // ...if none found, do nothing
        if (closestTriggerIndex == -1) return;

        // ...if the effectors associated with the trigger are in interaction, do nothing
        if (!interactionSystem.TriggerEffectorsReady(closestTriggerIndex)) return;

        // Its OK now to start the trigger
        GUILayout.Label("Press E to start interaction");

        if (Input.GetKey(KeyCode.E))
        {
            interactionSystem.TriggerInteraction(closestTriggerIndex, false);
        }
    }

}
