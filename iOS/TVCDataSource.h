//
//  TVCDataSource.h
//  TriviaCast
//
//  Created by John Brophy on 9/25/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TVCMessageStream.h"
#import "TVCAppDelegate.h"

@interface TVCDataSource : NSObject <TVCMessageStreamDelegate, GCKApplicationSessionDelegate>
@property(nonatomic, strong) GCKDevice *device;

- (BOOL) guessPlayer:(int)player forResponse:(NSString*)response;

@end
