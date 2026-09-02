#if defined(SHADER_API_D3D11) || defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE) || defined(SHADER_API_VULKAN) || defined(SHADER_API_METAL) || defined(SHADER_API_PSSL)
#define UNITY_CAN_COMPILE_TESSELLATION 1
#define UNITY_domain                 domain
#define UNITY_partitioning           partitioning
#define UNITY_outputtopology         outputtopology
#define UNITY_patchconstantfunc      patchconstantfunc
#define UNITY_outputcontrolpoints    outputcontrolpoints
#endif

float _Tess;
float _MaxTessDistance;

float _SnowHeight;

float4 _OrthCamPos;
float _OrthCamSize;

TEXTURE2D(_SnowTrailTex);
SAMPLER(sampler_SnowTrailTex);

struct Attributes
{
    float4 vertex : POSITION;
    float2 uv : TEXCOORD0;
    float3 normal : NORMAL;
};


struct ControlPoint
{
    float4 vertex : INTERNALTESSPOS;
    float3 normal : NORMAL;
    float2 uv : TEXCOORD0;
   
};


struct TessellationFactors
{
    float edge[3] : SV_TessFactor;
    float inside : SV_InsideTessFactor;
};

struct Varyings
{
    float2 uv : TEXCOORD0;
    float3 WorldPos : TEXCOORD1;
    float3 GroundWorldPos : TEXCOORD3;
    float3 WorldNormal : TEXCOORD2;
    float4 vertex : SV_Position;
    float3 normal : NORMAL;
    float height : TEXCOORD4;
};





float CalcTessFactor(float4 vertex, float minDist, float maxDist, float tess)
{
    float3 WorldPos = TransformObjectToWorld(vertex.xyz);
    float dist = max(0.01f, distance(GetCameraPositionWS().xyz, WorldPos));
    float factor = clamp(1.0 - ((dist - minDist) / (maxDist - minDist)), 0.01, 1);
    return factor * tess;
}

float UVInRange(float2 uv)//return 1 if uv is in range [0,1], else, return 0
{
    return step(0, uv.x) * step(uv.x, 1) * step(0, uv.y) * step(uv.y, 1);
}

float GetTrail(float3 worldPos)
{
    float3 camPos = _OrthCamPos.xyz;
    float2 uv = 0.5 + ((0.5f * (worldPos.xz - camPos.xz)) / _OrthCamSize);   
    float height = UVInRange(uv) * saturate(1.0f - SAMPLE_TEXTURE2D_LOD(_SnowTrailTex, sampler_SnowTrailTex, uv, 0).g);
    height *= UVInRange(uv);
    return max(0, height);
}




Varyings vert(Attributes i)
{
    Varyings o;
    
    
    o.WorldPos = TransformObjectToWorld(i.vertex.xyz);
    o.GroundWorldPos = TransformObjectToWorld(i.vertex.xyz);
    o.uv = i.uv;
  
    float Trail = GetTrail(o.WorldPos);
    float height = Trail * max(0, _SnowHeight);
    o.height = height;
    
    o.WorldNormal = TransformObjectToWorldNormal(i.normal);
    o.normal = i.normal;
    
    
    o.WorldPos.y += height;
    o.vertex = TransformWorldToHClip(o.WorldPos);
    return o;
}




//main
[UNITY_domain("tri")]
[UNITY_outputcontrolpoints(3)]
[UNITY_outputtopology("triangle_cw")]
[UNITY_partitioning("fractional_odd")]
[UNITY_patchconstantfunc("PatchConstantFunction")]
ControlPoint hull(InputPatch<ControlPoint, 3> patch, uint id : SV_OutputControlPointID)
{
    return patch[id];
}

TessellationFactors PatchConstantFunction(InputPatch<ControlPoint, 3> patch)
{
    float tess = _Tess;
    float minDist = 2.0f;
    float maxDist = _MaxTessDistance;
    TessellationFactors f;
    float3 vertFactor;
    //vertex tessfactor
    vertFactor.x = CalcTessFactor(patch[0].vertex, minDist, maxDist, tess);
    vertFactor.y = CalcTessFactor(patch[1].vertex, minDist, maxDist, tess);
    vertFactor.z = CalcTessFactor(patch[2].vertex, minDist, maxDist, tess);
    //vertex to edge & inside
    f.edge[0] = vertFactor.y * 0.5f + vertFactor.z * 0.5f;
    f.edge[1] = vertFactor.x * 0.5f + vertFactor.z * 0.5f;
    f.edge[2] = vertFactor.x * 0.5f + vertFactor.y * 0.5f;
    f.inside = (vertFactor.x + vertFactor.y + vertFactor.z) / 3.0f;
    
    return f;
}


[UNITY_domain("tri")]
Varyings domain(TessellationFactors factors, OutputPatch<ControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation)
{
    Attributes v;
#define Interpolate(fieldname) v.fieldname = patch[0].fieldname * barycentricCoordinates.x + \
                                                patch[1].fieldname * barycentricCoordinates.y + \
                                                    patch[2].fieldname * barycentricCoordinates.z;
    
    Interpolate(vertex);
    Interpolate(normal);
    Interpolate(uv);
    
    
    return vert(v);
}







