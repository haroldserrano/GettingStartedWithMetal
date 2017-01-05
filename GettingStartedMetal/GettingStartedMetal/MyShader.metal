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
    .ambientColor={0.1,0.1,0.1},
    .diffuseColor={0.5, 0.5, 0.5},
    .specularColor={1.0,1.0,1.0}
};

constant Material material={
    
    .ambientColor={0.1,0.1,0.1},
    .diffuseColor={1.0,1.0,1.0},
    .specularColor={1.0,1.0,1.0},
    .specularPower=5
    
};


vertex VertexOutput vertexShader(device float4 *vertices [[buffer(0)]], device float4 *normal [[buffer(1)]], constant float4x4 &mvp [[buffer(2)]], constant float3x3 &normalMatrix [[buffer(3)]], constant float4x4 &mvMatrix[[buffer(4)]], constant float4 &lightPosition[[buffer(5)]], device float2 *uv [[buffer(6)]], uint vid [[vertex_id]]){
    
    VertexOutput vertexOut;
    
    //1. transform the vertices by the mvp transformation
    float4 pos=mvp*vertices[vid];
    
    //2. transform the normal vectors by the normal matrix space
    
    float3 normalVectorInMVSpace=normalize(normalMatrix*normal[vid].xyz);
    
    //3. transform the vertices of the surface into the Model-View Space
    float4 verticesInMVSpace=mvMatrix*vertices[vid];
    
    //4. Compute the direction of the light ray betweent the light position and the vertices of the surface
    float3 lightRayDirection=normalize(lightPosition.xyz-verticesInMVSpace.xyz);
    
    
    //5. Compute View Vector
    float3 viewVector=normalize(-verticesInMVSpace.xyz);
    
    //6. Compute reflection vector
    float3 reflectionVector=reflect(-lightRayDirection,normalVectorInMVSpace);

    //COMPUTE LIGHTS
    
    //compute ambient lighting
    float3 ambientLight=light.ambientColor*material.ambientColor;
    
    //7. compute diffuse intensity by computing the dot product. We obtain the maximum the value between 0 and the dot product
    float diffuseIntensity=max(0.0,dot(normalVectorInMVSpace,lightRayDirection));
    
    //8. compute Diffuse Color
    float3 diffuseLight=diffuseIntensity*light.diffuseColor*material.diffuseColor;
    
    //9. compute specular lighting
    float3 specularLight=float3(0.0,0.0,0.0);
    
    if(diffuseIntensity>0.0){
        
        specularLight=light.specularColor*material.specularColor*pow(max(dot(reflectionVector,viewVector),0.0),material.specularPower);
        
    }
    
    //10. Add total lights
    float4 totalLights=float4(ambientLight+diffuseLight+specularLight,1.0);

    //11.. Pass the light color to the fragment shader
    vertexOut.color=totalLights;
    
    //12. Pass the uv coordinates to the fragment shader
    vertexOut.uvcoords=uv[vid];
    
    vertexOut.position=pos;

    return vertexOut;
    
}


fragment float4 fragmentShader(VertexOutput vertexOut [[stage_in]], texture2d<float> texture [[texture(0)]], sampler sam [[sampler(0)]]){
    
    //sample the texture color
    float4 sampledColor=texture.sample(sam, vertexOut.uvcoords);
    
    //UNCOMMENT THIS LINE IF YOU WANT TO COMBINE THE LIGHT COLOR WITH THE TEXTURE. set color fragment to the mix value of the shading and sampled color
    //return float4(mix(sampledColor,vertexOut.color,0.5));
    
    return float4(vertexOut.color);
}
