using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class ParallaxCubemapManager : MonoBehaviour {

    public Transform tPOI;

    List<ParallaxCubemapNode> nodesList;
    public List<ParallaxCubemapNode> selectedInfluenceVolumes;

    public bool bFinish = false;

    public ParallaxCubemapNode curNode;

    //public MeshRenderer mGeometryProxy;
    public Transform tGeometry;
    public Mesh geometryMesh;
    public Material geometryMat;
    public MaterialPropertyBlock mpb;

	// Use this for initialization
	void Start () {

        ParallaxCubemapNode[] nodes = FindObjectsOfType(typeof(ParallaxCubemapNode)) as ParallaxCubemapNode[];
        nodesList = new List<ParallaxCubemapNode>(nodes);
        selectedInfluenceVolumes = new List<ParallaxCubemapNode>();

        if (tGeometry)
        {
            geometryMesh = tGeometry.gameObject.GetComponent<MeshFilter>().sharedMesh;
            geometryMat = tGeometry.gameObject.GetComponent<Renderer>().material;
            mpb = new MaterialPropertyBlock();
        }

        if(Camera.main)
            tPOI = Camera.main.transform;
	}
	
	// Update is called once per frame
	void Update () {

        if(!tPOI)
        {
            if (Camera.main)
                tPOI = Camera.main.transform;
        }

        CubemapsBlendingWeightsCalc();

        //SetGeometryProxyParam();
	
	}

    void SetGeometryProxyParam()
    {
        if (!bFinish) return;

        //if(curNode)
        //    curNode.tGeometryProxy.gameObject.renderer.enabled = true;

    }

    void CubemapsBlendingWeightsCalc()
    {
        bFinish = false;
        selectedInfluenceVolumes.Clear();
        if (!tPOI)
            return;

        //foreach (ParallaxCubemapNode node in nodesList)
        //{
        //    node.tGeometryProxy.gameObject.renderer.enabled = false;
        //}

        foreach(ParallaxCubemapNode node in nodesList)
        {
            float weight = node.GetInfluenceWeights(tPOI.position);
            if (weight <= 0)
            {
                selectedInfluenceVolumes.Clear();
                selectedInfluenceVolumes.Add(node);
                break;
            }
            else if (weight > 0 && weight < 1)
            {
                selectedInfluenceVolumes.Add(node);
            }
        }

        if (!bFinish)
        {
            BlendMapFactorCalc();
        }
    }

    void BlendMapFactorCalc()
    {
        if (selectedInfluenceVolumes.Count == 0) return;

        if (selectedInfluenceVolumes.Count == 1)
        {
            selectedInfluenceVolumes[0].curBlendFactor = 1;
            curNode = selectedInfluenceVolumes[0];
            bFinish = true;
            return;
        }

        float SumNDF = 0.0f;
        float InvSumNDF = 0.0f;
        float SumBlendFactor = 0.0f;

        curNode = selectedInfluenceVolumes[0];
        float curDistFromPOI = (curNode.transform.position - tPOI.position).sqrMagnitude;

        for (int i = 0; i < selectedInfluenceVolumes.Count; ++i)
        {
            SumNDF += selectedInfluenceVolumes[i].curWeight;
            InvSumNDF += (1.0f - selectedInfluenceVolumes[i].curWeight);

            float tmpDist = (selectedInfluenceVolumes[i].transform.position - tPOI.position).sqrMagnitude;
            if(tmpDist < curDistFromPOI)
            {
                curNode = selectedInfluenceVolumes[i];
                curDistFromPOI = tmpDist;
            }
        }

        for (int i = 0; i < selectedInfluenceVolumes.Count; ++i)
        {
            selectedInfluenceVolumes[i].curBlendFactor = (1.0f - selectedInfluenceVolumes[i].curWeight / SumNDF) / (selectedInfluenceVolumes.Count - 1);
            selectedInfluenceVolumes[i].curBlendFactor *= ((1.0f - selectedInfluenceVolumes[i].curWeight) / InvSumNDF);
            SumBlendFactor += selectedInfluenceVolumes[i].curBlendFactor;
        }

        // Normalize BlendFactor
        if (SumBlendFactor == 0.0f) // Possible with custom weight
        {
            SumBlendFactor = 1.0f;
        }

        float ConstVal = 1.0f / SumBlendFactor;
        for (int i = 0; i < selectedInfluenceVolumes.Count; ++i)
        {
            selectedInfluenceVolumes[i].curBlendFactor *= ConstVal;
        }

        bFinish = true;
    }
}
