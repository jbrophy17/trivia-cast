//
//  TVCMessageStream.h
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

#import <UIKit/UIKit.h>

#import <GCKFramework/GCKFramework.h>

@class TVCPlayer;


/**
 * Possible endgame results.
 */
typedef NS_ENUM(NSInteger, GameResult) {
    /** This player won. */
    kResultYouWon,
    /** The opponent won. */
    kResultYouLost,
    /** The game resulted in a draw. */
    kResultDraw,
    /** One of the players abandoned the game before it was completed. */
    kResultAbandoned
};

/**
 * Delegate protocol for TVCMessageStream.
 */
@protocol TVCMessageStreamDelegate

/**
 * Called when a game has been successfully joined.
 *
 * @param player The symbol that was assigned to this player.
 * @param opponent The name of the opponent.
 */
- (void)didJoinGameAsPlayer:(TVCPlayer *)player
          withOpponents:(NSArray *)opponents;

/**
 * Called when the game could not be joined.
 *
 * @param message The error message describing the failure.
 */
- (void)didFailToJoinWithErrorMessage:(NSString *)message;


/**
 * Called when the responses are sent to the reader
 *
 * @param responses An array of the given responses.
 */
- (void)didReceiveReaderWithResponses:(NSArray*)responses;

/**
 * Called when it is a players turn to be a reader
 *
 */
- (void)didReceiveReader;

/**
 * Called when it is a players turn to be a guesser
 *
 * @param responses An array of the remaining responses.
 */
- (void)didReceiveGuesserWithResponses:(NSArray*)responses;


/**
 * Called when the responses are sent to the guesser
 *
 */
- (void)didReceiveGuesser;

/**
 * Called when an error occurs during gameplay.
 *
 * @param message The error message.
 */
- (void)didReceiveErrorMessage:(NSString *)message;

/**
 * Called when a guess response is recieved
 *
 * @param correct YES if the previous guess was correct, NO if the previous guess was incorrect
 */
- (void) didReceiveGuessResponse:(BOOL) correct;

/**
 * Called when a score response is recieved
 *
 * @param scores Dictionary containing the username of the player mapped to their score
 */
- (void) didReceiveScore:(NSDictionary*) scores;


/**
 * Called when the game has ended.
 *
 * @param result The result.
 * @param winningLocation The winning location: 0 indicates none; 1-3 indicates rows 1-3;
 * 4-6 indicates columns 1-3; 5 indicates diagonal from top-left corner; 6 indicates
 * diagonal from bottom-left corner.
 */
- (void)didEndGameWithResult:(GameResult)result
             winningLocation:(NSInteger)winningLocation;

@end

/**
 * A MessageStream implementation for a two-player TicTacToe game.
 */
@interface TVCMessageStream : GCKMessageStream

@property(nonatomic, readonly) TVCPlayer * player;

/**
 * Designated initializer. Constructs a TVCMessageStream with the given delegate.
 *
 * @param delegate The delegate that will receive notifications.
 */
- (id)initWithDelegate:(id<TVCMessageStreamDelegate>)delegate;

/**
 * Joins a new game.
 *
 * @param name The name of this player.
 * @return <code>YES</code> if the request was made, <code>NO</code> if it couldn't be sent.
 */
- (BOOL)joinGameWithName:(NSString *)name;


/**
 * Sends a Response
 *
 * @param text The text answer to the game.
 * @return <code>YES</code> if the request was made, <code>NO</code> if it couldn't be sent.
 */
- (BOOL)sendResponseWithText:(NSString*)text;

/**
 * Leaves the current game. If a game is in progress this will forfeit the game.
 *
 * @return <code>YES</code> if the request was made, <code>NO</code> if it couldn't be sent.
 */
- (BOOL)leaveGame;

- (void)didReceiveMessage:(id)message;

- (void)didDetach;

@end

