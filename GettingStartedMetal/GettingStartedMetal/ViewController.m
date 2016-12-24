//
//  ViewController.m
//  GettingStartedMetal
//
//  Created by Harold Serrano on 12/23/16.
//  Copyright © 2016 Harold Serrano. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

static float quadVertexData[] =
{
    0.5, -0.5, 0.0, 1.0,
    -0.5, -0.5, 0.0, 1.0,
    -0.5,  0.5, 0.0, 1.0,
    
    0.5,  0.5, 0.0, 1.0,
    0.5, -0.5, 0.0, 1.0,
    -0.5,  0.5, 0.0, 1.0
};

@implementation ViewController{
    
    id<MTLDevice> mtlDevice;
    
    id <MTLCommandQueue> mtlCommandQueue;
    
    id<MTLRenderPipelineState> renderPipelineState;
    
    id<MTLBuffer> vertexBuffer;
    
    id <CAMetalDrawable> frameDrawable;
    
    MTLRenderPipelineDescriptor *mtlRenderPipelineDescriptor;
    
    CAMetalLayer *metalLayer;
    
    CADisplayLink *displayLink;
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //1. create device
    mtlDevice=MTLCreateSystemDefaultDevice();
    
    //2. create command queue
    mtlCommandQueue=[mtlDevice newCommandQueue];
    
    //3. set up the layer
    metalLayer=[CAMetalLayer layer];
    metalLayer.device=mtlDevice;
    metalLayer.pixelFormat=MTLPixelFormatBGRA8Unorm;
    metalLayer.frame=self.view.bounds;
    [self.view.layer addSublayer:metalLayer];
    
    //4. create the library
    
    //create a library object
    id<MTLLibrary> mtlLibrary=[mtlDevice newDefaultLibrary];
    
    //create a vertex and fragment function object
    id<MTLFunction> vertexProgram=[mtlLibrary newFunctionWithName:@"vertexShader"];
    id<MTLFunction> fragmentProgram=[mtlLibrary newFunctionWithName:@"fragmentShader"];
    
    //5. build the pipeline
    
    //create a pipeline descriptor
    mtlRenderPipelineDescriptor=[[MTLRenderPipelineDescriptor alloc] init];
    
    //assign the vertex and fragment functions to the descriptor
    [mtlRenderPipelineDescriptor setVertexFunction:vertexProgram];
    [mtlRenderPipelineDescriptor setFragmentFunction:fragmentProgram];
    
    //specify the target-texture pixel format
    mtlRenderPipelineDescriptor.colorAttachments[0].pixelFormat=MTLPixelFormatBGRA8Unorm;
    
    //create the Rendering Pipeline Object
    renderPipelineState=[mtlDevice newRenderPipelineStateWithDescriptor:mtlRenderPipelineDescriptor error:nil];
    
    //6. create resources
    
    //load the data QuadVertexData into the buffer
    vertexBuffer=[mtlDevice newBufferWithBytes:quadVertexData length:sizeof(quadVertexData) options:MTLResourceOptionCPUCacheModeDefault];
    
    //Set the display link object to call the renderscene method continuously
    displayLink=[CADisplayLink displayLinkWithTarget:self selector:@selector(renderScene)];
    
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    
}

-(void) renderScene{
    
    //7. Get the next drawable layer
    frameDrawable=[metalLayer nextDrawable];
    
    //8. create a render pass
    
    //create a render pass descriptor
    MTLRenderPassDescriptor *mtlRenderPassDescriptor =[MTLRenderPassDescriptor renderPassDescriptor];
    
    //set the target texture for the rendering pipeline
    mtlRenderPassDescriptor.colorAttachments[0].texture=frameDrawable.texture;
    
    //set the following states for the pipeline. i.e., clear the texture before each render pass
    mtlRenderPassDescriptor.colorAttachments[0].loadAction=MTLLoadActionClear;
    mtlRenderPassDescriptor.colorAttachments[0].clearColor=MTLClearColorMake(1.0, 1.0, 1.0, 1.0);
    mtlRenderPassDescriptor.colorAttachments[0].storeAction=MTLStoreActionStore;
    
    //9. create a command buffer
    id<MTLCommandBuffer> mtlCommandBuffer=[mtlCommandQueue commandBuffer];
    
    //10. create a command encoder
    
    //creat a command encoder
    id<MTLRenderCommandEncoder> renderEncoder=[mtlCommandBuffer renderCommandEncoderWithDescriptor:mtlRenderPassDescriptor];
    
    //Configure enconder with the pipeline
    [renderEncoder setRenderPipelineState:renderPipelineState];
    
    //set the vertex buffer object and the index for the data
    [renderEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
    
    //Set the draw command
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    
    //End encoding
    [renderEncoder endEncoding];
    
    //11. present the drawable
    [mtlCommandBuffer presentDrawable:frameDrawable];
    
    //12. buffer is ready
    [mtlCommandBuffer commit];
}

-(void)dealloc{
    
    [displayLink invalidate];
    mtlDevice=nil;
    mtlCommandQueue=nil;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
