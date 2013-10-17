//
//  TVCAppDelegate.h
//  TriviaCast
//
//  Created by John Brophy on 9/18/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <UIKit/UIKit.h>


@class GCKContext;
@class GCKDevice;
@class GCKDeviceManager;
@class TVCDataSource;

@interface TVCAppDelegate : UIResponder <UIApplicationDelegate>

@property(nonatomic, strong, readonly) GCKContext *context;

@property(nonatomic, strong, readonly) TVCDataSource *dataSource;

@property(nonatomic, strong) UIWindow *window;

@property(nonatomic, strong) GCKDeviceManager *deviceManager;

- (NSString *)userName;
- (void)setUserName:(NSString *)userName;

@end

#define appDelegate ((TVCAppDelegate *) [UIApplication sharedApplication].delegate)
