//
//  TVCLobbyViewController.h
//  TriviaCast
//
//  Created by John Brophy on 9/19/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GCKFramework/GCKFramework.h>
@class TVCDataSource;

@interface TVCLobbyViewController : UIViewController

@property (nonatomic, strong) GCKDevice * device;
@property (nonatomic, strong) TVCDataSource * dataSource;

- (void) segueToResponseViewWithCue:(NSString*)cue;
-(void) segueToReaderViewWithResponses:(NSDictionary *)responseDictionary;
-(void) segueToGuesserViewWithResponses:(NSDictionary *)responseDictionary andPlayers:(NSArray*)players;

@end
