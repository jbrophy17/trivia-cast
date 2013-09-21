//
//  TVCPlayer.m
//  TriviaCast
//
//  Created by John Brophy on 9/18/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCPlayer.h"

@implementation TVCPlayer

-(id) initWithName:(NSString *)name {
    self = [super init];
    
    if (self) {
        self.name = [NSString stringWithString:name];
        self.score = 0;
        self.isReader = NO;
        self.isGuessing = NO;
    }
    
    return self;
}

@end
