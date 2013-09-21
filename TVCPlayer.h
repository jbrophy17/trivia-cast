//
//  TVCPlayer.h
//  TriviaCast
//
//  Created by John Brophy on 9/18/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface TVCPlayer : NSObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic) NSInteger * score;
@property (nonatomic) BOOL * isReader;
@property (nonatomic) BOOL * isGuessing;

-(id) initWithName:(NSString*) name;

@end
