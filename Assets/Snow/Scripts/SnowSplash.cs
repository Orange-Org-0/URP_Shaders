using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.VFX;


[ExecuteAlways]
public class SnowSplash : MonoBehaviour  //目前没有任何用
{

    public GameObject player;
    private float playerSpeed;
    public VisualEffect snowSplashEffect;

    private void Awake()
    {
        player = GameObject.FindGameObjectWithTag("Player");
    }

    // Start is called before the first frame update
    void Start()
    {
        player = GameObject.FindGameObjectWithTag("Player");
        snowSplashEffect = GetComponent<VisualEffect>();
    }

    // Update is called once per frame
    void Update()
    {
     
    }

  

    

}
