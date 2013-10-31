//
//  TVCMessageStream.m
//  TriviaCast
//
//  Created by John Brophy on 9/22/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

// Copyright 2013 Google Inc. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "TVCMessageStream.h"
#import "TVCPlayer.h"

static NSString * const kNamespace = @"com.bears.triviaCast";

static NSString * const kKeyColumn = @"column";
static NSString * const kKeyCommand = @"command";
static NSString * const kKeyEndState = @"end_state";
static NSString * const kKeyEvent = @"event";
static NSString * const kKeyGameOver = @"game_over";
static NSString * const kKeyMessage = @"message";
static NSString * const kKeyName = @"name";
static NSString * const kKeyOpponents = @"opponents";
static NSString * const kKeyPlayer = @"player";
static NSString * const kKeyRow = @"row";
static NSString * const kKeyWinningLocation = @"winning_location";

static NSString * const kKeyText = @"text";
static NSString * const kKeyResponses = @"responses";

static NSString * const kValueCommandJoin = @"join";
static NSString * const kValueCommandLeave = @"leave";
static NSString * const kValueCommandMove = @"move";
static NSString * const kValueCommandRespond = @"respond";

static NSString * const kValueEventEndgame = @"endgame";
static NSString * const kValueEventError = @"error";
static NSString * const kValueEventJoined = @"joined";
static NSString * const kValueEventMoved = @"moved";

static NSString * const kValueEventReader = @"reader";
static NSString * const kValueEventGuesser = @"guesser";

static NSString * const kValueEndgameAbandoned = @"abandoned";
static NSString * const kValueEndgameDraw = @"draw";
static NSString * const kValueEndgameOWon = @"O-won";
static NSString * const kValueEndgameXWon = @"X-won";

static NSString * const kValuePlayerO = @"O";
static NSString * const kValuePlayerX = @"X";

@interface TVCMessageStream () {
    BOOL _joined;
}

@property(nonatomic, strong, readwrite) id<TVCMessageStreamDelegate> delegate;
@property(nonatomic, readwrite) TVCPlayer * player;

@end

@implementation TVCMessageStream

- (id)initWithDelegate:(id<TVCMessageStreamDelegate>)delegate {
    if (self = [super initWithNamespace:kNamespace]) {
        _delegate = delegate;
        _joined = NO;
    }
    return self;
}

- (BOOL)joinGameWithName:(NSString *)name {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:@"jeff is gay" forKey:@"type"];
    [payload gck_setStringValue:kValueCommandJoin forKey:kKeyCommand];
    [payload gck_setStringValue:name forKey:kKeyName];
    NSLog(@"%@",[payload valueForKey:@"type"]);
    return [self sendMessage:payload];
}

- (BOOL)sendResponseWithText:(NSString*)text {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:kValueCommandRespond forKey:kKeyCommand];
    [payload gck_setStringValue:text forKey:kKeyText];
    
    return [self sendMessage:payload];
}

- (BOOL)leaveGame {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:kValueCommandLeave forKey:kKeyCommand];
    
    return [self sendMessage:payload];
}

- (void)didReceiveMessage:(id)message {
    NSDictionary *payload = message;
    
    NSString *event = [payload gck_stringForKey:kKeyEvent];
    if (!event) {
        NSLog(@"received invalid message: %@", [GCKJsonUtils writeJson:payload]);
        return;
    }
    
    if ([event isEqualToString:kValueEventJoined]) {
        NSString *playerName = [payload gck_stringForKey:kKeyName];
        NSInteger playerValue = [payload gck_integerForKey:kKeyPlayer];
        TVCPlayer * player;
        if (playerName && playerValue) {
            player = [[TVCPlayer alloc] initWithName:playerName andNumber:playerValue];
        } else {
            NSLog(@"received invalid message: %@", [GCKJsonUtils writeJson:payload]);
            return;
        }
        
        NSArray *opponents = [payload gck_arrayForKey:kKeyOpponents];
        _joined = YES;
        self.player = player;
        
        //[self.delegate didJoinGameAsPlayer:player withOpponents:opponents];
        
    } else if ([event isEqualToString:kValueEventReader])
    {
        NSArray * listOfResponses = [payload gck_arrayForKey:kKeyResponses];
        //SHould add error check here
        
        [self.delegate didReceiveReaderWithResponses:listOfResponses];
        
    } else if ([event isEqualToString:kValueEventGuesser])
    {
      NSArray * listOfResponses = [payload gck_arrayForKey:kKeyResponses];
        
        [self.delegate didReceiveGuesserWithResponses:listOfResponses];
        
    }
    /* else if ([event isEqualToString:kValueEventMoved]) {
        NSString *playerValue = [payload gck_stringForKey:kKeyPlayer];
        TicTacToePlayer player;
        if ([playerValue isEqualToString:kValuePlayerO]) {
            player = kPlayerO;
        } else if ([playerValue isEqualToString:kValuePlayerX]) {
            player = kPlayerX;
        } else {
            NSLog(@"received invalid message: %@", [GCKJsonUtils writeJson:payload]);
            return;
        }
        NSInteger row = [payload gck_integerForKey:kKeyRow];
        NSInteger column = [payload gck_integerForKey:kKeyColumn];
        if ((row > 2) || (column > 2)) {
            NSLog(@"received invalid message: %@", [GCKJsonUtils writeJson:payload]);
            return;
        }
        BOOL isFinal = [payload gck_boolForKey:kKeyGameOver];
        
        [self.delegate didReceiveMoveByPlayer:player atRow:row column:column isFinal:isFinal];
    } */
    else if ([event isEqualToString:kValueEventError]) {
        NSString *errorMessage = [payload gck_stringForKey:kKeyMessage];
        if (!_joined) {
            [self.delegate didFailToJoinWithErrorMessage:errorMessage];
        } else {
            [self.delegate didReceiveErrorMessage:errorMessage];
        }
    } /* else if ([event isEqualToString:kValueEventEndgame]) {
        NSString *stateValue = [payload gck_stringForKey:kKeyEndState];
        
        GameResult result;
        if ([stateValue isEqualToString:kValueEndgameOWon]) {
            result = (self.player == kPlayerO) ? kResultYouWon : kResultYouLost;
        } else if ([stateValue isEqualToString:kValueEndgameXWon]) {
            result = (self.player == kPlayerX) ? kResultYouWon : kResultYouLost;
        } else if ([stateValue isEqualToString:kValueEndgameDraw]) {
            result = kResultDraw;
        } else if ([stateValue isEqualToString:kValueEndgameAbandoned]) {
            result = kResultAbandoned;
        } else {
            NSLog(@"received invalid message: %@", [GCKJsonUtils writeJson:payload]);
            return;
        }
        
        NSInteger winningLocation = [payload gck_integerForKey:kKeyWinningLocation];
        
        _joined = NO;
        [self.delegate didEndGameWithResult:result winningLocation:winningLocation];
    } */
}

- (void)didDetach {
    _joined = NO;
}

@end

