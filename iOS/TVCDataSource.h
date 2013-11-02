//
//  TVCDataSource.h
//  TriviaCast
//
//  Created by John Brophy on 9/25/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TVCMessageStream.h"
#import "TVCAppDelegate.h"

@class TVCLobbyViewController;

@interface TVCDataSource : NSObject <TVCMessageStreamDelegate, GCKApplicationSessionDelegate>
@property(nonatomic, strong) GCKDevice *device;
@property(nonatomic, strong) TVCPlayer *player;
@property(nonatomic, strong) UIViewController *currentViewController;
@property(nonatomic, strong) TVCLobbyViewController *lobbyViewController;
@property(nonatomic) NSInteger * currentGuess;
-(id) initWithDevice:(GCKDevice*) device;

- (TVCMessageStream *)getMessageStream;

- (BOOL) isReader;
- (BOOL) isGuesser;

@end
