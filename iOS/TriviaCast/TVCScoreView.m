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
        int width = 25;
        int buffer = 5;
        self.profileThumbnail = [[UIImageView alloc] initWithFrame:CGRectMake(0, (frame.size.height / 2) - (width / 2), width, width) ];
        self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(width + buffer, buffer, width, width)];
        self.scoreLabel = [[UILabel alloc] initWithFrame:CGRectMake(width + buffer, self.nameLabel.frame.origin.y + self.nameLabel.frame.size.height + buffer, width, width)];
    }
    return self;
}

@end
