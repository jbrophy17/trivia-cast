//
//  TVCPlayer.h
//  TriviaCast
//
//  Created by John Brophy on 9/18/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^imageSetCompletion)(BOOL);

@interface TVCPlayer : NSObject <NSURLConnectionDelegate>

@property (nonatomic, strong) NSString * name;
@property (nonatomic) NSInteger score;
@property (nonatomic) BOOL isReader;
@property (nonatomic) BOOL isGuessing;
@property (nonatomic) BOOL isOut;
@property (nonatomic) NSInteger playerNumber;
@property (nonatomic) UIImage* profilePicture;
@property (nonatomic,strong) NSString* imageUrlString;
@property BOOL updatePicture;

-(id) initWithName:(NSString*) name andNumber:(NSInteger) number andImageURL:(NSString *)URL;
-(void) setImageUrlString:(NSString*)imageUrlString completion:(imageSetCompletion) comp;

@end
