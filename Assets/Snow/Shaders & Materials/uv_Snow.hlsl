float3 _OrthCamPos;
float _OrthCamSize;
float3 _WorldPos;



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

