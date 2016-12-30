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
    float4 color;
    
};


vertex VertexOutput vertexShader(device float4 *vertices [[buffer(0)]], device float4 *normal [[buffer(1)]], constant float4x4 &mvp [[buffer(2)]], constant float3x3 &normalMatrix [[buffer(3)]], constant float4x4 &mvMatrix[[buffer(4)]], constant float4 &lightPosition[[buffer(5)]], uint vid [[vertex_id]]){
    
    VertexOutput vertexOut;
    
    float4 lightDiffuseColor=float4(0.9, 0.9, 0.9,1.0);
    
    //transform the vertices by the mvp transformation
    float4 pos=mvp*vertices[vid];
    
    //compute lighting
    
    float3 eyeNormal=normalize(normalMatrix*normal[vid].xyz);
    
    float4 eyeCoords=mvMatrix*vertices[vid];
    
    float3 s=normalize(lightPosition.xyz-eyeCoords.xyz);
    
    //compute diffuse lighting
    
    float sDotN=max(0.0,dot(eyeNormal,s));
    
    float4 diffuseLight=sDotN*lightDiffuseColor;

    //add total lighting
    
    vertexOut.position=pos;
    
    vertexOut.color=diffuseLight;

    return vertexOut;
    
}


fragment float4 fragmentShader(VertexOutput vertexOut [[stage_in]]){
    
    //set color fragment to red
    return float4(vertexOut.color);
    
}
