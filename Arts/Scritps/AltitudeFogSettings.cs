using UnityEngine;
using System.Collections;
#if UNITY_EDITOR
using UnityEditor.SceneManagement;
#endif

public class AltitudeFogSettings : MonoBehaviour {
	public bool isAltitudeFogEnabled = false;
	public Color altitudeFogColor = new Color(0.5f, 0.7f, 0.7f, 1);
	public Vector4 altitudeFogParams = new Vector4(110, 0, 0.001f, 1);

	static readonly string defaultName = "AltitudeFogSettings";
	static readonly HideFlags selfHideFlags = HideFlags.HideInHierarchy;

	static readonly string wokAltitudeFogOff = "WOK_ALTITUDE_FOG_OFF";
	static readonly string wokAltitudeFogOn = "WOK_ALTITUDE_FOG_ON";
	static readonly string wokAltitudeFogColor = "wokAltitudeFogColor";
	static readonly string wokAltitudeFogParams = "wokAltitudeFogParams";

#if UNITY_EDITOR
	public static AltitudeFogSettings GetCurrentSceneSettings()
	{
		GameObject settingObj = GameObject.Find(defaultName);
		if (null == settingObj)
		{
			settingObj = new GameObject(defaultName);
			settingObj.hideFlags = selfHideFlags;
			settingObj.AddComponent<AltitudeFogSettings>();
		}
		AltitudeFogSettings setting = settingObj.GetComponent<AltitudeFogSettings>();
		if ( setting == null)
			setting = settingObj.AddComponent<AltitudeFogSettings>();

		return setting;
	}
#endif

	public static AltitudeFogSettings CreateAltitudeFogSettings()
	{
		GameObject settingObj = new GameObject(defaultName);
		settingObj.hideFlags = selfHideFlags;
		return settingObj.AddComponent<AltitudeFogSettings>();
	}

	public void ApplySettings()
	{
		if (isAltitudeFogEnabled)
		{
			Shader.DisableKeyword(wokAltitudeFogOff);
			Shader.EnableKeyword(wokAltitudeFogOn);
		}
		else
		{
			Shader.DisableKeyword(wokAltitudeFogOn);
			Shader.EnableKeyword(wokAltitudeFogOff);
		}

		Shader.SetGlobalColor(wokAltitudeFogColor, altitudeFogColor);
		Shader.SetGlobalVector(wokAltitudeFogParams, altitudeFogParams);
	}
}
