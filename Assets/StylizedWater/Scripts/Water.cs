using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteAlways]
public class Water : MonoBehaviour
{

    public Camera Camera;
    public RenderTexture RT;
    public Material Mat;
    // Start is called before the first frame update
    void Start()
    {
        if (Camera == null)
            Camera = GetComponentInChildren<Camera>();
        if (RT == null)
            RT = GetComponentInChildren<RenderTexture>();
        SetParams();
    }

    // Update is called once per frame
    void Update()
    {
       SetParams();
    }

    private void SetParams()
    {
        if(Mat == null || RT == null)
        {
            Debug.LogWarning("WaterMat or RT is null");
            return;
        }
        Mat.SetTexture("_RippleTex", RT);
        Mat.SetVector("_CamPos", Camera.transform.position);
        Mat.SetFloat("_CamSize", Camera.orthographicSize);
    }


}
