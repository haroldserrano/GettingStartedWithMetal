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

struct Light{
    
    float3 direction;
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
};

struct Material{
    
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
    float specularPower;
};


constant Light light={
    .direction={3.0,5.0,-3.0},
    .ambientColor={0.05,0.05,0.07},
    .diffuseColor={0.4, 0.4, 0.4},
    .specularColor={1.0,1.0,1.0}
};

constant Material material={
  
    .ambientColor={0.9,0.1,0},
    .diffuseColor={0.9,0.1,0},
    .specularColor={1.0,1.0,1.0},
    .specularPower=100
    
};

vertex VertexOutput vertexShader(device float4 *vertices [[buffer(0)]], device float4 *normal [[buffer(1)]], constant float4x4 &mvp [[buffer(2)]], constant float3x3 &normalMatrix [[buffer(3)]], constant float4x4 &mvMatrix[[buffer(4)]], uint vid [[vertex_id]]){
    
    VertexOutput vertexOut;
    
    //transform the vertices by the mvp transformation
    float4 pos=mvp*vertices[vid];
    
    //compute lighting
    
    float3 eyeNormal=normalize(normalMatrix*normal[vid].xyz);
    float4 eyeCoords=mvMatrix*vertices[vid];
    
    float3 s=normalize(light.direction-eyeCoords.xyz);
    float3 v=normalize(-eyeCoords.xyz);
    float3 r=reflect(-s,eyeNormal);
    
    
    //compute ambient lighting
    float3 ambientLight=light.ambientColor*material.ambientColor;
    
    //compute diffuse lighting
    
    float sDotN=max(0.0,dot(eyeNormal,s));
    
    float3 diffuseLight=sDotN*light.diffuseColor;
    
    //compute specular lighting
    float3 specularLight=float3(0.0,0.0,0.0);
    
    if(sDotN>0.0){
        
        specularLight=light.specularColor*material.specularColor*pow(max(dot(r,v),0.0),material.specularPower);
        
    }
    
    //add total lighting
    float4 totalLights=float4(ambientLight+diffuseLight+specularLight,1.0);
    
    
    vertexOut.position=pos;
    
    vertexOut.color=totalLights;

    return vertexOut;
    
}


fragment float4 fragmentShader(VertexOutput vertexOut [[stage_in]]){
    
    //set color fragment to red
    return float4(vertexOut.color);
    
}
