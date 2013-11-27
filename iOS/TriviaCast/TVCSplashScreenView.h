//
//  TVCSplashScreenView.h
//  TriviaCast
//
//  Created by John Brophy on 11/16/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TVCSplashScreenView : UIView

@property (strong, nonatomic) UILabel *titleLabel;
@property (strong, nonatomic) UILabel *subtitleLabel;
@property (strong, nonatomic) UIActivityIndicatorView *indicator;

@property float bufferSpace;
@property float indicatorSize;

- (id)initWithTitle:(NSString*)title andSubtitle:(NSString*)subtitle;

@end
