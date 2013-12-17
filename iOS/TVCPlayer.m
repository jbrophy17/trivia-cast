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
        self.profilePicture = nil;
        [self setImageUrlString:URL];
    }
    
    return self;
}

-(void) setImageUrlString:(NSString *)imageUrlString completion:(imageSetCompletion)comp {
    NSLog(@"setImageUrlString %@", imageUrlString);
    if ( (self.profilePicture == nil && ![self.imageUrlString isEqualToString:@""]) || ![self.imageUrlString isEqualToString:imageUrlString]) {
        NSLog(@"in the set url loop");
        _imageUrlString = imageUrlString;
        
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:self.imageUrlString]
                                                  cachePolicy:NSURLRequestUseProtocolCachePolicy
                                              timeoutInterval:15.0];
        
        // Create the NSMutableData to hold the received data.
        // receivedData is an instance variable declared elsewhere.
        requestData = [NSMutableData dataWithCapacity: 0];
        
        // create the connection with the request
        // and start loading the data
        NSURLConnection *theConnection=[NSURLConnection connectionWithRequest:theRequest delegate:self];//[[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        [theConnection start];
        
        if (!theConnection) {
            // Release the receivedData object.
            requestData = nil;
            self.profilePicture = nil;
            NSLog(@"Error creatingConnection");
            // Inform the user that the connection failed.
            if(comp) {
                comp(NO);
            }
        } else {
#warning TODO: make this fire in the actual url completion method
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

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [requestData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [requestData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Connection failed: %@", [error description]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (requestData)
    {
        self.profilePicture = [[UIImage alloc] initWithData:requestData];
        if (self.profilePicture == nil) {
            NSLog(@"profile pic is null, you trash programmer");
        }
        NSLog(@"%@ got picture: %@", self.name, self.imageUrlString);
    } else {
        NSLog(@"requestData nil");
    }
}


@end
