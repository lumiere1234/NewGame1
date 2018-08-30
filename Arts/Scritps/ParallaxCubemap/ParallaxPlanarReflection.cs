using UnityEngine;
using System.Collections;
using System.Collections.Generic;

//[ExecuteInEditMode]

public class ParallaxPlanarReflection : MonoBehaviour {
    // reflection
    public LayerMask reflectionMask;
    public bool reflectSkybox = false;
    public Color clearColor = Color.black;
    public System.String reflectionSampler = "_Ref";

    // height
    public float clipPlaneOffset = 0.07F;

    private Vector3 oldpos = Vector3.zero;
    private Camera reflectionCamera;
    private Material sharedMaterial = null;
    private Dictionary<Camera, bool> helperCameras = null;

    public ParallaxCubemapManager pcManager;

    public void Start()
    {
        sharedMaterial = GetComponent<Renderer>().sharedMaterial;        
    }

    private Camera CreateReflectionCameraFor(Camera cam)
    {
        System.String reflName = gameObject.name + "Reflection" + cam.name;
        GameObject go = GameObject.Find(reflName);

        if (!go)
            go = new GameObject(reflName, typeof(Camera));
        if (!go.GetComponent(typeof(Camera)))
            go.AddComponent(typeof(Camera));
        Camera reflectCamera = go.GetComponent<Camera>();

        reflectCamera.backgroundColor = clearColor;
        //reflectCamera.clearFlags = reflectSkybox ? CameraClearFlags.Skybox : CameraClearFlags.SolidColor;
        reflectCamera.clearFlags = CameraClearFlags.SolidColor;

        SetStandardCameraParameter(reflectCamera, reflectionMask);

        if (!reflectCamera.targetTexture)
            reflectCamera.targetTexture = CreateTextureFor(cam);

        return reflectCamera;
    }

    private void SetStandardCameraParameter(Camera cam, LayerMask mask)
    {
        cam.cullingMask = mask;
        cam.backgroundColor = Color.black;
        cam.enabled = false;
    }

    private RenderTexture CreateTextureFor(Camera cam)
    {
        RenderTexture rt = new RenderTexture(Mathf.FloorToInt(cam.pixelWidth * 0.25F), Mathf.FloorToInt(cam.pixelHeight * 0.25F), 24);
        rt.hideFlags = HideFlags.DontSave;
        return rt;
    }

    public void RenderHelpCameras(Camera currentCam)
    {
        if (null == helperCameras)
            helperCameras = new Dictionary<Camera, bool>();

        if (!helperCameras.ContainsKey(currentCam))
        {
            helperCameras.Add(currentCam, false);
        }
        if (helperCameras[currentCam])
        {
            return;
        }

        if (!reflectionCamera)
            reflectionCamera = CreateReflectionCameraFor(currentCam);

        RenderReflectionFor(currentCam, reflectionCamera);

        helperCameras[currentCam] = true;
    }

    public void LateUpdate()
    {
        if (null != helperCameras)
            helperCameras.Clear();
    }

    public void OnWillRenderObject()
    {
        if(Camera.current.name == "Main Camera")
            PlaneBeingRendered(transform, Camera.current);
    }

    public void PlaneBeingRendered(Transform tr, Camera currentCam)
    {
        RenderHelpCameras(currentCam);

        if (reflectionCamera && sharedMaterial)
        {
            sharedMaterial.SetTexture(reflectionSampler, reflectionCamera.targetTexture);
        }
    }

    //public void OnEnable()
    //{
    //    Shader.EnableKeyword("WATER_REFLECTIVE");
    //    Shader.DisableKeyword("WATER_SIMPLE");
    //}

    //public void OnDisable()
    //{
    //    Shader.EnableKeyword("WATER_SIMPLE");
    //    Shader.DisableKeyword("WATER_REFLECTIVE");
    //}


    private void RenderReflectionFor(Camera cam, Camera reflectCamera)
    {
        if (!reflectCamera)
            return;

        if (sharedMaterial && !sharedMaterial.HasProperty(reflectionSampler))
        {
            return;
        }

        reflectCamera.cullingMask = reflectionMask;// &~(1 << LayerMask.NameToLayer("Water"));

        SaneCameraSettings(reflectCamera);

        reflectCamera.backgroundColor = clearColor;
        reflectCamera.clearFlags = CameraClearFlags.SolidColor;

        GL.SetRevertBackfacing(true);

        Transform reflectiveSurface = transform; //planeHeight;

        Vector3 eulerA = cam.transform.eulerAngles;

        reflectCamera.transform.eulerAngles = new Vector3(-eulerA.x, eulerA.y, eulerA.z);
        reflectCamera.transform.position = cam.transform.position;

        Vector3 pos = reflectiveSurface.transform.position;
        pos.y = reflectiveSurface.position.y;
        Vector3 normal = reflectiveSurface.transform.up;
        float d = -Vector3.Dot(normal, pos) - clipPlaneOffset;
        Vector4 reflectionPlane = new Vector4(normal.x, normal.y, normal.z, d);

        Matrix4x4 reflection = Matrix4x4.zero;
        reflection = CalculateReflectionMatrix(reflection, reflectionPlane);
        oldpos = cam.transform.position;
        Vector3 newpos = reflection.MultiplyPoint(oldpos);

        reflectCamera.worldToCameraMatrix = cam.worldToCameraMatrix * reflection;

        Vector4 clipPlane = CameraSpacePlane(reflectCamera, pos, normal, 1.0f);

        reflectCamera.projectionMatrix = cam.CalculateObliqueMatrix(clipPlane);

        reflectCamera.transform.position = newpos;
        Vector3 euler = cam.transform.eulerAngles;
        reflectCamera.transform.eulerAngles = new Vector3(-euler.x, euler.y, euler.z);

        if (pcManager)
        {
            int tmpcount = 1;
            foreach (ParallaxCubemapNode node in pcManager.selectedInfluenceVolumes)
            {
                pcManager.mpb.SetTexture("_Cube" + tmpcount, node.cubemap);
                pcManager.mpb.SetFloat("_BlendFactor" + tmpcount, node.curBlendFactor);
                pcManager.mpb.SetVector("_DistortParams" + tmpcount, new Vector4(node.tCubemap.position.x, node.tCubemap.position.y, node.tCubemap.position.z, 0));

                tmpcount++;
            }
            if((tmpcount-1) == 1)
            {
                Shader.EnableKeyword("BLEND_ONE");
                Shader.DisableKeyword("BLEND_TWO");
                Shader.DisableKeyword("BLEND_THREE");
            }
            else if ((tmpcount - 1) == 2)
            {
                Shader.DisableKeyword("BLEND_ONE");
                Shader.EnableKeyword("BLEND_TWO");
                Shader.DisableKeyword("BLEND_THREE");
            }
            else if ((tmpcount - 1) >= 3)
            {
                Shader.DisableKeyword("BLEND_ONE");
                Shader.DisableKeyword("BLEND_TWO");
                Shader.EnableKeyword("BLEND_THREE");
            }
            else
            {
                Shader.DisableKeyword("BLEND_ONE");
                Shader.DisableKeyword("BLEND_TWO");
                Shader.DisableKeyword("BLEND_THREE");
            }

            if (tmpcount > 1)
            {
                Graphics.DrawMesh(pcManager.geometryMesh, pcManager.tGeometry.localToWorldMatrix, pcManager.geometryMat, LayerMask.NameToLayer("ParallaxCubemap"), reflectCamera, 0, pcManager.mpb);
            
            }
            //Graphics.DrawMesh(pcManager.curNode.geometryMesh, pcManager.curNode.tGeometryProxy.localToWorldMatrix, pcManager.curNode.geometryMat, LayerMask.NameToLayer("ParallaxCubemap"), reflectCamera, 0, pcManager.curNode.mpb);
        }

        reflectCamera.Render();

        GL.SetRevertBackfacing(false);
    }

    private void SaneCameraSettings(Camera helperCam)
    {
        helperCam.depthTextureMode = DepthTextureMode.None;
        helperCam.backgroundColor = Color.black;
        helperCam.clearFlags = CameraClearFlags.SolidColor;
        helperCam.renderingPath = RenderingPath.Forward;
    }

    static Matrix4x4 CalculateReflectionMatrix(Matrix4x4 reflectionMat, Vector4 plane)
    {
        reflectionMat.m00 = (1.0F - 2.0F * plane[0] * plane[0]);
        reflectionMat.m01 = (-2.0F * plane[0] * plane[1]);
        reflectionMat.m02 = (-2.0F * plane[0] * plane[2]);
        reflectionMat.m03 = (-2.0F * plane[3] * plane[0]);

        reflectionMat.m10 = (-2.0F * plane[1] * plane[0]);
        reflectionMat.m11 = (1.0F - 2.0F * plane[1] * plane[1]);
        reflectionMat.m12 = (-2.0F * plane[1] * plane[2]);
        reflectionMat.m13 = (-2.0F * plane[3] * plane[1]);

        reflectionMat.m20 = (-2.0F * plane[2] * plane[0]);
        reflectionMat.m21 = (-2.0F * plane[2] * plane[1]);
        reflectionMat.m22 = (1.0F - 2.0F * plane[2] * plane[2]);
        reflectionMat.m23 = (-2.0F * plane[3] * plane[2]);

        reflectionMat.m30 = 0.0F;
        reflectionMat.m31 = 0.0F;
        reflectionMat.m32 = 0.0F;
        reflectionMat.m33 = 1.0F;

        return reflectionMat;
    }

    static float sgn(float a)
    {
        if (a > 0.0F) return 1.0F;
        if (a < 0.0F) return -1.0F;
        return 0.0F;
    }

    private Vector4 CameraSpacePlane(Camera cam, Vector3 pos, Vector3 normal, float sideSign)
    {
        Vector3 offsetPos = pos + normal * clipPlaneOffset;
        Matrix4x4 m = cam.worldToCameraMatrix;
        Vector3 cpos = m.MultiplyPoint(offsetPos);
        Vector3 cnormal = m.MultiplyVector(normal).normalized * sideSign;

        return new Vector4(cnormal.x, cnormal.y, cnormal.z, -Vector3.Dot(cpos, cnormal));
    }
}
