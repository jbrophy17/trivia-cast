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

static NSString * const keyType = @"type";

// Messages Received

static NSString * const valueTypeDidJoin = @"didJoin";
static NSString * const valueTypeSetGuesser = @"guesser";
static NSString * const valueTypeSetReader = @"reader";
static NSString * const valueTypeReceiveResponses = @"receiveResponses";
static NSString * const valueTypeGuessResponse = @"guessResponse";
static NSString * const valueTypeSyncGame = @"gameSync";
static NSString * const valueTypeRoundStarted = @"roundStarted";
static NSString * const valueTypeRoundOver = @"roundOver";
static NSString * const valueTypeResponseReceived = @"responseReceived";
static NSString * const valueTypeUpdateSettings = @"updateSettings";
static NSString * const valueTypeSettingsUpdated = @"settingsUpdated";

//Messages Sent
static NSString * const valueTypeJoin = @"join";
static NSString * const valueTypeLeave = @"leave";
static NSString * const valueTypeSubmitResponse = @"submitResponse";
static NSString * const valueTypeReaderIsDone = @"readerIsDone";
static NSString * const valueTypeSubmitGuess = @"submitGuess";
static NSString * const valueTypeStartNextRound = @"nextRound";
static NSString * const valueTypeGetScore = @"score"; //Maybe

// new Player Protocol
static NSString * const keyName = @"name";
static NSString * const keyPlayerNumber = @"number";
static NSString * const keyPlayers = @"players";

// Receive Responses Protocol
static NSString * const keyResponses = @"responses";
static NSString * const keyResponse = @"response";
static NSString * const keyResponseId = @"responseID";

// Receive Guesses Protocol
static NSString * const keyGuesses = @"guesses";
static NSString * const keyGuessPlayerNumber = @"guessPlayerNumber";
static NSString * const keyGuessResponseId = @"guessResponseId";

// General Protocol
static NSString * const keyValue = @"value";
static NSString * const keyPrompt = @"cue";
static NSString * const keyReader = @"reader";
static NSString * const keyScore = @"score";
static NSString * const keyID = @"ID";

//Google

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
    [payload gck_setStringValue:valueTypeJoin forKey:keyType];
    [payload gck_setStringValue:name forKey:keyName];

    return [self sendMessage:payload];
}

- (BOOL) updateSettingsWithName:(NSString*)name {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeUpdateSettings forKey:keyType];
    [payload gck_setStringValue:name forKey:keyName];
    
    return [self sendMessage:payload];
}

- (BOOL)sendResponseWithText:(NSString*)text {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeSubmitResponse forKey:keyType];
    [payload gck_setStringValue:text forKey:keyResponse];
    NSLog(@"Payload: %@", payload);
    @try {
        return [self sendMessage:payload];
    } @catch (GCKError *error) {
        NSLog(@"ERROR SENDING: %@ BTW error code 6 is: %@", error, [GCKError localizedDescriptionForCode:6]);
    }
}

- (BOOL)sendGuessWithPlayer:(NSInteger*)number andResponseId:(NSInteger*)responseId {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeSubmitGuess forKey:keyType];
    [payload gck_setIntegerValue:*number forKey:keyGuessPlayerNumber];
    [payload gck_setIntegerValue:*responseId forKey:keyGuessResponseId];
    [self.delegate setCurrentGuess:number];
    return [self sendMessage:payload];
}

-(BOOL)sendReaderIsDone {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeReaderIsDone forKey:keyType];
    
    return [self sendMessage:payload];
}

-(BOOL)sendNextRound {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeStartNextRound forKey:keyType];
    
    return [self sendMessage:payload];
}

- (BOOL)leaveGame {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeLeave forKey:keyType];
    
    return [self sendMessage:payload];
}

- (void)didReceiveMessage:(id)message {
    NSDictionary *payload = message;
    NSLog(@"Did receive Message");
    NSLog(@"dict: %@",payload);
    NSString *type = [payload gck_stringForKey:keyType];
    NSLog(@"type:%@",type);
    if (!type) {
        NSLog(@"received invalid message: %@", [GCKJsonUtils writeJson:payload]);
        return;
    }
    
    
    if([type isEqualToString:valueTypeDidJoin]) {
        NSLog(@"Did start working");
        
        NSNumber *playerValue = [NSNumber numberWithInt:[payload gck_integerForKey:keyPlayerNumber]];
       
        if (playerValue) {
            //TVCPlayer * player = [[TVCPlayer alloc] initWithName:@"test" andNumber:playerValue.integerValue];
           // NSLog(@"%@ , %d",[player name], [player playerNumber]);
            [self.delegate didJoinGameAsPlayer:playerValue.integerValue];
            //NSLog(@"%@ , %d",[player name], [player playerNumber]);
            return;
        } else {
            NSLog(@"received invalid message: %@", [GCKJsonUtils writeJson:payload]);
            return;
        }
        
        
    }
    
    if([type isEqualToString:valueTypeSetReader]) {
        
        [self.delegate didReceiveReader];
        return;
    }
    
    if([type isEqualToString:valueTypeReceiveResponses]) {
        NSDictionary *responsesDictionary = [payload gck_dictionaryForKey:keyResponses];
    
        NSMutableDictionary *responseIdDictionary = [[NSMutableDictionary alloc] init];
        
        for(id key in responsesDictionary) {
            NSDictionary * holdDict = [responsesDictionary gck_dictionaryForKey:key];
            
            NSString * response = [holdDict gck_stringForKey:keyResponse];
            NSInteger responseID = [holdDict gck_integerForKey:keyResponseId];
           
            [responseIdDictionary setObject:[NSNumber numberWithInt:responseID] forKey:response];
        }
       
        [self.delegate didReceiveResponses:responseIdDictionary];
        return;
    }
    
    if([type isEqualToString:valueTypeResponseReceived]) {
        [self.delegate responseWasReceived];
        return;
    }
    
    if([type isEqualToString:valueTypeSetGuesser]) {
        
        [self.delegate didReceiveGuesser];
        return;
    }
    
    if([type isEqualToString:valueTypeGuessResponse]) {
        NSInteger correct = [payload gck_integerForKey:keyValue];
        
        if(correct == 1) {
        
            [self.delegate didReceiveGuessResponse:YES];
        } else {
            [self.delegate didReceiveGuessResponse:NO];
        }
        return;
    }
    
    if([type isEqualToString:valueTypeSyncGame]) {
        NSDictionary* players = [payload gck_dictionaryForKey:keyPlayers];
        NSInteger readerID = [payload gck_integerForKey:keyReader];
        NSInteger guesserID = [payload gck_integerForKey:valueTypeSetGuesser];
        
        NSMutableArray *returnPlayers = [NSMutableArray array];
        for(id key in players) {
            NSDictionary * holdDictionary = [players gck_dictionaryForKey:key];
            NSInteger ID = [holdDictionary gck_integerForKey:keyID];
            NSString* name = [holdDictionary gck_stringForKey:keyName];
            NSInteger score = [holdDictionary gck_integerForKey:keyScore];
            
            TVCPlayer *holdPlayer = [[TVCPlayer alloc] initWithName:name andNumber:ID];
            [holdPlayer setScore:&score];
            
            if (holdPlayer.playerNumber == readerID) {
                [holdPlayer setIsReader:YES];
            } else if (holdPlayer.playerNumber == guesserID) {
                [holdPlayer setIsGuessing:YES];
            }
            
            [returnPlayers addObject:holdPlayer];
            
        }
        NSLog(@"returnPlayers: %@", returnPlayers);
        [self.delegate didReceiveGameSyncWithPlayers:returnPlayers];
        return;
    }
    
    if([type isEqualToString:valueTypeRoundStarted]) {
        NSString *cue = [payload gck_stringForKey:keyPrompt];
        [self.delegate didReceiveRoundStartedWithCue:cue];
        return;
        
    }
    
    if([type isEqualToString:valueTypeRoundOver]) {
        [self.delegate didReceiveRoundEnded];
        return;
    }
    
    
    
    /*start google's stuff*/
    /*
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
        
        NSArray *players = [payload gck_arrayForKey:keyPlayersInGame];
        
        [self.delegate didJoinGameAsPlayer:player withPlayers:players];
        
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
     */
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
    else if ([type isEqualToString:kValueEventError]) {
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

