//
//  ParentLayer.m
//  OpenGLES2.0Test
//
//  Created by Michael Chen on 7/19/16.
//  Copyright © 2016 michael. All rights reserved.
//

#import "ParentLayer.h"
#import <GLKit/GLKit.h>
#import <libkern/OSAtomic.h>


@implementation ParentLayer

// Attribute index.
enum {
    ATTRIB_VERTEX,
    ATTRIB_TEXTURE_COORD,
    NUM_ATTRIBUTES
};

// Uniform index.
enum {
    UNIFORM_MVP_MATRIX,
    UNIFORM_TEXTURE,
    NUM_UNIFORMS
};
GLint uniforms[NUM_UNIFORMS];

static GLfloat vertices[] =  {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f, 1.0f,
    1.0f, -1.0f,
    1.0f, 1.0f,
    -1.0f, 1.0f
};

GLuint indices[] = {
    0, 1, 2,
    1, 4, 5
};

GLfloat texCoords[] = {
    -1.0f, -1.0f,
    1.0f, -1.0f,
    -1.0f, 1.0f,
    1.0f, -1.0f,
    1.0f, 1.0f,
    -1.0f, 1.0f
};

GLfloat vertices2[] = {
    0.0f,  0.5f, 0.5f,
    -0.5f, -0.5f, 0.5f,
    0.5f, -0.5f, 0.5f,
};

- (void) setup {
    self.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking,
                               kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat,
                               nil];
    
    [self setupContext];
    [self setupBuffers];
    [self loadShaders];
    [self setupVAO];
}

- (void) setupContext {
    if (!context) {
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        if (!context) {
            NSLog(@"Failed to create ES context");
        }
    }
    
    offscreenContext = [[EAGLContext alloc] initWithAPI:[context API] sharegroup: [context sharegroup]];
    
    if (!offscreenContext) {
        NSLog(@"Failed to initialize OpenGLES 1.0 off screen context");
        exit(1);
    }
}

- (void) setupBuffers {
    [EAGLContext setCurrentContext:context];
    
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    
    glGenRenderbuffers(1, &renderbuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, renderbuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, renderbuffer);
    [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
    
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
    
    //prepare the texture for drawing onto the object later
    [self loadModelToTexture:&textureName0];
    [self loadModelToTexture:&textureName1];
    
    currentTex = textureName0;
}

- (void) setupVAO {
    glGenVertexArraysOES(1, &vaoId);
    glBindVertexArrayOES(vaoId);
    
    glGenBuffers(1, &vbo);
    glBindBuffer(GL_ARRAY_BUFFER, vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, GL_FALSE, 0, vertices);
}

//This method prepares the necessary program initiation and shader attachments to draw objects
- (BOOL) prepareTexture {
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    program2 = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader2" ofType:@"vsh"];
    
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader2" ofType:@"fsh"];
    
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // Attach vertex shader to program.
    glAttachShader(program2, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program2, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(program2, ATTRIB_VERTEX, "position");
    glBindAttribLocation(program2, ATTRIB_TEXTURE_COORD, "texture_coord");
    
    // Link program.
    if (![self linkProgram:program2]) {
        NSLog(@"Failed to link program: %d", program2);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        
        if (program2) {
            glDeleteProgram(program2);
            program = 0;
        }
        
        return FALSE;
    }
    
    // Release vertex and fragment shaders.
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    return TRUE;
}

//This method is supposed to draw a triangle into the texture we are going to apply later
- (BOOL) loadModelToTexture: (GLuint*) tex {
    GLenum status;
    
    //prepare the program used for this texture
    [self prepareTexture];
    
    // Use texture program
    glUseProgram(program2);
    
    glGenFramebuffers(1, &textureFBO);
    
    // Set up the FBO with one texture attachment
    glBindFramebuffer(GL_FRAMEBUFFER, textureFBO);
    glGenTextures(1, tex);
    glBindTexture(GL_TEXTURE_2D, *tex);
    
    NSLog(@"Error1: %x", glGetError());
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, 128, 128, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, *tex, 0);
    
    status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    
    if (status != GL_FRAMEBUFFER_COMPLETE) {
        // Handle error here
        NSLog(@"Loading model to texture failed");
        return FALSE;
    }
    
//    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);  // Set color's clear-value to red
//    glClearDepthf(1.0f);            // Set depth's clear-value to farthest
//    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
//    glViewport(0, 0, 128, 128);
//    
//    NSLog(@"Error2: %x", glGetError());
//    
//    // Update attribute values.
//    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, 0, 0, vertices2);
//    glEnableVertexAttribArray(ATTRIB_VERTEX);
//    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    NSLog(@"Error3: %x", glGetError());
    
    return TRUE;
}

-(void)updateTexture {
    
    // Create shader program.
    glUseProgram(program2);
    
    glBindFramebuffer(GL_FRAMEBUFFER, textureFBO);
    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);  // Set color's clear-value to green
//    glClearDepthf(1.0f);            // Set depth's clear-value to farthest
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glViewport(0, 0, 128, 128); //self.frame.size.width*self.contentsScale, self.frame.size.height*self.contentsScale);
    
    // Update attribute values.
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, 0, vertices2);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    if (increaseSize) {
        for (int i = 0; i < sizeof(vertices2)/sizeof(vertices2[0]); i += 1) {
            vertices2[i] *= 1.01;
        }
    } else {
        for (int i = 0; i < sizeof(vertices2)/sizeof(vertices2[0]); i += 1) {
            vertices2[i] *= 0.99;
        }
    }
    
    if (vertices2[1] < 0.25) {
        OSAtomicTestAndSet(7, &increaseSize);
        
    } else if (vertices2[1] > 1.0) {
        OSAtomicTestAndClear(7, &increaseSize);
    }
    
    NSLog(@"Vertex Size: %f", vertices2[1]);
    
}

- (void) renderTexture: (GLuint) tex {
    [EAGLContext setCurrentContext:offscreenContext];
    
    // Set binding for FBO and texture to prepare for rendering
    glBindFramebuffer(GL_FRAMEBUFFER, textureFBO);
    glBindTexture(GL_TEXTURE_2D, tex);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, tex, 0);
    
    // Specify shader program to use
    glUseProgram(program2);
    
    glBindFramebuffer(GL_FRAMEBUFFER, textureFBO);
    glClearColor(1.0f, 0.0f, 0.0f, 1.0f);  // Set color's clear-value to red
//    glClearDepthf(1.0f);            // Set depth's clear-value to farthest
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glViewport(0, 0, 128, 128); //self.frame.size.width*self.contentsScale, self.frame.size.height*self.contentsScale);
    
    // Update attribute values.
    glVertexAttribPointer(ATTRIB_VERTEX, 3, GL_FLOAT, GL_FALSE, 0, vertices2);
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    glFlush();
    
    if (increaseSize) {
        for (int i = 0; i < sizeof(vertices2)/sizeof(vertices2[0]); i += 1) {
            vertices2[i] *= 1.01;
        }
    } else {
        for (int i = 0; i < sizeof(vertices2)/sizeof(vertices2[0]); i += 1) {
            vertices2[i] *= 0.99;
        }
    }
    
    if (vertices2[1] < 0.25) {
        OSAtomicTestAndSet(7, &increaseSize);
        
    } else if (vertices2[1] > 1.0) {
        OSAtomicTestAndClear(7, &increaseSize);
    }
    
    NSLog(@"%f", vertices2[1]);
}

- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load vertex shader");
        return FALSE;
    }
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    
    if (status == 0) {
        NSLog(@"Failed to compile shader");
        glDeleteShader(*shader);
        return FALSE;
    }
    
    return TRUE;
}

//This method loads the shaders and initiates the program for the main shape-drawingprogram
- (BOOL)loadShaders {
    GLuint vertShader, fragShader;
    NSString *vertShaderPathname, *fragShaderPathname;
    
    // Create shader program.
    program = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"vsh"];
    
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return FALSE;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:@"Shader" ofType:@"fsh"];
    
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return FALSE;
    }
    
    // Attach vertex shader to program.
    glAttachShader(program, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(program, fragShader);
    
    // Bind attribute locations.
    // This needs to be done prior to linking.
    glBindAttribLocation(program, ATTRIB_VERTEX, "position");
    glBindAttribLocation(program, ATTRIB_TEXTURE_COORD, "texture_coord");
    
    // Link program.
    if (![self linkProgram:program]) {
        NSLog(@"Failed to link program: %d", program);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        
        if (program) {
            glDeleteProgram(program);
            program = 0;
        }
        
        return FALSE;
    }
    
    // Release vertex and fragment shaders.
    if (vertShader)
        glDeleteShader(vertShader);
    if (fragShader)
        glDeleteShader(fragShader);
    
    return TRUE;
}

- (BOOL)linkProgram:(GLuint)prog {
    GLint status;
    
    glLinkProgram(prog);
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    
    if (status == 0)
        return FALSE;
    
    return TRUE;
}

- (void) draw {
    if (firstFull || secondFull) {
        [self setAtomicBit];
    }
    
    if (currentTex == 0) {
        OSAtomicTestAndSet(7, &firstFull);
        [self renderTexture:textureName0];
        OSAtomicTestAndSet(7, &currentTex);

    } else {
        OSAtomicTestAndSet(7, &secondFull);
        [self renderTexture:textureName1];
        OSAtomicTestAndClear(7, &currentTex);
    }
    
    //displaying the currentframebuffer to the screen
    dispatch_async(dispatch_get_main_queue(), ^{
        [self displayOnscreen];
    });
}


- (void) displayOnscreen {
    [EAGLContext setCurrentContext:context];
    
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    
    // Use shader program.
    glUseProgram(program);
    
    glClearColor(0.0f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glViewport(0, 0, self.frame.size.width*self.contentsScale, self.frame.size.height*self.contentsScale);
    
//    // Update attribute values.
    glEnableVertexAttribArray(ATTRIB_VERTEX);
    glVertexAttribPointer(ATTRIB_VERTEX, 2, GL_FLOAT, 0, 0, vertices);

    //for some reason this is unneeded, but I'm not sure why
//    glVertexAttribPointer(ATTRIB_TEXTURE_COORD, 2, GL_FLOAT, 0, 0, texCoords);
//    glEnableVertexAttribArray(ATTRIB_TEXTURE_COORD);
    
    glBindVertexArrayOES(vaoId);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    if (currentTex == textureName0) {
        glBindTexture(GL_TEXTURE_2D, textureName0);
    } else {
        glBindTexture(GL_TEXTURE_2D, textureName1);
    }
    
    glDrawArrays(GL_TRIANGLES, 0, 3);
    glDrawArrays(GL_TRIANGLES, 3, 3);
    
//    [context presentRenderbuffer:GL_RENDERBUFFER];
    
    //clear to show that we swapped
    [self clearAtomicBit];
}

- (BOOL) canRender {
    //Return the opposite since the bit starts at 0
    return !atomicBit;
}

- (void) setAtomicBit {
    OSAtomicTestAndSet(7, &atomicBit);
}

- (void) clearAtomicBit {
    OSAtomicTestAndClear(7, &atomicBit);
}

@end
