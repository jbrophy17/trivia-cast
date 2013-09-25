//
//  TVCGame.m
//  TriviaCast
//
//  Created by John Brophy on 9/18/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCGame.h"

@implementation TVCGame

-(id) initWithPlayers:(NSArray *)players {
    self = [super init];
    
    if(self) {
        NSString* filePath = @"sampleInput";
        NSString* fileRoot = [[NSBundle mainBundle] pathForResource:filePath ofType:@"txt"];
        NSString* fileContents = [NSString stringWithContentsOfFile:fileRoot encoding:NSUTF8StringEncoding error:nil];
        
        self.listOfThings =[NSMutableArray arrayWithArray:[fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]];
        
        for( NSString* s in self.listOfThings) {
            NSLog(@"%@",s);
        }
        
        self.listOfPlayers = [NSMutableArray arrayWithArray:players];
        
    }
    
    return self;
}

@end
