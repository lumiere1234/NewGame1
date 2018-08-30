using UnityEngine;
using System.Collections;

public class FxScale : MonoBehaviour {

    ParticleSystem[] particleSystems;

    void Awake()
    {
        ScaleParticles();
    }

    void ScaleParticles()
    {
        particleSystems = gameObject.GetComponentsInChildren<ParticleSystem>();

        for (int i = 0; i < particleSystems.Length; i++)
		{
            particleSystems[i].startLifetime *= transform.lossyScale.x;
            particleSystems[i].startSize *= transform.lossyScale.x;
            particleSystems[i].gravityModifier *= transform.lossyScale.x;
		}
    }

}
