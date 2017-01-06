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
    float3 normalVectorInMVSpace;
    float4 verticesInMVSpace;
    
};

struct Light{
    
    float3 direction;
    float3 ambientColor;
    float3 diffuseColor;
    float3 specularColor;
};

struct Material{
    
    float3 ambientReflection;
    float3 diffuseReflection;
    float3 specularReflection;
    float specularReflectionPower;
};


constant Light light={
    .ambientColor={0.1,0.1,0.1},
    .diffuseColor={0.5, 0.5, 0.5},
    .specularColor={1.0,1.0,1.0}
};

constant Material material={
    
    .ambientReflection={0.1,0.1,0.1},
    .diffuseReflection={1.0,1.0,1.0},
    .specularReflection={1.0,1.0,1.0},
    .specularReflectionPower=5
    
};


vertex VertexOutput vertexShader(device float4 *vertices [[buffer(0)]], device float4 *normal [[buffer(1)]], constant float4x4 &mvp [[buffer(2)]], constant float3x3 &normalMatrix [[buffer(3)]], constant float4x4 &mvMatrix[[buffer(4)]], device float2 *uv [[buffer(6)]], uint vid [[vertex_id]]){
    
    VertexOutput vertexOut;
    
    //1. transform the vertices by the mvp transformation
    float4 pos=mvp*vertices[vid];
    
    //2. transform the normal vectors by the normal matrix space
    
    float3 normalVectorInMVSpace=normalize(normalMatrix*normal[vid].xyz);
    
    //3. transform the vertices of the surface into the Model-View Space
    float4 verticesInMVSpace=mvMatrix*vertices[vid];
    
    
    //4. Pass the uv coordinates to the fragment shader
    vertexOut.uvcoords=uv[vid];
    
    //5. Pass the position
    vertexOut.position=pos;
    
    //6. Pass the vertices in MV space
    vertexOut.verticesInMVSpace=verticesInMVSpace;
    
    //7. Pass the normal vector in MV space
    vertexOut.normalVectorInMVSpace=normalVectorInMVSpace;

    return vertexOut;
    
}


fragment float4 fragmentShader(VertexOutput vertexOut [[stage_in]], texture2d<float> texture [[texture(0)]], sampler sam [[sampler(0)]], constant float4 &lightPosition[[buffer(1)]]){
    
    //1. sample the texture color
    float4 sampledColor=texture.sample(sam, vertexOut.uvcoords);
    
    //2. Compute the direction of the light ray betweent the light position and the vertices of the surface
    float3 lightRayDirection=normalize(lightPosition.xyz-vertexOut.verticesInMVSpace.xyz);
    
    //3. Compute View Vector
    float3 viewVector=normalize(-vertexOut.verticesInMVSpace.xyz);
    
    //4. Compute reflection vector
    float3 reflectionVector=reflect(-lightRayDirection,vertexOut.normalVectorInMVSpace);
    
    //COMPUTE LIGHTS
    
    //5. compute ambient lighting
    float3 ambientLight=light.ambientColor*material.ambientReflection;
    
    //6. compute diffuse intensity by computing the dot product. We obtain the maximum the value between 0 and the dot product
    float diffuseIntensity=max(0.0,dot(vertexOut.normalVectorInMVSpace,lightRayDirection));
    
    //7. compute Diffuse Color
    float3 diffuseLight=diffuseIntensity*light.diffuseColor*material.diffuseReflection;
    
    //8. compute specular lighting
    float3 specularLight=float3(0.0,0.0,0.0);
    
    if(diffuseIntensity>0.0){
        
        specularLight=light.specularColor*material.specularReflection*pow(max(dot(reflectionVector,viewVector),0.0),material.specularReflectionPower);
        
    }
    
    //9. Add total lights
    float4 totalLights=float4(ambientLight+diffuseLight+specularLight,1.0);
    
    //10. set color fragment to the mix value of the shading and light
    return float4(mix(sampledColor,totalLights,0.5));
    
}
