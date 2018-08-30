using UnityEngine;
using System.Collections;



public class MaterialFxV2 : MonoBehaviour {
	public enum Mode
	{
		Normal = 0,
		StopOther,
	}

	public Mode mode;
	public AnimationClip clip;
	public string[] propertyNames;
	public bool[] isColor;
}
