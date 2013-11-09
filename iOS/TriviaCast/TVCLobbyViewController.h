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
@property (weak, nonatomic) IBOutlet UIButton *roundStartButton;
@property (weak, nonatomic) IBOutlet UIImageView *profileThumbnailImageView;
@property (weak, nonatomic) IBOutlet UILabel *currentScoreLabel;
@property (nonatomic) BOOL missedCue;
@property (nonatomic, strong) NSString * cue;
@property (nonatomic, strong) NSMutableDictionary * imageDict;

@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;

- (void) segueToResponseViewWithCue:(NSString*)cue;
-(void) segueToReaderViewWithResponses:(NSDictionary *)responseDictionary;
-(void) segueToGuesserViewWithResponses:(NSDictionary *)responseDictionary andPlayers:(NSArray*)players;
- (void) updateScoreList;

- (IBAction)startRoundAction:(id)sender;
- (IBAction)quitAction:(id)sender;

@end
