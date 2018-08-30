using UnityEngine;
#if UNITY_EDITOR 
using UnityEditor;
#endif
using System.Collections;

public class ParallaxCubemapNode : MonoBehaviour {

    public Transform tInfluenceProxy;
    public bool bInfluenceCube;
	public enum InfluenceType
    {
        Sphere = 0,
        Cube = 1,
    };

    public InfluenceType influenceType;
    public Transform tGeometryProxy;
    public Transform tCubemap;
    public string sCubemapName;
    public Cubemap cubemap; // stores an corresponding cubemap in this variable for access by other scripts

    public float curWeight;
    public float curBlendFactor;

    public Vector3 fCubeOuterLength;// = {5.0f,5.0f,5.0f};// = Vector3(5.0f, 5.0f, 5.0f);
    public Vector3 fCubeInnerLength;
    public float fSphereOuterRadius;
    public float fSphereInnerRadius;

    //public MeshRenderer mGeometryProxy;
    public Mesh geometryMesh;
    public Material geometryMat;
    public MaterialPropertyBlock mpb;

    void Start()
    {
        curWeight = 0.0f;
        curBlendFactor = 0.0f;
        //if(tGeometryProxy)
        //{
        //    geometryMesh = tGeometryProxy.gameObject.GetComponent<MeshFilter>().sharedMesh;
        //    geometryMat = tGeometryProxy.gameObject.renderer.material;
        //    mpb = new MaterialPropertyBlock();
        //    //tGeometryProxy.gameObject.renderer.GetPropertyBlock(mpb);
        //}
    }

    public float GetInfluenceWeights(Vector3 POI)
    {
        curWeight = 0.0f;
        curBlendFactor = 0.0f;

        if(influenceType == InfluenceType.Cube)
        {
            Vector3 localPOI = tInfluenceProxy.InverseTransformPoint(POI);

            if(fCubeInnerLength.x == fCubeOuterLength.x || fCubeInnerLength.y == fCubeOuterLength.y || fCubeInnerLength.z == fCubeOuterLength.z)
            {
                return curWeight;
            }
            
            Vector3 localDir = new Vector3();
            localDir.x = (Mathf.Abs(localPOI.x) - fCubeInnerLength.x / 2.0f) / (fCubeOuterLength.x / 2.0f - fCubeInnerLength.x / 2.0f);
            localDir.y = (Mathf.Abs(localPOI.y) - fCubeInnerLength.y / 2.0f) / (fCubeOuterLength.y / 2.0f - fCubeInnerLength.y / 2.0f);
            localDir.z = (Mathf.Abs(localPOI.z) - fCubeInnerLength.z / 2.0f) / (fCubeOuterLength.z / 2.0f - fCubeInnerLength.z / 2.0f);

            curWeight = GetMax(localDir);
            return curWeight;
        }
        else
        {
            Vector3 direction = POI - tInfluenceProxy.position;
            float distance = direction.magnitude;
            if (distance > fSphereOuterRadius)
            {
                curWeight = 2;
            }
            else if (distance <= fSphereInnerRadius)
            {
                curWeight = 0;
            }
            else
            {
                if ((fSphereOuterRadius - fSphereInnerRadius) > 0)
                    curWeight = (distance - fSphereInnerRadius) / (fSphereOuterRadius - fSphereInnerRadius);
            }
            return curWeight;
        }
    }

    float GetMax(Vector3 inVec)
    {
        float fMax = inVec.x;
        if (fMax < inVec.y)
            fMax = inVec.y;
        if (fMax < inVec.z)
            fMax = inVec.z;
        return fMax;
    }

    #if UNITY_EDITOR 
    void OnDrawGizmos()
    {
        Gizmos.DrawIcon(transform.position, "CubemapNode.png");

        Gizmos.color = Color.green;
        Gizmos.matrix = tInfluenceProxy.localToWorldMatrix;

        if (influenceType == InfluenceType.Cube)
        {
            Gizmos.DrawWireCube(new Vector3(0, 0, 0),
                            fCubeOuterLength);
        }
        else
        {
            Gizmos.DrawWireSphere(new Vector3(0, 0, 0), fSphereOuterRadius);
        }

        Gizmos.color = Color.yellow;
        if (influenceType == InfluenceType.Cube)
        {
            Gizmos.DrawWireCube(new Vector3(0, 0, 0),
                            fCubeInnerLength);
        }
        else
        {
            Gizmos.DrawWireSphere(new Vector3(0, 0, 0), fSphereInnerRadius);
        }
    }

    void OnDrawGizmosSelected()
    {
        Gizmos.DrawIcon(transform.position, "CubemapNode.png");

        Gizmos.color = Color.red;
        Gizmos.matrix = tInfluenceProxy.localToWorldMatrix;

        if (influenceType == InfluenceType.Cube)
        {
            Gizmos.DrawWireCube(new Vector3(0, 0, 0),
                            fCubeOuterLength);
        }
        else
        {
            Gizmos.DrawWireSphere(new Vector3(0, 0, 0), fSphereOuterRadius);
        }

        Gizmos.color = Color.yellow;
        if (influenceType == InfluenceType.Cube)
        {
            Gizmos.DrawWireCube(new Vector3(0, 0, 0),
                            fCubeInnerLength);
        }
        else
        {
            Gizmos.DrawWireSphere(new Vector3(0, 0, 0), fSphereInnerRadius);
        }
    }
    #endif
}
