//
//  MyShader.metal
//  GettingStartedMetal
//
//  Created by Harold Serrano on 12/23/16.
//  Copyright © 2016 Harold Serrano. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

vertex float4 vertexShader(device float4 *vertices [[buffer(0)]], uint vid [[vertex_id]]){
    
    return vertices[vid];
    
}


fragment float4 fragmentShader(float4 in [[stage_in]]){
    
    //set color fragment to red
    return float4(1.0,0.0,0.0,1.0);
    
}
