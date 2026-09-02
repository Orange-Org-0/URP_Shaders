//float3 _OrthCamPos;
//float _OrthCamSize;
//float3 _WorldPos;



float uvInRange(float2 uv)
{
    return step(0, uv.x) * step(uv.x, 1) * step(0, uv.y) * step(uv.y, 1);
}

float3 CalcUV(float3 OrthCamPos, float OrthCamSize, float3 WorldPos)
{
    float2 uv = (WorldPos.xz - OrthCamPos.xz) / OrthCamSize;
    uv = uv * 0.5 + 0.5;    
    return float3(uv, uvInRange(uv));
}


float CalcHeight(float2 CompTex, float NoiseStrength, float2 Ground, float uvInRange)
{
    float GroundHeight = Ground.x;
    float GroundHeightStrength = Ground.y;
    float Snowtrail = CompTex.r;
    float Noise = CompTex.g;
    //preprocessing
    Snowtrail = saturate(Snowtrail);   
    Noise = saturate(Noise);
    Noise = Noise * 2 - 1;
    
    //main
    float height = pow(Snowtrail, 0.2) * Noise * NoiseStrength * 0.1;
    height += (1.0 - Snowtrail);
    
    height *= uvInRange;
    height += (1.0 - uvInRange);
    return height;
}

float CalcSnowHeight(float Height, float SnowHeight)
{
    return Height + SnowHeight;
}

