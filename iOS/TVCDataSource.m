//
//  TVCDataSource.m
//  TriviaCast
//
//  Created by John Brophy on 9/25/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCDataSource.h"
#import "TVCPlayer.h"
#import "TVCLobbyViewController.h"
#import "TVCGuesserViewController.h"
#import "TVCReaderViewController.h"
#import "TVCSettingsViewController.h"

static NSString * const kReceiverApplicationName = @"1f96e9a0-9cf0-4e61-910e-c76f33bd42a2";
static NSString * const betweenRoundsMessage = @"Start the round once everyone has joined";
static NSString * const queuedToJoinMessage = @"You will join at the begining of the next round";
static NSString * const waitForGuesserMessage = @"The guesser is currently guessing";
static NSString * const waitForReaderMessage = @"The reader is currently reading";
static NSString * const incorrectGuessMessage = @"You guessed incorrectly";
static NSString * const submittedResponseMessage = @"Your response was submitted";


@interface TVCDataSource(){
    // Dongle state and communication.
    GCKApplicationSession *_session;
    GCKApplicationChannel *_channel;
    TVCMessageStream *_messageStream;
    int playerNumber;
}

@property (nonatomic, strong) NSArray* responses;
//@property (nonatomic, strong) NSDictionary* responseDictionary;
@property (nonatomic, strong) NSMutableDictionary* responseMap;

@end


@implementation TVCDataSource

-(id) initWithDevice:(GCKDevice*)device {
    self = [super init];
    if (self) {
        self.device = device;
        self.currentScore = 0;
        [self startSession];
    
    }
    
    return self;
}

-(BOOL) isReader {
    return [self.player isReader];
}

-(BOOL) isGuesser {
    return [self.player isGuessing];
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
    [_messageStream leaveGame];
    [_session endSession];
    _session = nil;
    _channel = nil;
    _messageStream = nil;
}


- (GCKApplicationSession *)createSession {
    return [[GCKApplicationSession alloc] initWithContext:appDelegate.context
                                                   device:self.device];
}

- (TVCMessageStream *)getMessageStream {
    if(_messageStream) {
        NSLog(@"existing stream");
        return _messageStream;
    } else {
        return [self createMessageStream];
    }
}

- (TVCMessageStream *)createMessageStream {
    return [[TVCMessageStream alloc] initWithDelegate:self];
}

- (NSString *)currentUserName {
    return [appDelegate userName];
}



#pragma mark - GCKApplicationSessionDelegate

// When connected to the session, attempt to join the game if the channel was
// successfully established, or show an error if there is no channel.
- (void)applicationSessionDidStart {
    _channel = _session.channel;
    if (!_channel) {
        NSString *message = NSLocalizedString(@"Could not establish channel.", nil);
        NSLog(@"%@",message); //[self showErrorMessage:message popViewControllerOnOK:YES];
        [_session endSession];
    }
    
    _messageStream = [self createMessageStream];

    if ([_channel attachMessageStream:_messageStream]) {
        if (_messageStream.messageSink) {
            if (20 < _channel.sendBufferAvailableBytes) {
                if (![_messageStream joinGameWithName:[self currentUserName] andURL:[appDelegate profilePicUrl]]) {
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
    NSLog(@"ERROR: %@",message);
    //[self showErrorMessage:message popViewControllerOnOK:YES];
}

// If there is an error, show it; otherwise, just nil out the message stream.
- (void)applicationSessionDidEndWithError:
(GCKApplicationSessionError *)error {
    NSLog(@"castApplicationSessionDidEndWithError: %@", error);
    _messageStream = nil;
    if (error) {
        NSString *message = NSLocalizedString(@"Lost connection.", nil);
        NSLog(@"ERROR: %@",message);
    //    [self showErrorMessage:message popViewControllerOnOK:YES];
    }
}


#pragma mark - TVCMessageStreamDelegate

-(BOOL) isValid {
    if (_messageStream) {
        return YES;
    }
    
    return NO;
}

// When the game has been joined, update the current player to whichever player
// we joined as, update the game state to a new game, and keep track of the
// opponent's name.
- (void)didJoinGameAsPlayer:(NSInteger)number {
    playerNumber = number;
    //self.players = [NSArray arrayWithArray:players];
    if (!self.player) {
        self.player = [[TVCPlayer alloc] initWithName:[self currentUserName] andNumber:playerNumber andImageURL:[appDelegate profilePicUrl]];
    } else {
        //For when the player gets assigned a new ID
        [self.player setPlayerNumber:number];
    }
    [self.lobbyViewController.descriptionLabel setText:betweenRoundsMessage];
}

// Dispaly an error indicating that the game couldn't be started.
- (void)didFailToJoinWithErrorMessage:(NSString *)message {
  //  [self showErrorMessage:message popViewControllerOnOK:YES];
}

- (void) didReceiveDidQueue {
    [self.lobbyViewController.descriptionLabel setText:queuedToJoinMessage];
}

- (void) didReceiveOrderInitialized {
    
    UIViewController* viewController = self.currentViewController;
    if ([viewController isKindOfClass:[TVCLobbyViewController class]]) {
        TVCLobbyViewController* lobbyViewController = (TVCLobbyViewController*)self.currentViewController;
        [lobbyViewController segueToOrderPickerView];
    } else if ([viewController isKindOfClass:[TVCSettingsViewController class]]){
        TVCSettingsViewController* settingsView = (TVCSettingsViewController*)self.currentViewController;
        [settingsView dismissViewControllerAnimated:YES completion:^(void){
            
            [[[appDelegate dataSource] lobbyViewController] segueToOrderPickerView];
            
        }];
    }
}

- (void) didReceiveOrderCanceled {
    UIViewController* viewController = self.currentViewController;
    if ([viewController isKindOfClass:[TVCOrderPickerViewController class]]) {
        TVCOrderPickerViewController* orderPickerView = (TVCOrderPickerViewController*) viewController;
        
        [orderPickerView dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void) didReceiveOrderCompleted {
    
    UIViewController* viewController = self.currentViewController;
    if ([viewController isKindOfClass:[TVCOrderPickerViewController class]]) {
        TVCOrderPickerViewController* orderPickerView = (TVCOrderPickerViewController*) viewController;
        
        [orderPickerView dismissViewControllerAnimated:YES completion:nil];
    }
    
    
    
}

- (void) didReceiveGuesser {
    [self.player setIsGuessing:YES];
}

- (void) didReceiveResponses:(NSDictionary *)responses {
    self.responseDictionary = responses;
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(timerFired:) userInfo:responses repeats:NO];
}

- (void)timerFired:(NSTimer *)timer
{
    NSDictionary *responses = [timer userInfo];
    [self didReceiveResponsesHelper:responses];
}

-(void) didReceiveResponsesHelper:(NSDictionary *)responses {
    NSLog(@"got responses, your ID is: %i", self.player.playerNumber);
    NSLog(@"player isReader: %@ and datasource isReading: %@", self.player.isReader ? @"YES" : @"NO", self.isReader ? @"YES" : @"NO");
    if([self.player isReader]){
        if (self.currentViewController != self.lobbyViewController) {
            [self.lobbyViewController setMissedReader:YES];
        } else {
            TVCLobbyViewController* lobbyViewController = self.lobbyViewController;
            [lobbyViewController segueToReaderViewWithResponses:responses];
            [self.player setIsReader:NO];
            /*[self.currentViewController dismissViewControllerAnimated:YES completion:^(void){
             TVCLobbyViewController* lobbyViewController = (TVCLobbyViewController*)self.currentViewController;
             [lobbyViewController segueToReaderViewWithResponses:responses];
             }];*/
        }
        
    }else {
        NSLog(@"not reader");
        if (self.currentViewController != self.lobbyViewController && ![self.currentViewController isKindOfClass:[TVCReaderViewController class]]) {
            [self.lobbyViewController setMissedGuesser:YES];
        } else {
        
            NSMutableArray* notOutPlayers = [NSMutableArray array];
            for (id key in [self.playerDictionary allKeys]) {
                TVCPlayer *p = [self.playerDictionary objectForKey:key];
                if (!p.isOut) {
                    [notOutPlayers addObject:p];
                }
            }
            TVCLobbyViewController* lobbyViewController = self.lobbyViewController;
            [lobbyViewController segueToGuesserViewWithResponses:responses andPlayers:notOutPlayers];
            /* [self.currentViewController dismissViewControllerAnimated:YES completion:^(void){
             TVCLobbyViewController* lobbyViewController = (TVCLobbyViewController*)self.currentViewController;
             [lobbyViewController segueToGuesserViewWithResponses:responses andPlayers:self.players];
             }];*/
        }
    }
}

//actually probably unecessary, maybe not, in the case of reader leaving
- (void) didReceiveReader {
    [self.player setIsReader:YES];
}

-(void) didReceiveGuessResponse:(BOOL)correct {
    
    if (correct) {
        TVCGuesserViewController* guessViewController = (TVCGuesserViewController*)self.currentViewController;
        [guessViewController didMakeCorrectGuess];

    } else {
        [self.player setIsGuessing:NO];
        [[self.lobbyViewController descriptionLabel] setText:incorrectGuessMessage];
        [self.currentViewController dismissViewControllerAnimated:YES completion:nil];
    }
    
    
}

- (void) didReceiveGameSyncWithPlayers:(NSArray *)players andProfilePictureURLs:(NSArray *)profilePictureURLs {

    NSMutableArray *holdPlayers = [NSMutableArray arrayWithArray:players];
    //NSMutableDictionary *newPlayerDictionary = [[NSMutableDictionary alloc] init];
    
    for(TVCPlayer* player in holdPlayers) {
        if(player.playerNumber == self.player.playerNumber) {
            //self.player = player;
            
            self.currentScore = player.score;
            self.player.score = player.score;
            self.player.name = player.name;
            self.player.isOut = player.isOut;
            self.player.isGuessing = player.isGuessing;
            self.player.isReader = player.isReader;
            [self.playerDictionary setObject:self.player forKey:[NSNumber numberWithInt:self.player.playerNumber]];
            [[self.playerDictionary objectForKey:[NSNumber numberWithInt:player.playerNumber]] setImageUrlString:[profilePictureURLs objectAtIndex:player.playerNumber] completion:^(BOOL valid) {
                [[[appDelegate dataSource] lobbyViewController] setScoreViewForPlayer:[[[appDelegate dataSource] playerDictionary ] objectForKey:[NSNumber numberWithInt:player.playerNumber]]];
            }];
            
        } else {
            [self.playerDictionary setObject:player forKey:[NSNumber numberWithInt:player.playerNumber]];
            [[self.playerDictionary objectForKey:[NSNumber numberWithInt:player.playerNumber]] setImageUrlString:[profilePictureURLs objectAtIndex:player.playerNumber] completion:^(BOOL valid) {
                [[[appDelegate dataSource] lobbyViewController] setScoreViewForPlayer:[[[appDelegate dataSource] playerDictionary ] objectForKey:[NSNumber numberWithInt:player.playerNumber]]];
            }];
        }
        
    }
    //[self setPlayerDictionary:newPlayerDictionary];
   // [[[appDelegate dataSource] lobbyViewController] updateScoreList];
}

-(void)didReceiveRoundStartedWithCue:(NSString*)cue {
    if (self.currentViewController != self.lobbyViewController) {
        [self.lobbyViewController setMissedCue:YES];
        [self.lobbyViewController setCue:cue];
    } else {
        TVCLobbyViewController* lobbyViewController = (TVCLobbyViewController*)self.currentViewController;
        [lobbyViewController segueToResponseViewWithCue:cue];
    }
    
    [self.lobbyViewController.descriptionLabel setText:waitForReaderMessage];
    [self.lobbyViewController.roundStartButton setHidden:YES];
    
}

- (void) didReceiveRoundEnded {
    if (self.currentViewController != self.lobbyViewController) {
        [self.currentViewController dismissViewControllerAnimated:YES completion:nil];
        [self.lobbyViewController.roundStartButton setHidden:NO];
    }
    [[self.lobbyViewController descriptionLabel] setText:betweenRoundsMessage];
    [self.lobbyViewController.roundStartButton setHidden:NO];
}

- (void)responseWasReceived {
    if (self.currentViewController != self.lobbyViewController) {
        [self.currentViewController dismissViewControllerAnimated:YES completion:nil];
        
    }
    [self.lobbyViewController.descriptionLabel setText:submittedResponseMessage];
    
}


// Display the error message.
- (void)didReceiveErrorMessage:(NSString *)message {
   // _isWaitingForMoveToBeSent = NO;
   // [self showErrorMessage:message popViewControllerOnOK:NO];
}

- (void)didReceiveResponses:(NSArray*)responses fromPlayers:(NSArray*)players{
    self.responseMap = [[NSMutableDictionary alloc] init];
    for (int i = 0; i < [responses count]; ++i) {
        int num = (int)[players objectAtIndex:i];
        [self.responseMap setObject:[responses objectAtIndex:i] forKey:[NSNumber numberWithInt:num]];
    }
}

@end
