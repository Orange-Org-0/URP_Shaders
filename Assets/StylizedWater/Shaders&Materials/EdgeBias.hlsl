#ifndef STYLIZED_WATER_EDGE_BIAS_INCLUDED
#define STYLIZED_WATER_EDGE_BIAS_INCLUDED

void EdgeBias_float(float X, float S, out float Out)
{
    float u = saturate(X);
    float p = S + 1.0;

    if (u <= 0.5)
    {
        Out = 0.5 * pow(2.0 * u, p);
    }
    else
    {
        Out = 1.0 - 0.5 * pow(2.0 * (1.0 - u), p);
    }
}

void EdgeBias_half(half X, half S, out half Out)
{
    half u = saturate(X);
    half p = S + 1.0h;

    if (u <= 0.5h)
    {
        Out = 0.5h * pow(2.0h * u, p);
    }
    else
    {
        Out = 1.0h - 0.5h * pow(2.0h * (1.0h - u), p);
    }
}

#endif
