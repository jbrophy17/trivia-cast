//
//  TVCPlayer.m
//  TriviaCast
//
//  Created by John Brophy on 9/18/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCPlayer.h"


@interface TVCPlayer () {
    NSMutableData* requestData;
}


@end

@implementation TVCPlayer


-(id) initWithName:(NSString *)name andNumber:(NSInteger )number andImageURL:(NSString *)URL{
    self = [super init];
    
    if (self) {
        self.name = [NSString stringWithString:name];
        self.playerNumber = number;
        self.score = 0;
        self.isReader = NO;
        self.isGuessing = NO;
        self.isOut = NO;
        self.updatePicture = NO;
        [self setImageUrlString:URL];
    }
    
    return self;
}

-(void) setImageUrlString:(NSString *)imageUrlString completion:(imageSetCompletion)comp {
    if (self.imageUrlString != imageUrlString) {
        _imageUrlString = imageUrlString;
        
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:self.imageUrlString]
                                                  cachePolicy:NSURLRequestUseProtocolCachePolicy
                                              timeoutInterval:15.0];
        
        // Create the NSMutableData to hold the received data.
        // receivedData is an instance variable declared elsewhere.
        requestData = [NSMutableData dataWithCapacity: 0];
        
        // create the connection with the request
        // and start loading the data
        NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        if (!theConnection) {
            // Release the receivedData object.
            requestData = nil;
            NSLog(@"Error creatingConnection");
            // Inform the user that the connection failed.
            if(comp) {
                comp(NO);
            }
        } else {
            if(comp) {
                comp(YES);
            }
        }
        
    } else {
        if(comp) {
            comp(YES);
        }
    }
    
}

#pragma NSURLConnectionDelegate methods

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (requestData)
    {
        _profilePicture = [[UIImage alloc] initWithData:requestData];
    }
}


@end
