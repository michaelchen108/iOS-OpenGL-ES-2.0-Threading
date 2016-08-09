//
//  ParentLayer.h
//  OpenGLES2.0Test
//
//  Created by Michael Chen on 7/19/16.
//  Copyright © 2016 michael. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

@interface ParentLayer : CAEAGLLayer {
    GLuint framebuffer, textureFBO;
    GLuint vbo;
    GLuint vaoId;
    GLuint program, program2;
    GLuint renderbuffer;
    GLuint depthbuffer;
    GLuint texture;
    GLuint depthRenderbuffer;
    GLuint position, tex_coord;
    GLuint currentTex;
    
    GLint framebufferWidth, framebufferHeight;
    GLuint textureName0, textureName1;
    
    EAGLContext* context;
    EAGLContext* offscreenContext;
    
    int32_t atomicBit;
    int32_t increaseSize;
    int32_t firstFull;
    int32_t secondFull;
    
}

- (void) setup;
- (void) draw;
- (BOOL) canRender;

@end
