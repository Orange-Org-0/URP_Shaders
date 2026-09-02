using System.Collections;
using System.Collections.Generic;
using UnityEngine;


[ExecuteAlways]
public class HoloScaleControl : MonoBehaviour
{
    public Material material;
    private float Scale = 1.0f;
    public GameObject projector;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        Scale = transform.localScale.x;
        if(material != null)
            material.SetFloat("_inv_Scale", 1.0f / Scale);
        if(projector != null)        
            material.SetVector("_ProjectorPos", projector.transform.position);
        
    }
}
