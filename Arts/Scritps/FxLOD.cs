using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class FxLOD : MonoBehaviour
{
	public GameObject[] allKeyGameObjects;
	public int[] generation;
	public int[] priorities;

	public int costLevel;	// 1,2,3  3 -> expensive.

	[HideInInspector]
	public ParticleSystem[] particleSystems;
	//[HideInInspector]
	public float[] oriParticlesSize;


	public TrailRenderer[] trailRenderers;
	public float[] oriTrailStartSize;

	public MeshRenderer[] billBoards;
	public float[] oriBillBoardsSize;

	bool m_sizeInfoRecorded = false;
	Transform myT;

	string billboardScaleProperty = "_Scale";
	string billboardOffsetProperty = "_DistanceOffset";

	public Renderer[] suddenDisappearRenderers;
	
	void Awake()
	{
		if (!m_sizeInfoRecorded)	//避免手动调 RecordSizeInformation 后此处再调一次
			RecordSizeInformation();
		
		myT = transform;
	}

	public void RecordSizeInformation()
	{
		m_sizeInfoRecorded = true;

		// particle
#if ! UNITY_5
		particleSystems = gameObject.GetComponentsInChildren<ParticleSystem>(true);
		oriParticlesSize = new float[particleSystems.Length];
		for (int i = 0; i < particleSystems.Length; i++)
		{
			oriParticlesSize[i] = particleSystems[i].startSize;
		}
#endif
		// trailrenderer
		trailRenderers = gameObject.GetComponentsInChildren<TrailRenderer>(true);
		oriTrailStartSize = new float[trailRenderers.Length];
		for (int i = 0; i < trailRenderers.Length; i++)
		{
			oriTrailStartSize[i] = trailRenderers[i].startWidth;
		}
		//bill board
		MeshRenderer[] meshRenderers = gameObject.GetComponentsInChildren<MeshRenderer>(true);
		List<MeshRenderer> billboardRenderers = new List<MeshRenderer>();
		for (int i = 0; i < meshRenderers.Length; i++)
		{
			Material mat;
			if (Application.isPlaying)
			{
				mat = meshRenderers[i].material;

			}
			else
			{
				mat = meshRenderers[i].sharedMaterial;
			}
			if (mat.shader.name.ToLower().StartsWith("billboard/vertexcolor/"))	//TODO
			{
				billboardRenderers.Add(meshRenderers[i]);
			}
		}
		billBoards = billboardRenderers.ToArray();
		oriBillBoardsSize = new float[billBoards.Length];
		for (int i = 0; i < billBoards.Length; i++)
		{
			oriBillBoardsSize[i] = billBoards[i].material.GetFloat(billboardScaleProperty);
		}
	}

	public void TurnEnable(bool enable, int threshold = 10, float scale = 1)
	{
		if (myT == null)
			myT = transform;
		
		//myT.localScale = Vector3.one * scale;
		if (enable)
		{
			if (suddenDisappearRenderers != null)
			{
				for (int i = 0; i < suddenDisappearRenderers.Length; i++)
				{
					var render = suddenDisappearRenderers[i];
					if (render != null && !render.enabled)
						render.enabled = true;
				}
			}

			if (allKeyGameObjects != null)
			{
				for (int i = 0; i < allKeyGameObjects.Length; i++)
				{
					GameObject gameObject = allKeyGameObjects[i];
					if (gameObject != null)
						gameObject.SetActive(priorities[i] <= threshold);
				}
			}
		}
		else
		{
			if (allKeyGameObjects != null)
			{
				for (int i = 0; i < allKeyGameObjects.Length; i++)
				{
					var gameObject = allKeyGameObjects[i];
					if (gameObject != null)
						gameObject.SetActive(false);
				}
			}
		}

		/// Scale TrailRenderer
		if (enable)
		{
			if (trailRenderers != null && trailRenderers.Length != 0)
			{
				for (int i = 0; i < trailRenderers.Length; i++)
				{
					ScaleTrailRenderer(trailRenderers[i], scale, oriTrailStartSize[i]);
				}
			}
		}

		if (enable)
		{
			if (billBoards != null && billBoards.Length != 0)
			{
				for (int i = 0; i < billBoards.Length; i++)
				{
					ScaleBillboard(billBoards[i], scale, oriBillBoardsSize[i]);
				}
			}
		}


		if (enable)
		{
			if (particleSystems != null)
			{
				for (int i = 0; i < particleSystems.Length; i++)
				{
					if (particleSystems[i].gameObject.activeInHierarchy)
					{
						particleSystems[i].Clear(false);
#if !UNITY_5
						ScaleParticle(particleSystems[i], scale, oriParticlesSize[i]);
#endif
						particleSystems[i].Play(false);
					}
				}
			}
		}
		else
		{
			if (particleSystems != null)
			{
				for (int i = 0; i < particleSystems.Length; i++)
				{
					particleSystems[i].Stop(false);
					particleSystems[i].Clear(false);
				}
			}
		}
	}

	public void Stop()
	{
		for (int i = 0; i < particleSystems.Length; i++)
		{
			particleSystems[i].Stop();
		}
		if (suddenDisappearRenderers != null)
		{
			for (int i = 0; i < suddenDisappearRenderers.Length; i++)
			{
				var render = suddenDisappearRenderers[i];
				if (render != null)
					render.enabled = false;
			}
		}
	}

	void ScaleParticle(ParticleSystem particle, float scale, float oriScale)
	{
		if (scale == 0)
		{
			Debug.LogError("should not scale to 0, skipped.");
			return;
		}
		float multi = oriScale / particle.startSize * scale;
		if (Mathf.Abs(multi - 1) < 0.01f)
			return;
		particle.startSize *= multi;
		particle.startSpeed *= multi;
		particle.startRotation *= multi;
		particle.gravityModifier *= multi;
	}

	void ScaleTrailRenderer(TrailRenderer trail, float scale, float oriScale)
	{
		float multi = oriScale / trail.startWidth * scale;
		if (Mathf.Abs(multi - 1) < 0.01f)
			return;
		trail.startWidth *= multi;
		trail.endWidth *= multi;
		//TODO: min vertex distance


	}

	void ScaleBillboard(MeshRenderer render, float scale, float oriScale)
	{
		float currentSize = render.material.GetFloat(billboardScaleProperty);
		float multi = oriScale / currentSize * scale;
		if (Mathf.Abs(multi - 1) < 0.01f)
			return;
		render.transform.localScale = Vector3.one * (1 / transform.lossyScale.x);
		render.material.SetFloat(billboardScaleProperty, multi * currentSize);
	}

}