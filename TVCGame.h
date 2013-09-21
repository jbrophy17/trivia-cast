//
//  TVCGame.h
//  TriviaCast
//
//  Created by John Brophy on 9/18/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TVCPlayer.h"


@interface TVCGame : NSObject
@property (nonatomic, strong) NSMutableArray * listOfPlayers;
@property (nonatomic, strong) NSMutableArray * listOfThings;
@property (nonatomic, strong) NSString * currentThing;

@property (nonatomic, strong) TVCPlayer * reader;
@property (nonatomic, strong) TVCPlayer * guesser;

-(id) initWithHost:(TVCPlayer*) host;

@end
