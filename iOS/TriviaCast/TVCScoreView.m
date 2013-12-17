//
//  TVCScoreView.m
//  TriviaCast
//
//  Created by John Brophy on 11/6/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCScoreView.h"

@implementation TVCScoreView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        int buffer = 5;
        
        float scoreHeight = frame.size.height / 3.0 - buffer;
        float profileDimension = (scoreHeight + buffer) * 2.0;
        
        self.profileThumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, profileDimension, profileDimension) ];
        self.scoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, profileDimension + buffer, profileDimension, scoreHeight)];
        [self.scoreLabel setAdjustsFontSizeToFitWidth:YES];
        [self.scoreLabel setMinimumScaleFactor:.25];
        [self.scoreLabel setTextColor:[UIColor colorWithRed:(102.0/255.0) green:(204.0/255.0) blue:1.0 alpha:1.0]];
        [self.scoreLabel setTextAlignment:NSTextAlignmentCenter];
        
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(profileDimension + buffer, 0, frame.size.width - profileDimension - buffer, profileDimension)];
        [self.nameLabel setAdjustsFontSizeToFitWidth:YES];
        [self.nameLabel setMinimumScaleFactor:.25];
        [self.nameLabel setTextColor:[UIColor colorWithRed:0.0 green:(128.0/255.0) blue:1.0 alpha:1.0]];
        
        
        [self addSubview:self.profileThumbnail];
        [self addSubview:self.nameLabel];
        [self addSubview:self.scoreLabel];
        
    }
    return self;
}

@end
