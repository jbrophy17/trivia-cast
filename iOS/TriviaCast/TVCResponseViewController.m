//
//  TVCResponseViewController.m
//  TriviaCast
//
//  Created by John Brophy on 9/22/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCResponseViewController.h"
#import "TVCAppDelegate.h"
#import "TVCMessageStream.h"
#import "TVCGame.h"

#import <GCKFramework/GCKFramework.h>

static NSString * const kReceiverApplicationName = @"1f96e9a0-9cf0-4e61-910e-c76f33bd42a2";

@interface TVCResponseViewController () <GCKApplicationSessionDelegate, TVCMessageStreamDelegate, UIAlertViewDelegate>
{
    // Game state.
    BOOL _isXsTurn;
    BOOL _isGameInProgress;
    BOOL _isWaitingForMoveToBeSent;
    TVCGame *game;
    // Dongle state and communication.
    GCKApplicationSession *_session;
    GCKApplicationChannel *_channel;
    TVCMessageStream *_messageStream;
}

@property (nonatomic) TVCPlayer * player;

@end

@implementation TVCResponseViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)isPlayersTurn {
    
    
}

- (TVCPlayer*)player {
    
    
}

- (NSString *)currentUserName {
    return [appDelegate userName];
    
}

- (GCKApplicationSession *)createSession {
    return [[GCKApplicationSession alloc] initWithContext:appDelegate.context
                                                   device:self.device];
}

// Start the remote application session when the view appears.
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self startSession];
}

// End the remote application session when the view disappears.
- (void)viewDidDisappear:(BOOL)animated {
    [self endSession];
    [super viewDidDisappear:animated];
}

// Begin the application session with the current device.
- (void)startSession {
    NSAssert(!_session, @"Starting a second session");
    NSAssert(self.device, @"device is nil");
    
    _session = [self createSession];
    _session.delegate = self;
    
    [_session startSessionWithApplication:kReceiverApplicationName];
}

// End the current application session.
- (void)endSession {
    NSAssert(_session, @"Ending non-existent session");
    //[_messageStream leaveGame];
    [_session endSession];
    _session = nil;
    _channel = nil;
    _messageStream = nil;
}

- (TVCMessageStream *)createMessageStream {
    return [[TVCMessageStream alloc] initWithDelegate:self];
}


#pragma mark - GCKApplicationSessionDelegate

// When connected to the session, attempt to join the game if the channel was
// successfully established, or show an error if there is no channel.
- (void)applicationSessionDidStart {
    _channel = _session.channel;
    if (!_channel) {
        NSString *message = NSLocalizedString(@"Could not establish channel.", nil);
        NSLog(@"ERROR: %@", message);//[self showErrorMessage:message popViewControllerOnOK:YES];
        [_session endSession];
    }
    NSLog(@"%@",[_channel description]);
    _messageStream = [self createMessageStream];
    if ([_channel attachMessageStream:_messageStream]) {
        if (_messageStream.messageSink) {
            if (20 < _channel.sendBufferAvailableBytes) {
                if (![_messageStream joinGameWithName:[self currentUserName]]) {
                    NSLog(@"Couldn't join game.");
                }
            } else {
                NSLog(@"_channel.sendBufferAvailableBytes:%d too small.",
                      _channel.sendBufferAvailableBytes);
            }
        } else {
            NSLog(@"Can't send messages.");
        }
    } else {
        NSLog(@"Couldn't attachMessageStream.");
    }
    
    //_gameStatusLabel.text = NSLocalizedString(@"Waiting for opponent\u2026", nil);
}

// Show an error indicating that the game could not be started.
- (void)applicationSessionDidFailToStartWithError:
(GCKApplicationSessionError *)error {
    NSLog(@"castApplicationSessionDidFailToStartWithError: %@",
          [error localizedDescription]);
    _messageStream = nil;
    NSString *message = NSLocalizedString(@"Could not start game.", nil);
    NSLog(@"ERROR: %@", message);//[self showErrorMessage:message popViewControllerOnOK:YES];
}

// If there is an error, show it; otherwise, just nil out the message stream.
- (void)applicationSessionDidEndWithError:
(GCKApplicationSessionError *)error {
    NSLog(@"castApplicationSessionDidEndWithError: %@", error);
    _messageStream = nil;
    if (error) {
        NSString *message = NSLocalizedString(@"Lost connection.", nil);
        NSLog(@"ERROR: %@", message);//[self showErrorMessage:message popViewControllerOnOK:YES];
    }
}

#pragma mark TVCMessageStreamDelegate Methods

- (void)didJoinGameAsPlayer:(TVCPlayer *)player
              withOpponents:(NSArray *)opponents {
    
    game = [[TVCGame alloc] initWithPlayers:opponents];
    self.player = player;
    
    
}


- (void)didFailToJoinWithErrorMessage:(NSString *)message{
    
    
}


- (void)didReceiveReader {
    [self.iconImageView setImage:[UIImage imageNamed:@"readerIcon"]];
}


- (void)didReceiveReaderWithResponses:(NSArray*)responses{
    
    
}

- (void)didReceiveGuesser{
     [self.iconImageView setImage:[UIImage imageNamed:@"guesserIcon"]];
    
}

- (void)didReceiveGuesserWithResponses:(NSArray*)responses{
    
    
}



- (void) didReceiveGuessResponse:(BOOL) correct {
    
    
}


- (void) didReceiveScore:(NSDictionary*) scores {
    
    
}

- (void)didReceiveErrorMessage:(NSString *)message {
    
    
}


- (IBAction)submitAction:(id)sender {
    NSLog(@"%hhd",[_messageStream joinGameWithName:[self currentUserName]]);
}
@end
