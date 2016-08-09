//
//  NewViewController.m
//  iOSTextures
//
//  Created by Michael Chen on 6/29/16.
//  Copyright © 2016 michael. All rights reserved.
//

#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "ParentLayer.h"
#import <GLKit/GLKit.h>

@interface ViewController ()

@end

@implementation ViewController {
    ParentLayer* _sublayer;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
}

- (void)viewDidAppear:(BOOL)animated {
    self.view.layer.backgroundColor = [UIColor orangeColor].CGColor;
    self.view.layer.cornerRadius = 20.0;
    self.view.layer.frame = CGRectInset(self.view.layer.frame, 20, 20);
    
    [self setupLayer];
    [self setupDisplayLink];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupLayer {
    _sublayer = [ParentLayer layer];
    _sublayer.contentsScale = [UIScreen mainScreen].nativeScale;
    _sublayer.backgroundColor = [UIColor blueColor].CGColor;
    _sublayer.shadowOffset = CGSizeMake(0, 3);
    _sublayer.shadowRadius = 5.0;
    _sublayer.shadowColor = [UIColor blackColor].CGColor;
    _sublayer.shadowOpacity = 0.8;
    //    _sublayer.frame = CGRectMake(30, 30, 150, 192);
    _sublayer.frame = self.view.bounds;
    _sublayer.opaque = TRUE;
    //    _sublayer.bounds = CGRectMake(30, 30, 150, 192);
    
    [_sublayer setup];
    [self.view.layer addSublayer: _sublayer];
}

- (void) setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
}

- (void) render : (CADisplayLink *) displayLink {
    if ([_sublayer canRender]) {
        dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [_sublayer draw];
        });
    }
}



@end
