//
//  MyShader.metal
//  GettingStartedMetal
//
//  Created by Harold Serrano on 12/23/16.
//  Copyright © 2016 Harold Serrano. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct VertexOutput{
    
    float4 position [[position]];
    float2 uvcoords;
    float4 color;
    
};


vertex VertexOutput vertexShader(device float4 *vertices [[buffer(0)]], device float4 *normal [[buffer(1)]], constant float4x4 &mvp [[buffer(2)]], constant float3x3 &normalMatrix [[buffer(3)]], constant float4x4 &mvMatrix[[buffer(4)]], constant float4 &lightPosition[[buffer(5)]], device float2 *uv [[buffer(6)]], uint vid [[vertex_id]]){
    
    VertexOutput vertexOut;
    
    float4 lightColor=float4(0.9, 0.9, 0.9,1.0);
    
    //1. transform the vertices by the mvp transformation
    float4 pos=mvp*vertices[vid];
    
    //2. transform the normal vectors by the normal matrix space
    
    float3 normalVectorInMVSpace=normalize(normalMatrix*normal[vid].xyz);
    
    //3. transform the vertices of the surface into the Model-View Space
    float4 verticesInMVSpace=mvMatrix*vertices[vid];
    
    //4. Compute the direction of the light ray betweent the light position and the vertices of the surface
    float3 lightRayDirection=normalize(lightPosition.xyz-verticesInMVSpace.xyz);
    
    //5. compute shading intensity by computing the dot product. We obtain the maximum the value between 0 and the dot product
    
    float shadingIntensity=max(0.0,dot(normalVectorInMVSpace,lightRayDirection));
    
    //6. Multiply the shading intensity by a light color
    
    float4 shadingColor=shadingIntensity*lightColor;

    //7a. Pass the shading color to the fragment shader
    vertexOut.color=shadingColor;
    
    //7b. Pass the uv coordinates to the fragment shader
    vertexOut.uvcoords=uv[vid];
    
    vertexOut.position=pos;

    return vertexOut;
    
}


fragment float4 fragmentShader(VertexOutput vertexOut [[stage_in]], texture2d<float> texture [[texture(0)]], sampler sam [[sampler(0)]]){
    
    //sample the texture color
    float4 sampledColor=texture.sample(sam, vertexOut.uvcoords);
    
    //set color fragment to the mix value of the shading and sampled color
    return float4(mix(sampledColor,vertexOut.color,0.2));
    
}
