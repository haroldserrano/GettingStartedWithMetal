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

vertex VertexOutput vertexShader(device float4 *vertices [[buffer(0)]], device float3 *normal [[buffer(1)]], constant float4x4 &mvp [[buffer(2)]], constant float3x3 &normalMatrix [[buffer(3)]],uint vid [[vertex_id]]){
    
    VertexOutput vertexOut;
    
    //transform the vertices by the mvp transformation
    float4 pos=mvp*vertices[vid];
    
    float3 eyeNormal=normalize(normalMatrix*normal[vid]);
    float3 lightPosition=float3(3.0,3.0,-3.0);
    float4 diffuseColor=float4(0.4,0.4,1.0,1.0);
    
    float nDotVP=max(0.0,dot(eyeNormal,normalize(lightPosition)));
    
    float4 color=diffuseColor*nDotVP;
    
    vertexOut.position=pos;
    vertexOut.color=color;

    return vertexOut;
    
}


fragment float4 fragmentShader(VertexOutput vertexOut [[stage_in]]){
    
    //set color fragment to red
    return float4(vertexOut.color);
    
}
