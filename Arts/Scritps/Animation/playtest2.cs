using UnityEngine;
using System.Collections;
using System.IO;
using System.Text;
//using Game;

public class playtest2 : MonoBehaviour {


	[System.Serializable]
	public class EffectDelay
	{ 
		public Transform effect;
		public float delayTime;
		public string bindname;
		public Transform bindbone;
		[HideInInspector]
		public bool played;
		[HideInInspector]
		public Transform effectInstance;
	}

	public EffectDelay[]  DelayEffects;
	public string AnimationName=null;
	private Vector3 pos;
	private Quaternion rot;
	public bool UseTime;
	public float AniTime;
	private GameObject GfxPos_obj;
    
    void OnEnable()
	{
		for(int i = 0; i < DelayEffects.Length;++i)
		{
			EffectDelay effectDelay = DelayEffects[i];
			effectDelay.played = false;
		}
	}

    void Awake()
    {

    }
	// Use this for initialization
	void Start () {
		GfxPos_obj = GameObject.CreatePrimitive (PrimitiveType.Sphere);
		GfxPos_obj.transform.name="▶特效位置◀"+"▶"+transform.name+"◀";



	}
	
	// Update is called once per frame
	void Update () 
    {
		//Application.targetFrameRate = 30;
		//if (gfxobj == null) {
	   //pos = transform.position;
		pos = GfxPos_obj.transform.position;
		rot = GfxPos_obj.transform.rotation;

		//		}
		//else {
		//				pos = gfxobj.transform.position;
		//	}
		//string strAnim  = anim.ToString();
		if (Input.GetButtonDown ("Jump")) 
		{
			if(GetComponent<Animation>() != null)
			{
                 GetComponent<Animation>()[AnimationName].time = 0.0f;
			     GetComponent<Animation>().CrossFade (AnimationName, 0.1f);
			}
		}
		//if (UseTime&&AnimationName != null && animation [AnimationName].time != AniTime) 
        //if (AnimationName != null) 
		{	
		    //animation [AnimationName].time = AniTime;

            if(UseTime)
            {
				if(GetComponent<Animation>() != null)
				{
                	if (Mathf.Abs(GetComponent<Animation>()[AnimationName].time - AniTime) < Mathf.Epsilon)
                	{
                    	return;
                	}
                	GetComponent<Animation>() [AnimationName].time = AniTime;
				}
            }
           


			float fCurTime = AniTime;//animation [AnimationName].time;
			if(GetComponent<Animation>() != null)
			{
				fCurTime = GetComponent<Animation>() [AnimationName].time;
			}


			for(int i = 0; i < DelayEffects.Length;++i)
			{
				EffectDelay effectDelay = DelayEffects[i];
				Transform trans = effectDelay.effect;
				if(trans != null)
				{
					if(fCurTime >= effectDelay.delayTime * 0.001f)
					{
						if(!effectDelay.played )
						{
							if(effectDelay.effectInstance != null)
							{
								GameObject.Destroy(effectDelay.effectInstance.gameObject);
							}
							

							effectDelay.effectInstance = Instantiate(trans, pos, rot) as Transform;
							File.WriteAllText ("特效偏移角度配置.txt","位置"+pos.ToString()+"角度"+rot.eulerAngles.ToString());



							if(/*!effectDelay.bindname.IsNullOrEmpty() ||*/ effectDelay.bindbone != null)
							{
								//Transform bindbone = null;

								//if(effectDelay.bindbone != null)
								//{ 
								//	bindbone = effectDelay.bindbone;
								//}
								//else
								//{
								//     GameObject goaltemp = GameObject.Find (effectDelay.bindname);
								//	if(goaltemp != null)
								//	{
								//		bindbone = goaltemp.transform;
								//	}

								//}
								//if(bindbone != null)
								{
									effectDelay.effectInstance.position = effectDelay.bindbone.position;
									effectDelay.effectInstance.rotation = effectDelay.bindbone.rotation;
									effectDelay.effectInstance.transform.parent = effectDelay.bindbone;

								}
							}
							effectDelay.played = true;
						}
						
					}
					else
					{
						effectDelay.played = false;
						
					}

				}

			}


			if(!UseTime)
			{
				AniTime += Time.deltaTime;
			}

		}
	}
}
