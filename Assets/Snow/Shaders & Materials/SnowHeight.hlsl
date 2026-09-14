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


float ProcessTrailTex(float2 CompTex, float uvInRange)
{
    
    float SnowTrail = CompTex.r;
    float Noise = CompTex.g;
    //preprocessing
    SnowTrail = saturate(SnowTrail);
    SnowTrail *= uvInRange;
    //Noise = saturate(Noise);
    //Noise = Noise * 2 - 1;
    
    
    
    ////main
    //float height = pow(Snowtrail, 0.2) * Noise * NoiseStrength * 0.1;
    //height += (1.0 - Snowtrail);
    
    //GroundHeight = saturate(GroundHeight);
    //GroundHeight += 1;
    
    //float currentHeight = height;//下一步会导致地面吃不到trail信息，这里存一下
    //height = lerp(height, GroundHeight, GroundHeightStrength);
    
    //height *= uvInRange;
    //height += (1.0 - uvInRange);   
    
    //height *= currentHeight;
    //height = clamp(height, 0, 2);
    
    return SnowTrail;
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
    
    GroundHeight = saturate(GroundHeight);
    GroundHeight += 1;
    
    float currentHeight = height;//下一步会导致地面吃不到trail信息，这里存一下
    height = lerp(height, GroundHeight, GroundHeightStrength);
    
    height *= uvInRange;
    height += (1.0 - uvInRange);   
    
    height *= currentHeight;
    height = clamp(height, 0, 2);
    
    return height;
}



float CalcSnowHeight(float Height, float SnowHeight)
{
    return Height * SnowHeight * 0.5;
}

