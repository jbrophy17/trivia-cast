//
//  TVCAppDelegate.m
//  TriviaCast
//
//  Created by John Brophy on 9/18/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCAppDelegate.h"

#import <GCKFramework/GCKFramework.h>
#import "TVCDataSource.h"
#import "TVCCastDiscoveryViewController.h"
#import "TVCSplashScreenView.h"

static NSString *const kUserDefaultsKeyUserName = @"userDefaultsKeyUserName";

@interface TVCAppDelegate ()

@property(nonatomic, strong, readwrite) GCKContext *context;

@end

@implementation TVCAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    self.context = [[GCKContext alloc] initWithUserAgent:@"com.bears.triviaCast"];
    self.deviceManager = [[GCKDeviceManager alloc] initWithContext:self.context];
    //_dataSource = [[TVCDataSource alloc] init];
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    UIActivityIndicatorView *activity = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(self.window.frame.size.width /2 -15, self.window.frame.size.height * (3.0/4.0), 30, 30)];
    [activity setBackgroundColor:[UIColor clearColor]];
    [activity setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleGray];
    
    //Add the splash screen
    TVCSplashScreenView *splashScreen = [[TVCSplashScreenView alloc] initWithTitle:@"TriviaCast" andSubtitle:@"A Game For Friends"];

    UINavigationController* navVC = ((UINavigationController*)self.window.rootViewController);
    [navVC.view addSubview:splashScreen];
    [navVC.view bringSubviewToFront:splashScreen];
    

    //Old Splash screen
    /*
    UIImageView*imageView=[[UIImageView alloc]initWithImage:[UIImage imageNamed:@"splashScreen.png"]];
    [imageView setFrame:self.window.frame];
    [imageView setBackgroundColor:[UIColor whiteColor]];
    [imageView addSubview:activity];
    [activity startAnimating];
     */
//    UINavigationController* navVC = ((UINavigationController*)self.window.rootViewController);
  //  TVCCastDiscoveryViewController* viewController = (TVCCastDiscoveryViewController*)navVC.visibleViewController;
    //[[navVC view] addSubview:imageView];
    //[[navVC view] bringSubviewToFront:imageView];
    //[viewController initialLaunch];
    // as usual
    [self.window makeKeyAndVisible];
    
    //now fade out splash image
    [NSTimer scheduledTimerWithTimeInterval:2.0f target:self selector:@selector(timerFired:) userInfo:splashScreen repeats:NO];
    
    
    
    
    return YES;
}


- (void)timerFired:(NSTimer *)timer
{
    NSLog(@"Timer fired");
    TVCSplashScreenView *imageView = [timer userInfo];
    
    [UIView transitionWithView:self.window duration:0.5f options:UIViewAnimationOptionTransitionNone animations:^(void){imageView.alpha=0.0f;} completion:^(BOOL finished){[imageView removeFromSuperview];}];
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
  
    __block UIBackgroundTaskIdentifier background_task;
    background_task = [application beginBackgroundTaskWithExpirationHandler:^ {
        
        //Clean up code. Tell the system that we are done.
        if (self.dataSource) {
            [[[self dataSource] getMessageStream] leaveGame];
            self.dataSource = nil;
        }
        [application endBackgroundTask: background_task];
        background_task = UIBackgroundTaskInvalid;
    }];
    
    //To make the code block asynchronous
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        //### background task starts
        NSLog(@"Running in the background\n");
        if (self.dataSource) {
            while ([self.dataSource isValid]) {
                [NSThread sleepForTimeInterval:10];
            }
        }
        int counter = 0;
        while(TRUE)
        {
            if (counter > 12) {
                break;
            }
            counter++;
            [NSThread sleepForTimeInterval:10]; //wait for 10 sec
        }
      
        //#### background task ends
        
        //Clean up code. Tell the system that we are done.
        [application endBackgroundTask: background_task];
        background_task = UIBackgroundTaskInvalid;
    });
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     NSLog(@"will become active");
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    if(self.dataSource) {
        [[self.dataSource getMessageStream] leaveGame];
    }
}

- (NSString *)userName {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return [userDefaults stringForKey:kUserDefaultsKeyUserName];
}

- (void)setUserName:(NSString *)userName {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:userName forKey:kUserDefaultsKeyUserName];
}

- (NSString *)applicationDocumentDirectory {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *docs = [paths objectAtIndex:0];
    
    return docs;
}

@end
