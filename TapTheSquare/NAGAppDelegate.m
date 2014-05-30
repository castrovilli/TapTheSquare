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

@implementation NAGAppDelegate

+ (void)initialize
{
    //    настраиваем окно с вопросом об оценке приложения
    [iRate sharedInstance].appStoreID = -1; // TODO
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
    [FlurryAds enableTestAds:YES];
    [FlurryAds fetchAdForSpace:@"GAME_VIEW" frame:self.window.frame size:FULLSCREEN];

    // Override point for customization after application launch.
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.

}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.

}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.

}

@end