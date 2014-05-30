//
//  NAGViewController.m
//  TapTheSquare
//
//  Created by AndrewShmig on 5/29/14.
//  Copyright (c) 2014 Non Atomic Games Inc. All rights reserved.
//

#import "NAGViewController.h"
#import "NAGMyScene.h"

@implementation NAGViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Configure the view.
    SKView *skView = (SKView *) self.view;
#ifdef DEBUG
    skView.showsFPS = YES;
    skView.showsNodeCount = YES;
#endif

    // Create and configure the scene.
    SKScene *scene = [NAGMyScene sceneWithSize:skView.bounds.size];

    // Present the scene.
    [skView presentScene:scene];
}

- (BOOL)shouldAutorotate
{
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

@end
