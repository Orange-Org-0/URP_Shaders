using JetBrains.Annotations;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;
using static UnityEngine.ParticleSystem;



[ExecuteInEditMode]
public class Hollow : MonoBehaviour
{
    public Material material;
    public ParticleSystem ps;


    private ParticleSystem.Particle[] particles;//粒子数组
    private Vector4[] pos;//粒子位置数组
    private float[] sizes;//粒子大小数组
    private float[] initsizes;//粒子初始大小数组
    public int maxPartAmount = 20;//最大粒子数
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {


        //粒子系统的参数设置
        var psmain = ps.main;
        psmain.maxParticles = maxPartAmount;
        particles = new ParticleSystem.Particle[maxPartAmount];

        ps.GetParticles(particles);
        sizes = new float[maxPartAmount];
        pos = new Vector4[maxPartAmount];
        initsizes = new float[maxPartAmount];

        for (int i = 0; i < maxPartAmount; i++)
        {
            pos[i] = particles[i].position;
            sizes[i] = particles[i].GetCurrentSize(ps) * ps.transform.localScale.x;
            initsizes[i] = particles[i].startSize * ps.transform.localScale.x;
        }


        //material.SetFloat("_HitSize", sizes[0]);
        //material.SetFloat("_FinalSize", finsizes[0]);
        //material.SetVector("_HitPos", pos[0]);

        Shader.SetGlobalFloatArray("ParticleSize", sizes);
        Shader.SetGlobalFloatArray("ParticleInitSize", initsizes);
        Shader.SetGlobalVectorArray("ParticlePos", pos);
    }
}
