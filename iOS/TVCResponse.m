//
//  TVCResponse.m
//  TriviaCast
//
//  Created by John Brophy on 9/18/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCResponse.h"

@implementation TVCResponse

-(id) initWithAuthor:(TVCPlayer *)author andMessage:(NSString *)message {
    self = [super init];
    if(self) {
        self.author = author;
        self.message = message;
    }
    return self;
}

@end
