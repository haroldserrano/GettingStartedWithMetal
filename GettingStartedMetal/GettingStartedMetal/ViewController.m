//
//  ViewController.m
//  GettingStartedMetal
//
//  Created by Harold Serrano on 12/23/16.
//  Copyright © 2016 Harold Serrano. All rights reserved.
//

#import "ViewController.h"
#import <simd/simd.h>

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
    
    id <CAMetalDrawable> frameDrawable;
    
    MTLRenderPipelineDescriptor *mtlRenderPipelineDescriptor;
    
    CAMetalLayer *metalLayer;
    
    CADisplayLink *displayLink;
    
    //Attribute
    id<MTLBuffer> vertexAttribute;
    
    //Uniform
    id<MTLBuffer> transformationUniform;
    
    //Matrix transformation
    matrix_float4x4 rotationMatrix;
    
    //rotation angle
    float rotationAngle;
    
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
    
    //load the data attribute into the buffer
    vertexAttribute=[mtlDevice newBufferWithBytes:quadVertexData length:sizeof(quadVertexData) options:MTLResourceOptionCPUCacheModeDefault];
    
    
    //set initial rotation Angle to 0
    rotationAngle=0.0;
    
    //Set the display link object to call the renderscene method continuously
    displayLink=[CADisplayLink displayLinkWithTarget:self selector:@selector(renderPass)];
    
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    
}

-(void) renderPass{
    
    //Update Transformation
    [self updateTransformation];
    
    
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
    [renderEncoder setVertexBuffer:vertexAttribute offset:0 atIndex:0];
    
    //set the uniform buffer and the index for the data
    [renderEncoder setVertexBuffer:transformationUniform offset:0 atIndex:1];
    
    //Set the draw command
    [renderEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    
    //End encoding
    [renderEncoder endEncoding];
    
    //11. present the drawable
    [mtlCommandBuffer presentDrawable:frameDrawable];
    
    //12. buffer is ready
    [mtlCommandBuffer commit];
}

-(void)updateTransformation{
    
    //Update the rotation Transformation Matrix
    rotationMatrix=matrix_from_rotation(rotationAngle*M_PI/180, 0.0, 0.0, 1.0);
 
    //Update the Transformation Uniform
    transformationUniform=[mtlDevice newBufferWithBytes:(void*)&rotationMatrix length:sizeof(rotationMatrix) options:MTLResourceOptionCPUCacheModeDefault];
    
}


static matrix_float4x4 matrix_from_rotation(float radians, float x, float y, float z)
{
    vector_float3 v = vector_normalize(((vector_float3){x, y, z}));
    float cos = cosf(radians);
    float cosp = 1.0f - cos;
    float sin = sinf(radians);
    
    matrix_float4x4 m = {
        .columns[0] = {
            cos + cosp * v.x * v.x,
            cosp * v.x * v.y + v.z * sin,
            cosp * v.x * v.z - v.y * sin,
            0.0f,
        },
        
        .columns[1] = {
            cosp * v.x * v.y - v.z * sin,
            cos + cosp * v.y * v.y,
            cosp * v.y * v.z + v.x * sin,
            0.0f,
        },
        
        .columns[2] = {
            cosp * v.x * v.z + v.y * sin,
            cosp * v.y * v.z - v.x * sin,
            cos + cosp * v.z * v.z,
            0.0f,
        },
        
        .columns[3] = { 0.0f, 0.0f, 0.0f, 1.0f
        }
    };
    return m;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    
    for (UITouch *myTouch in touches) {
        CGPoint touchPosition = [myTouch locationInView: [myTouch view]];
        
        //get the x-position of the touch
        rotationAngle=touchPosition.x;
        
    }
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    
    for (UITouch *myTouch in touches) {
        CGPoint touchPosition = [myTouch locationInView: [myTouch view]];
        
        
        
    }
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    
    for (UITouch *myTouch in touches) {
        CGPoint touchPosition = [myTouch locationInView: [myTouch view]];
        
        //get the x-position of the touch
        rotationAngle=touchPosition.x;
        
    }
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
