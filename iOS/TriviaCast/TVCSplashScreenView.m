//
//  TVCSplashScreenView.m
//  TriviaCast
//
//  Created by John Brophy on 11/16/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCSplashScreenView.h"

@implementation TVCSplashScreenView

- (id)initWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle
{
    self = [super initWithFrame:[UIScreen mainScreen].bounds];
    if (self) {
        self.bufferSpace = 10.0;
        //set background color
        [self setBackgroundColor:[UIColor whiteColor]];
        
        //Set default Title label
        self.titleLabel = [[UILabel alloc] init];
        [self.titleLabel setText:title];
        [self.titleLabel setTextColor:[UIColor colorWithRed:0.0 green:128.0/255.0 blue:1.0 alpha:1.0]];
       
        //[test setValue:[NSNumber numberWithFloat:34.0] forKey:@"size"];
        //[self.titleLabel setFont:test];
        
        [self.titleLabel sizeToFit];
        CGRect defaultTitleFrame = CGRectMake(self.frame.size.width / 2.0 - self.titleLabel.bounds.size.width / 2.0, self.bounds.size.height / 2.0 - self.titleLabel.bounds.size.height, self.titleLabel.bounds.size.width, self.titleLabel.bounds.size.height);
        
        [self.titleLabel setFrame:defaultTitleFrame];
        [self addSubview:self.titleLabel];
        
        //Set default Subtitle lable
        self.subtitleLabel = [[UILabel alloc] init];
        [self.subtitleLabel setText:subtitle];
         [self.subtitleLabel setTextColor:[UIColor colorWithRed:102.0/255.0 green:204.0/255.0 blue:1.0 alpha:1.0]];
        [self.subtitleLabel sizeToFit];
        CGRect defaultSubtitleFrame = CGRectMake(self.frame.size.width / 2.0 - self.subtitleLabel.bounds.size.width / 2.0, defaultTitleFrame.origin.y + defaultTitleFrame.size.height + self.bufferSpace, self.subtitleLabel.bounds.size.width, self.subtitleLabel.bounds.size.height);
        [self.subtitleLabel setFrame:defaultSubtitleFrame];
        [self addSubview:self.subtitleLabel];
        
        //Set default indicator
        self.indicatorSize = 30.0;
        self.indicator = [[UIActivityIndicatorView alloc] init];
        CGRect defaultIndicatorFrame = CGRectMake(self.frame.size.width / 2.0 - self.indicatorSize / 2.0, self.frame.size.height - self.bufferSpace - self.indicatorSize, self.indicatorSize, self.indicatorSize);
        [self.indicator setFrame:defaultIndicatorFrame];
        [self.indicator startAnimating];
        [self addSubview:self.indicator];
    }
    return self;
}

- (void) setTitleLabel:(UILabel *)titleLabel {
    _titleLabel = titleLabel;
    
    [self.titleLabel sizeToFit];
    [self.titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    CGRect titleFrame = CGRectMake(self.frame.size.width / 2.0, self.bufferSpace, self.titleLabel.bounds.size.width, self.titleLabel.bounds.size.height);
    [self.titleLabel setFrame:titleFrame];
}

- (void) setSubtitleTitleLabel:(UILabel *)subtitleLabel {
    _subtitleLabel = subtitleLabel;
    
    [self.subtitleLabel sizeToFit];
    [self.subtitleLabel setTextAlignment:NSTextAlignmentCenter];
    
    CGRect subtitleFrame = CGRectMake(self.frame.size.width / 2.0, self.subtitleLabel.frame.origin.y + self.subtitleLabel.frame.size.height + self.bufferSpace, self.subtitleLabel.bounds.size.width, self.subtitleLabel.bounds.size.height);
    [self.titleLabel setFrame:subtitleFrame];
}

@end
