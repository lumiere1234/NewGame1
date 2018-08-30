using UnityEngine;
using System.Collections;


public enum SubFxDirection{
	Left,

	TopLeft,
	TopRight ,
	Right,
	Bottom
}

public enum SubFxQuality{
	White = 0,
	Blue,
	Yellow,
	Green,
	Purple
}

public class Fx_Bonus : MonoBehaviour {
	public KeyCode startKey = KeyCode.T;
	public KeyCode resetKey = KeyCode.R;
	public GameObject backGroundFx;
	public GameObject fx1;
	public float delay = .6f;


	public float[] eachDirectionDelay = new float[]{0.4f,0.3f, 0.1f,0.1f };
	public GameObject[] directionObjs;
	public Vector3[] oriPositions;

	public SubFxDirection[] order = new SubFxDirection[]{SubFxDirection.Left,SubFxDirection.TopLeft
		,SubFxDirection.TopRight,SubFxDirection.Right, SubFxDirection.Bottom};


	string[] missleObjectName = new string[]{"white_missile", "blue_missile", "yellow_missile", "green_missile", "purple_missile"};
	string[] fxObjectName = new string[]{"white", "blue", "yellow", "green", "purple"};


	// Use this for initialization
	void Start () {
		oriPositions = new Vector3[directionObjs.Length];
		for (int i = 0; i < directionObjs.Length; i ++) {
			if ( directionObjs[i] != null){
				oriPositions[i] = directionObjs[i].transform.localPosition;
			}
		}
		if (backGroundFx != null) {
			backGroundFx.SetActive(true);
		}
	}
	
	// Update is called once per frame
	void Update () {
		if (Input.GetKeyDown (startKey)) {
		 	StartCoroutine(	StartFx());
		}

		if (Input.GetKeyDown (resetKey)) {
			Reset();
		}
	}


	IEnumerator StartFx(){
		if (fx1 != null) {
			fx1.SetActive (true);
		}
		if (backGroundFx != null) {
			backGroundFx.SetActive (false);
		}
		yield return new WaitForSeconds( delay);


		for (int i = 0; i < order.Length; i++) {
			PlaySubFx( (SubFxDirection )order[i] ,RandomQuality()	);

			if ( i < eachDirectionDelay.Length){
				yield return new WaitForSeconds( eachDirectionDelay[i]);
			}
		}

	}

	SubFxQuality RandomQuality(){
		return (SubFxQuality) (Random.Range(0,5));
	}

	public void PlaySubFx(SubFxDirection dir ,SubFxQuality quality){

		GameObject dirObject = directionObjs [(int)dir];
		dirObject.SetActive (true);


		Transform missile = dirObject.transform.Find( missleObjectName[(int) quality] );
		if (missile != null) {
				missile.gameObject.SetActive (true);
			} else {
			Debug.LogWarning("can't find missle "+ dir + "   " + quality);
		}

		Transform fxObj = dirObject.transform.Find( fxObjectName[(int) quality]);
		if (fxObj != null) {
			fxObj.gameObject.SetActive (true);


			} else {
			Debug.LogWarning ("can't find " + dir + "   " + quality);
		}
	}

	void Reset(){
		for (int i = 0; i < order.Length; i++) {
			for( int j = 0 ; j < 5; j++){
				DisableFxAll( 	);
			}
		}
	}
	public void DisableFxAll(){
		for (int i = 0; i < directionObjs.Length; i ++) {
			GameObject dirObject = directionObjs [i];
			for ( int j = 0; j < 5; j ++){
				Transform missile =  dirObject.transform.Find( missleObjectName[j]);
				Transform fxObj = dirObject.transform.Find( fxObjectName[j]);
				if ( missile != null){
					missile.gameObject.SetActive(false);
				}
				if (fxObj != null){
					fxObj.gameObject.SetActive(false);
				}
			}
			dirObject.transform.localPosition = oriPositions[i];
			dirObject.SetActive(false);
		}
		if(backGroundFx != null)
			backGroundFx.SetActive (true);
		if(fx1 != null)
			fx1.SetActive (false);
	}

	void OnGUI(){
	//	GUI.Label( new Rect(0, 0, 300,50), "Key T for preview, R for Reset");
	}
}
