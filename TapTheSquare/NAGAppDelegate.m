//
//  NAGAppDelegate.m
//  TapTheSquare
//
//  Created by AndrewShmig on 5/29/14.
//  Copyright (c) 2014 Non Atomic Games Inc. All rights reserved.
//

#import "NAGAppDelegate.h"
#import "iRate.h"
#import "Flurry.h"
#import "FlurryAds.h"
#import "NAGViewController.h"

@implementation NAGAppDelegate

+ (void)initialize
{
    //    настраиваем окно с вопросом об оценке приложения
    [iRate sharedInstance].appStoreID = 884144338;
    [iRate sharedInstance].applicationName = @"Tap The Square";
    [iRate sharedInstance].daysUntilPrompt = 0.1;
    [iRate sharedInstance].usesUntilPrompt = 2;
    [iRate sharedInstance].promptForNewVersionIfUserRated = YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
//    инициализация Flurry
    [Flurry startSession:@"77Q767FQ4DB73MT9JN4X"];
    [FlurryAds initialize:self.window.rootViewController];

//    предварительно запрашиваем рекламку
    [FlurryAds fetchAdForSpace:@"GAME_VIEW" frame:self.window.frame size:FULLSCREEN];

    // Override point for customization after application launch.
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    SKView *skView = (SKView *)[UIApplication sharedApplication].keyWindow.rootViewController.view;
    skView.paused = YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    SKView *skView = (SKView *)[UIApplication sharedApplication].keyWindow.rootViewController.view;
    skView.paused = NO;
}

@end