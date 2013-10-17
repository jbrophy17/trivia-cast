//
//  TVCDataSource.m
//  TriviaCast
//
//  Created by John Brophy on 9/25/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCDataSource.h"

static NSString * const kReceiverApplicationName = @"1f96e9a0-9cf0-4e61-910e-c76f33bd42a2";


@interface TVCDataSource(){
    // Dongle state and communication.
    GCKApplicationSession *_session;
    GCKApplicationChannel *_channel;
    TVCMessageStream *_messageStream;
    int playerNumber;
}
@property (nonatomic, strong) NSArray* players;
@property (nonatomic, strong) NSArray* responses;
@property (nonatomic, strong) NSMutableDictionary* responseMap;

@end


@implementation TVCDataSource

-(id) init {
    self = [super init];
    if (self) {
        
        [self startSession];
    
    }
    
    return self;
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

- (TVCMessageStream *)createMessageStream {
    return [[TVCMessageStream alloc] initWithDelegate:self];
}

- (NSString *)currentUserName {
    return [appDelegate userName];
}

- (BOOL) guessPlayer:(int)player forResponse:(NSString*)response {
    
    //Message Stream send guess
    
    if ([self.responseMap objectForKey:[NSNumber numberWithInt:player]] == response) {
        return YES;
    }
    return NO;
}

#pragma mark - GCKApplicationSessionDelegate

// When connected to the session, attempt to join the game if the channel was
// successfully established, or show an error if there is no channel.
- (void)applicationSessionDidStart {
    _channel = _session.channel;
    if (!_channel) {
        NSString *message = NSLocalizedString(@"Could not establish channel.", nil);
        //[self showErrorMessage:message popViewControllerOnOK:YES];
        [_session endSession];
    }
    
    _messageStream = [self createMessageStream];
    if ([_channel attachMessageStream:_messageStream]) {
        if (_messageStream.messageSink) {
            if (20 < _channel.sendBufferAvailableBytes) {
                if ([_messageStream joinGameWithName:[self currentUserName]]) {
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
    //[self showErrorMessage:message popViewControllerOnOK:YES];
}

// If there is an error, show it; otherwise, just nil out the message stream.
- (void)applicationSessionDidEndWithError:
(GCKApplicationSessionError *)error {
    NSLog(@"castApplicationSessionDidEndWithError: %@", error);
    _messageStream = nil;
    if (error) {
        NSString *message = NSLocalizedString(@"Lost connection.", nil);
    //    [self showErrorMessage:message popViewControllerOnOK:YES];
    }
}


#pragma mark - TVCMessageStreamDelegate

// When the game has been joined, update the current player to whichever player
// we joined as, update the game state to a new game, and keep track of the
// opponent's name.
- (void)didJoinGameAsPlayer:(int)player
          withPlayers:(NSArray *)players {
    playerNumber = player;
    self.players = [NSArray arrayWithArray:players];
}

// Dispaly an error indicating that the game couldn't be started.
- (void)didFailToJoinWithErrorMessage:(NSString *)message {
  //  [self showErrorMessage:message popViewControllerOnOK:YES];
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

// When the move is received, update the board state with the move, and update
// the game state so that it is the other player's turn.
- (void)didReceiveMoveByPlayer:(TicTacToePlayer)player
                         atRow:(NSInteger)row
                        column:(NSInteger)column
                       isFinal:(BOOL)isFinal {
    _isWaitingForMoveToBeSent = NO;
    TicTacToeSquareState newState = ((player == kPlayerX)
                                     ? kTicTacToeSquareStateX
                                     : kTicTacToeSquareStateO);
    _isXsTurn = !(player == kPlayerX);
    [self.boardState setState:newState forSquareAtRow:(NSUInteger)row column:(NSUInteger)column];
    [_ticTacToeView setNeedsDisplay];
}

// Update the game board to show the winning strikethrough if there is a winner,
// and show an alert indicating if the player won, lost, or the game was a draw.
- (void)didEndGameWithResult:(GameResult)result
             winningLocation:(NSInteger)winningLocation {
    switch (result) {
        case kResultYouWon:
        case kResultYouLost: {
            _isGameInProgress = NO;
            TicTacToeWinType winType;
            NSInteger index;
            [[self class] decodeWinningLocationFrom:winningLocation
                                          toWinType:&winType
                                              index:&index];
            [_ticTacToeView showWinningStrikethroughOfType:winType
                                                   atIndex:(NSUInteger)index];
            NSString *message;
            if (result == kResultYouWon) {
                message = NSLocalizedString(@"A winner is you! Play again?", nil);
            } else {
                message = NSLocalizedString(@"You lost! Play again?", nil);
            }
            [self showGameOverMessage:message];
            _gameStatusLabel.text = @"";
            break;
        }
            
        case kResultDraw: {
            NSString *message = NSLocalizedString(@"Nobody wins, again.", nil);
            [self showGameOverMessage:message];
            _gameStatusLabel.text = @"";
            break;
        }
            
        case kResultAbandoned: {
            NSString *title = NSLocalizedString(@"Opponent ran away", nil);
            NSString *message = NSLocalizedString(@"It may feel hollow and empty, "
                                                  @"but a win by default is still a "
                                                  @"win!",
                                                  nil);
            [self showAlertMessage:message
                         withTitle:title
                               tag:kTagPopViewControllerOnOK];
            break;
        }
    }
    [_messageStream leaveGame];
}

// Converts the message stream representation of a win, which is a single
// integer, to a TicTacToeWinType and (if necessary) the index at which that
// win type applies.
+ (void)decodeWinningLocationFrom:(NSInteger)value
                        toWinType:(TicTacToeWinType *)winType
                            index:(NSInteger *)index {
    if ((value >= 0) && (value <= 2)) {
        *winType = kTicTacToeWinTypeRow;
        *index = value;
    } else if ((value >= 3) && (value <= 5)) {
        *winType = kTicTacToeWinTypeColumn;
        *index = value - 3;
    } else if (value == 6) {
        *winType = kTicTacToeWinTypeDiagonalFromTopLeft;
    } else if (value == 7) {
        *winType = kTicTacToeWinTypeDiagonalFromBottomLeft;
    } else {
        *winType = kTicTacToeWinTypeNone;
    }
}


@end
