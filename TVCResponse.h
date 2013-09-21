//
//  TVCResponse.h
//  TriviaCast
//
//  Created by John Brophy on 9/18/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TVCPlayer.h"

@interface TVCResponse : NSObject

@property (nonatomic,strong) TVCPlayer *author;
@property (nonatomic, strong) NSString *message;

-(id) initWithAuthor:(TVCPlayer*)author andMessage:(NSString*)message;


@end
