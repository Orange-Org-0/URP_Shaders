using System.Collections;
using System.Collections.Generic;
using UnityEngine;


public class HitWave : MonoBehaviour
{
   
    public ParticleSystem ps;
    public int maxParticleCount = 10;

    public Material material;

    public Vector4[] positions;
    public float[] sizes;
    public float[] finalSizes;  // 新增：存储每个粒子的最终大小

    private ParticleSystem.Particle[] particles;
    private ParticleSystem.MainModule mainModule;

    private void DoRaycast()
    {
        RaycastHit hit;
        Ray ray = Camera.main.ScreenPointToRay(Input.mousePosition);

        if (Physics.Raycast(ray, out hit))
        {
            if (hit.transform.CompareTag("Shield"))
            {
                ps.transform.position = hit.point;
                ps.Emit(1);
            }
        }
    }

    void Start()
    {
        positions = new Vector4[maxParticleCount];
        sizes = new float[maxParticleCount];
        finalSizes = new float[maxParticleCount];
        particles = new ParticleSystem.Particle[maxParticleCount];
        mainModule = ps.main;
    }

    void Update()
    {

        if (ps == null) return;


        if (Input.GetMouseButtonDown(0))
        {
            DoRaycast();
        }

        int count = ps.GetParticles(particles);

        for (int i = 0; i < maxParticleCount; i++)
        {
            if (i < count)
            {
                // 当前世界空间位置
                positions[i] = particles[i].position;
                //positions[i] = ps.transform.position;
                Debug.Log("Particle " + i + "pos:" + particles[i].position);
                Debug.Log("pspos:" + ps.transform.position);
                // 当前大小（随时间变化）
                sizes[i] = particles[i].GetCurrentSize(ps);
                Debug.Log("Particle " + i + " Current Size: " + sizes[i]);
                // 最终大小（startSize的恒定值或曲线最大值）
                finalSizes[i] = mainModule.startSize.constantMax;
            }
            else
            {
                positions[i] = Vector3.zero;
                sizes[i] = 0.0f;
                finalSizes[i] = 1.0f;
            }
        }

        Shader.SetGlobalVectorArray("HitPos", positions);
        Shader.SetGlobalFloatArray("ParticleCrntSize", sizes);
        Shader.SetGlobalFloatArray("ParticleFinalSize", finalSizes);
        material.SetFloat("_Scale", transform.localScale.x);
    }

}
