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
#import "TVCAppDelegate.h"
#import "TVCDataSource.h"
#import "TVCLobbyViewController.h"

#import <AudioToolbox/AudioServices.h>

static NSString * const kNamespace = @"com.bears.triviaCast";

static NSString * const keyType = @"type";

// Messages Received

static NSString * const valueTypeDidJoin = @"didJoin";
static NSString * const valueTypeOrderInitialized = @"orderInitialized";
static NSString * const valueTypeOrderCanceled = @"orderCanceled";
static NSString * const valueTypeOrderCompleted = @"orderComplete";
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
static NSString * const valueTypeError = @"error";
static NSString * const valueTypeUploadResponse = @"uploadResult";
static NSString * const valueTypeDidQueue = @"didQueue";

//Messages Sent
static NSString * const valueTypeJoin = @"join";
static NSString * const valueTypeLeave = @"leave";
static NSString * const valueTypeOrder = @"order";
static NSString * const valueTypeInitializeOrder = @"initializeOrder";
static NSString * const valueTypeCancelOrder = @"cancelOrder";
static NSString * const valueTypeSubmitResponse = @"submitResponse";
static NSString * const valueTypeReaderIsDone = @"readerIsDone";
static NSString * const valueTypeSubmitGuess = @"submitGuess";
static NSString * const valueTypeStartNextRound = @"nextRound";
static NSString * const valueTypeGetScore = @"score"; //Maybe

// new Player Protocol
static NSString * const keyName = @"name";
static NSString * const keyPlayerNumber = @"number";
static NSString * const keyPlayers = @"players";
static NSString * const keyPlayerIsOut = @"isOut";

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
static NSString * const keyPictureURL = @"pictureURL";

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

- (BOOL)joinGameWithName:(NSString *)name andURL:(NSString *)URL{
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeJoin forKey:keyType];
    [payload gck_setStringValue:name forKey:keyName];
    [payload gck_setStringValue:URL forKey:keyPictureURL];

    return [self sendMessage:payload];
}

- (BOOL)sendOrderMessage {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeOrder forKey:keyType];
    
    return [self sendMessage:payload];
}

- (BOOL)sendCancelOrderMessage {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeCancelOrder forKey:keyType];
    
    return [self sendMessage:payload];
}

- (BOOL)sendInitializeOrderMessage {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeInitializeOrder forKey:keyType];
    
    return [self sendMessage:payload];
}

- (BOOL) updateSettingsWithName:(NSString*)name andURL:(NSString *)url {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeUpdateSettings forKey:keyType];
    [payload gck_setStringValue:name forKey:keyName];
    [payload gck_setStringValue:url forKey:keyPictureURL];
    NSLog(@"update settings, url: %@", url);
    return [self sendMessage:payload];
}

- (BOOL)sendResponseWithText:(NSString*)text {
    NSMutableDictionary *payload = [[NSMutableDictionary alloc] init];
    [payload gck_setStringValue:valueTypeSubmitResponse forKey:keyType];
    [payload gck_setStringValue:text forKey:keyResponse];
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
    NSLog(@"Did receive Message: dict: %@",payload);
    NSString *type = [payload gck_stringForKey:keyType];

    if (!type) {
        NSLog(@"received invalid message: %@", [GCKJsonUtils writeJson:payload]);
        return;
    }
    
    
    if([type isEqualToString:valueTypeDidJoin]) {
        
        NSInteger playerValue = [payload gck_integerForKey:keyPlayerNumber];
       
        if (playerValue) {
            //TVCPlayer * player = [[TVCPlayer alloc] initWithName:@"test" andNumber:playerValue.integerValue];
           // NSLog(@"%@ , %d",[player name], [player playerNumber]);
            [self.delegate didJoinGameAsPlayer:playerValue];
            //NSLog(@"%@ , %d",[player name], [player playerNumber]);
            return;
        } else {
            NSLog(@"received invalid message: %@", [GCKJsonUtils writeJson:payload]);
            return;
        }
        
        
    } if([type isEqualToString:valueTypeDidQueue]) {
        [self.delegate didReceiveDidQueue];
    }
    
    if([type isEqualToString:valueTypeOrderInitialized]) {
        [self.delegate didReceiveOrderInitialized];
        return;
    }
    
    if([type isEqualToString:valueTypeOrderCanceled]) {
        [self.delegate didReceiveOrderCanceled];
        return;
    }
    
    if([type isEqualToString:valueTypeOrderCompleted]) {
        [self.delegate didReceiveOrderCompleted];
        return;
    }
    
    if([type isEqualToString:valueTypeSetReader]) {
        
        [self.delegate didReceiveReader];
        return;
    }
    
    if([type isEqualToString:valueTypeReceiveResponses]) {
        NSArray *responsesArray = [payload gck_arrayForKey:keyResponses];
    
        NSMutableDictionary *responseIdDictionary = [[NSMutableDictionary alloc] init];
        
        for(NSDictionary *holdDict in responsesArray) {
           // NSDictionary * holdDict = [responsesDictionary gck_dictionaryForKey:key];
            
            NSString * response = [holdDict gck_stringForKey:keyResponse];
            NSInteger responseID = [holdDict gck_integerForKey:keyResponseId];
           
            [responseIdDictionary setObject:response forKey:[NSString stringWithFormat:@"%i",responseID]];
        }
       
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        [self.delegate didReceiveResponses:responseIdDictionary];
        return;
    }
    
    if([type isEqualToString:valueTypeResponseReceived]) {
        [self.delegate responseWasReceived];
        return;
    }
    
    if([type isEqualToString:valueTypeSetGuesser]) {
        
       // [self.delegate didReceiveGuesser];
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
        NSArray* players = [payload gck_arrayForKey:keyPlayers];
        NSInteger readerID = [payload gck_integerForKey:keyReader];
        NSInteger guesserID = [payload gck_integerForKey:valueTypeSetGuesser];
        
        NSMutableArray *returnPlayers = [NSMutableArray array];
        [[[appDelegate dataSource] lobbyViewController] setMaxScoreCount:[players count]];
        [[[appDelegate dataSource] lobbyViewController] setUpdatedScoreCount:0];
        for(NSDictionary * dict in players) {
            
            //NSDictionary * holdDictionary = [players gck_dictionaryForKey:key];
            NSInteger ID = [dict gck_integerForKey:keyID];
            NSString* name = [dict gck_stringForKey:keyName];
            NSInteger score = [dict gck_integerForKey:keyScore];
            BOOL isOut = [dict gck_boolForKey:keyPlayerIsOut];
            NSString* profilePicURL = [dict gck_stringForKey:keyPictureURL];
            
            TVCPlayer *holdPlayer = nil;
#warning if the player ID system is ever changed, this code should be updated to be more efficient
        
            for (id key in [[[appDelegate dataSource] playerDictionary] allKeys]) {
                TVCPlayer * p = [[[appDelegate dataSource] playerDictionary] objectForKey:key];
#warning so horribly inefficient
                if (p.playerNumber == ID) {
                    holdPlayer = p;
                    NSLog(@"Message Stream, player is not nil");
                    break;
                }
            }
            if(!holdPlayer) {
                NSLog(@"Message Stream, player is nil");
                holdPlayer = [[TVCPlayer alloc] initWithName:name andNumber:ID andImageURL:profilePicURL];
            }
            
            [holdPlayer setName:name];
            [holdPlayer setIsOut:isOut];
            [holdPlayer setScore:score];
            [holdPlayer setImageUrlString:profilePicURL completion:^(BOOL valid) {
                [[[appDelegate dataSource] lobbyViewController] setScoreViewForPlayer:[[[appDelegate dataSource] playerDictionary ] objectForKey:[NSNumber numberWithInt:ID]]];
            }];
            [holdPlayer setIsGuessing:NO];
            [holdPlayer setIsReader:NO];

            NSLog(@"Game sync: Profile pic url: %@", profilePicURL);
            
            if (holdPlayer.playerNumber == readerID) {
                [holdPlayer setIsReader:YES];
            }
            if (holdPlayer.playerNumber == guesserID) {
                [holdPlayer setIsGuessing:YES];
            }
            
            [returnPlayers addObject:holdPlayer];
            
        }
        if ([[[appDelegate dataSource] player] playerNumber] == readerID) {
            [[[appDelegate dataSource] player] setIsReader:YES];
        }
        if ([[[appDelegate dataSource] player] playerNumber] == guesserID) {
            [[[appDelegate dataSource] player] setIsGuessing:YES];
        }
        
        [self.delegate didReceiveGameSyncWithPlayers:returnPlayers];
        return;
    }
    
    if([type isEqualToString:valueTypeRoundStarted]) {
        NSString *cue = [payload gck_stringForKey:keyPrompt];
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
        [self.delegate didReceiveRoundStartedWithCue:cue];
        return;
        
    }
    
    if([type isEqualToString:valueTypeRoundOver]) {
        [self.delegate didReceiveRoundEnded];
        return;
    }

    if ([type isEqualToString:valueTypeError]) {
        NSInteger errorCode = [payload gck_integerForKey:keyValue];
        
          [self.delegate didReceiveErrorMessage:[NSString stringWithFormat:@"Error Code: %i",errorCode]];
    }
}

- (void)didDetach {
    _joined = NO;
}

@end

