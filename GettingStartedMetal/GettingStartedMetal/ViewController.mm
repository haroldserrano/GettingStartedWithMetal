//
//  ViewController.m
//  GettingStartedMetal
//
//  Created by Harold Serrano on 12/23/16.
//  Copyright © 2016 Harold Serrano. All rights reserved.
//

#import "ViewController.h"
#import <simd/simd.h>
#include "models.h"
#include <vector>
#include "lodepng.h"

@interface ViewController ()

@end


@implementation ViewController{
    
    id<MTLDevice> mtlDevice;
    
    id <MTLCommandQueue> mtlCommandQueue;
    
    id<MTLRenderPipelineState> renderPipelineState;
    
    id<MTLDepthStencilState> depthStencilState;
    
    id <CAMetalDrawable> frameDrawable;
    
    MTLRenderPipelineDescriptor *mtlRenderPipelineDescriptor;
    
    
    
    CAMetalLayer *metalLayer;
    
    CADisplayLink *displayLink;
    
    //Attribute
    id<MTLBuffer> vertexAttribute;
    
    id<MTLBuffer> normalAttribute;
    
    id<MTLBuffer> uvAttribute;
    
    id<MTLBuffer> indicesBuffer;
    
    //Uniform
    id<MTLBuffer> mvpMatrixUniform;
    
    id<MTLBuffer> mvMatrixUniform;
    
    id<MTLBuffer> normalMatrixUniform;
    
    id<MTLTexture> texture;
    
    id<MTLSamplerState> samplerState;
    
    //light
    id<MTLBuffer> mvLightUniform;
    
    //touch position
    float xPosition;
    float yPosition;
    
    // Decode image raw data
    std::vector<unsigned char> rawImageData;
    unsigned int imageWidth;
    unsigned int imageHeight;
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
    
    
    MTLDepthStencilDescriptor *depthStencilDescriptor = [[MTLDepthStencilDescriptor alloc] init];
    depthStencilDescriptor.depthCompareFunction = MTLCompareFunctionLess;
    depthStencilDescriptor.depthWriteEnabled = YES;
    depthStencilState=[mtlDevice newDepthStencilStateWithDescriptor:depthStencilDescriptor];
    
    
    //create the Rendering Pipeline Object
    renderPipelineState=[mtlDevice newRenderPipelineStateWithDescriptor:mtlRenderPipelineDescriptor error:nil];
    
    //6. create resources
    
    //6a. load the data attribute into the buffer
    vertexAttribute=[mtlDevice newBufferWithBytes:smallHouseVertices length:sizeof(smallHouseVertices) options:MTLResourceOptionCPUCacheModeDefault];
    
    //6b. load normal vector attribute data into the buffer
    normalAttribute=[mtlDevice newBufferWithBytes:smallHouseNormals length:sizeof(smallHouseNormals) options:MTLResourceOptionCPUCacheModeDefault];
    
    //6c. Load UV-Coordinate attribute data into the buffer
    uvAttribute=[mtlDevice newBufferWithBytes:smallHouseUV length:sizeof(smallHouseUV) options:MTLResourceCPUCacheModeDefaultCache];
    
    //6d. load the index into the buffer
    indicesBuffer=[mtlDevice newBufferWithBytes:smallHouseIndices length:sizeof(smallHouseIndices) options:MTLResourceOptionCPUCacheModeDefault];
    
    //7. Decode the image-Obtains a pointer to the raw data.
    [self decodeImage];
    
    //8. Create a Texture Object and load the image raw data
    [self createTextureObject];
    
    //9. Create a Sampler State Object and set the filtering parameters
    [self createSamplerObject];
    
    
    //set initial position to 0
    xPosition=0.0;
    yPosition=0.0;
    
    //Set the display link object to call the renderscene method continuously
    displayLink=[CADisplayLink displayLinkWithTarget:self selector:@selector(renderPass)];
    
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    
}

-(void) createTextureObject{
    
    //1. create the texture descriptor
    MTLTextureDescriptor *textureDescriptor=[MTLTextureDescriptor texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm width:imageWidth height:imageHeight mipmapped:NO];
    
    //2. create the texture object
    texture=[mtlDevice newTextureWithDescriptor:textureDescriptor];
    
    //3. copy the raw image data into the texture object
    
    MTLRegion region=MTLRegionMake2D(0, 0, imageWidth, imageHeight);
    
    [texture replaceRegion:region mipmapLevel:0 withBytes:&rawImageData[0] bytesPerRow:4*imageWidth];
  
}

-(void) createSamplerObject{
    
    //1. create a Sampler Descriptor
    MTLSamplerDescriptor *samplerDescriptor=[[MTLSamplerDescriptor alloc] init];
    
    //2. Set the filtering and addressing settings
    samplerDescriptor.minFilter=MTLSamplerMinMagFilterLinear;
    samplerDescriptor.magFilter=MTLSamplerMinMagFilterLinear;
    samplerDescriptor.sAddressMode=MTLSamplerAddressModeClampToEdge;
    samplerDescriptor.tAddressMode=MTLSamplerAddressModeClampToEdge;
    
    //3. Create the Sampler State object
    samplerState=[mtlDevice newSamplerStateWithDescriptor:samplerDescriptor];
    
}

-(void) decodeImage{
    
    //name of image in project.
    std::string uTexture="small_house_01.png";
    
    imageWidth=0.0;
    imageHeight=0.0;
    
    // Load file and decode image.
    const char * textureImage = uTexture.c_str();
    
    unsigned error = lodepng::decode(rawImageData, imageWidth, imageHeight,textureImage);
    
    //if there's an error, display it
    if(error){
        std::cout << "decoder error " << error << ": " <<uTexture<<" file is "<< lodepng_error_text(error) << std::endl;
    }else{
        
        //Flip and invert the image
        unsigned char* imagePtr=&rawImageData[0];
        
        int halfTheHeightInPixels=imageHeight/2;
        int heightInPixels=imageHeight;
        
        
        //Assume RGBA for 4 components per pixel
        int numColorComponents=4;
        
        //Assuming each color component is an unsigned char
        int widthInChars=imageWidth*numColorComponents;
        
        unsigned char *top=NULL;
        unsigned char *bottom=NULL;
        unsigned char temp=0;
        
        for( int h = 0; h < halfTheHeightInPixels; ++h )
        {
            top = imagePtr + h * widthInChars;
            bottom = imagePtr + (heightInPixels - h - 1) * widthInChars;
            
            for( int w = 0; w < widthInChars; ++w )
            {
                // Swap the chars around.
                temp = *top;
                *top = *bottom;
                *bottom = temp;
                
                ++top;
                ++bottom;
            }
        }
    }
    
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
    mtlRenderPassDescriptor.colorAttachments[0].clearColor=MTLClearColorMake(0.0, 0.0, 0.0, 1.0);
    mtlRenderPassDescriptor.colorAttachments[0].storeAction=MTLStoreActionStore;
    
    //9. create a command buffer
    id<MTLCommandBuffer> mtlCommandBuffer=[mtlCommandQueue commandBuffer];
    
    //10. create a command encoder
    
    //10a. creat a command encoder
    id<MTLRenderCommandEncoder> renderEncoder=[mtlCommandBuffer renderCommandEncoderWithDescriptor:mtlRenderPassDescriptor];
    
    //10b. Configure enconder with the pipeline
    [renderEncoder setRenderPipelineState:renderPipelineState];
    
    //10c. set the vertex buffer object and the index for the data
    [renderEncoder setVertexBuffer:vertexAttribute offset:0 atIndex:0];
    
    [renderEncoder setVertexBuffer:normalAttribute offset:0 atIndex:1];
    
    //10d. set the uniform buffer and the index for the data
    [renderEncoder setVertexBuffer:mvpMatrixUniform offset:0 atIndex:2];
    
    //10e. set the uniform buffer for the normal matrix
    [renderEncoder setVertexBuffer:normalMatrixUniform offset:0 atIndex:3];
    
    //10f. set the uniform buffer for the Model-View Matrix
    [renderEncoder setVertexBuffer:mvMatrixUniform offset:0 atIndex:4];
    
    //10g. Set the uniform for the Light position
    [renderEncoder setVertexBuffer:mvLightUniform offset:0 atIndex:5];
    
    //10h. Set the vertex buffer for the uv Attribute
    [renderEncoder setVertexBuffer:uvAttribute offset:0 atIndex:6];
    
    //10i. Set the fragment texture
    [renderEncoder setFragmentTexture:texture atIndex:0];
    
    //10j. set the fragment sampler
    [renderEncoder setFragmentSamplerState:samplerState atIndex:0];
    
    //10k.
    [renderEncoder setDepthStencilState:depthStencilState];
    
    //10l.
    [renderEncoder setFrontFacingWinding:MTLWindingCounterClockwise];
    
    //10m.
    [renderEncoder setCullMode:MTLCullModeFront];
    
    //10n. Set the draw command
    [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangle indexCount:[indicesBuffer length]/sizeof(uint16_t) indexType:MTLIndexTypeUInt16 indexBuffer:indicesBuffer indexBufferOffset:0];
    
    //10p. End encoding
    [renderEncoder endEncoding];
    
    //11. present the drawable
    [mtlCommandBuffer presentDrawable:frameDrawable];
    
    //12. buffer is ready
    [mtlCommandBuffer commit];
}

-(void)updateTransformation{
    
    
    //Rotate the model and produce the model matrix
    matrix_float4x4 modelMatrix=matrix_from_rotation(-150.0*M_PI/180, 0.0, 1.0, 0.0);
    
    //set the world matrix to its identity matrix.i.e, no transformation. It's origin is at 0,0,0
    matrix_float4x4 worldMatrix=matrix_identity_float4x4;
    
    //Set the camera position in the z-direction
    matrix_float4x4 viewMatrix=matrix_multiply(matrix_from_rotation(-10.0*M_PI/180, 1.0, 0.0, 0.0),matrix_from_translation(0.0, -3.0, 10.0));
    
    //compute the projective-perspective matrix
    float aspect=self.view.bounds.size.width/self.view.bounds.size.height;
    
    matrix_float4x4 projectiveMatrix=matrix_from_perspective_fov_aspectLH(45.0f * (M_PI / 180.0f), aspect, 0.1f, 100.0f);
    
    //Transform the model into the world's coordinate space
    matrix_float4x4 modelWorldTransformation=matrix_multiply(worldMatrix, modelMatrix);
    
    //Transform the Model-World Space into the camera's coordinate space
    matrix_float4x4 modelViewTransformation=matrix_multiply(viewMatrix, modelWorldTransformation);
    
    //Transfom the Model-View Space into the Projection space
    matrix_float4x4 modelViewProjectionTransformation=matrix_multiply(projectiveMatrix, modelViewTransformation);
    
    //Load the MVP transformation into the MTLBuffer
    mvpMatrixUniform=[mtlDevice newBufferWithBytes:(void*)&modelViewProjectionTransformation length:sizeof(modelViewProjectionTransformation) options:MTLResourceOptionCPUCacheModeDefault];
    
    //get normal matrix
    matrix_float3x3 normalMatrix={modelViewTransformation.columns[0].xyz,modelViewTransformation.columns[1].xyz,modelViewTransformation.columns[2].xyz};
    
    normalMatrix=matrix_transpose(matrix_invert(normalMatrix));
    
    //load the NormalMatrix into the MTLBuffer
    normalMatrixUniform=[mtlDevice newBufferWithBytes:(void*)&normalMatrix length:sizeof(normalMatrix) options:MTLResourceOptionCPUCacheModeDefault];

    //load the mv transfomration into the MTLBuffer
    mvMatrixUniform=[mtlDevice newBufferWithBytes:(void*)&modelViewTransformation length:sizeof(modelViewTransformation) options:MTLResourceOptionCPUCacheModeDefault];
    
    //light position
    
    vector_float4 lightPosition={static_cast<float>(xPosition*5.0),static_cast<float>(yPosition*5.0+10.0),-5.0,1.0};
    
    // transform the light position
    lightPosition=matrix_multiply(viewMatrix, lightPosition);
    
    // load the light position into the MTLBuffer
    mvLightUniform=[mtlDevice newBufferWithBytes:(void*)&lightPosition length:sizeof(lightPosition) options:MTLResourceCPUCacheModeDefaultCache];
    
 
}


#pragma mark Linear Algebra Utilities

static matrix_float4x4 matrix_from_perspective_fov_aspectLH(const float fovY, const float aspect, const float nearZ, const float farZ)
{
    float yscale = 1.0f / tanf(fovY * 0.5f); // 1 / tan == cot
    float xscale = yscale / aspect;
    float q = farZ / (farZ - nearZ);
    
    matrix_float4x4 m = {
        .columns[0] = { xscale, 0.0f, 0.0f, 0.0f },
        .columns[1] = { 0.0f, yscale, 0.0f, 0.0f },
        .columns[2] = { 0.0f, 0.0f, q, 1.0f },
        .columns[3] = { 0.0f, 0.0f, q * -nearZ, 0.0f }
    };
    
    return m;
}

static matrix_float4x4 matrix_from_translation(float x, float y, float z)
{
    matrix_float4x4 m = matrix_identity_float4x4;
    m.columns[3] = (vector_float4) { x, y, z, 1.0 };
    return m;
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
        xPosition=(touchPosition.x-self.view.bounds.size.width/2)/(self.view.bounds.size.width/2);
        yPosition=(self.view.bounds.size.height/2-touchPosition.y)/(self.view.bounds.size.height/2);
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
        
        xPosition=(touchPosition.x-self.view.bounds.size.width/2)/(self.view.bounds.size.width/2);
        yPosition=(self.view.bounds.size.height/2-touchPosition.y)/(self.view.bounds.size.height/2);
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
