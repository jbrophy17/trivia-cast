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
    imageSetCompletion completionBlock;
    NSInteger currentAttempts;
}
-(BOOL)dataIsValidJPEG:(NSData *)data;

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
        self.maxAttempts = 2;
        currentAttempts = 0;
        [self setImageUrlString:URL];
    }
    
    return self;
}

- (void) setImageUrlString:(NSString *)imageUrlString {
    [self setImageUrlString:imageUrlString completion:nil];
}

-(void) setImageUrlString:(NSString *)imageUrlString completion:(imageSetCompletion)comp {
    //Attempted to connect and failed too many times
    if (currentAttempts > self.maxAttempts) {
        NSLog(@"Attempted to set imageURL over max");
        currentAttempts = 0;
        self.profilePicture = nil;
        completionBlock = nil;
        if (comp) {
            comp(NO);
        }
        return;
    }
    
    NSLog(@"setImageUrlString %@", imageUrlString);
    completionBlock = nil;
    currentAttempts++;
    
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
        NSURLConnection *theConnection=[NSURLConnection connectionWithRequest:theRequest delegate:self];
        [theConnection start];
        
        if (!theConnection) {
            requestData = nil;
            self.profilePicture = nil;
            completionBlock = nil;
            currentAttempts = 0;
            NSLog(@"Error creatingConnection");
            // Inform the user that the connection failed.
            if(comp) {
                comp(NO);
            }
        } else {
            //sets completion block to be run, after the server request has been finished
            completionBlock = comp;
        }
        
    } else {
        if(comp) {
            comp(YES);
        }
        currentAttempts = 0;
        completionBlock = nil;
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
        if ( [self dataIsValidJPEG:requestData] ) {
            self.profilePicture = [[UIImage alloc] initWithData:requestData];
            if (self.profilePicture == nil) {
                NSLog(@"profile pic is null");
            }
            NSLog(@"%@ got picture: %@", self.name, self.imageUrlString);
            
            if (completionBlock) {
                completionBlock(YES);
            }
            
        } else {
            NSLog(@"request data is corrupted, trying again");
            self.profilePicture = nil;
            [self setImageUrlString:self.imageUrlString completion:completionBlock];
        }
    } else {
        NSLog(@"requestData nil");
        if(completionBlock) {
            completionBlock(NO);
        }
    }
}

-(BOOL)dataIsValidJPEG:(NSData *)data
{
    if (!data || data.length < 2) return NO;
    
    NSInteger totalBytes = data.length;
    const char *bytes = (const char*)[data bytes];
    
    return (bytes[0] == (char)0xff &&
            bytes[1] == (char)0xd8 &&
            bytes[totalBytes-2] == (char)0xff &&
            bytes[totalBytes-1] == (char)0xd9);
}


@end
