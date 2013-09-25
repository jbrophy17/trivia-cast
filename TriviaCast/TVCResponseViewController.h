//
//  TVCResponseViewController.h
//  TriviaCast
//
//  Created by John Brophy on 9/22/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GCKDevice;
@class GCKApplicationSession;
@class TVCPlayer;
@class TVCMessageStream;

@interface TVCResponseViewController : UIViewController

@property(nonatomic, strong) GCKDevice *device;
@property (weak, nonatomic) IBOutlet UILabel *promptLabel;
@property (weak, nonatomic) IBOutlet UITextView *responseTextView;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

- (IBAction)submitAction:(id)sender;

// Creates a GCKApplicationSession to talk to a cast device. Tests can
// override this method to inject a mock session.
- (GCKApplicationSession *)createSession;

// Creates a TicTacToeMessageStream to talk to a TicTacToe app instance on a
// cast device. Tests can override this method to inject a mock stream.
//- (TicTacToeMessageStream *)createMessageStream;

// The name of the current user playing the game on this device.
- (NSString *)currentUserName;

// Shows an alert message. This is used internally for all alert messages,
// which allows tests to easily check the important parts of the alerts.
- (void)showAlertMessage:(NSString *)message
               withTitle:(NSString *)title
                     tag:(NSInteger)tag;

// True if the current player can play.
- (BOOL)isPlayersTurn;

// Once the game has been joined, the player on this device.
- (TVCPlayer*)player;

@end
