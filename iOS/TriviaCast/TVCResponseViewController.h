//
//  TVCResponseViewController.h
//  TriviaCast
//
//  Created by John Brophy on 9/22/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GCKDevice;
@class GCKApplicationSession;
@class TVCPlayer;
@class TVCMessageStream;

@interface TVCResponseViewController : UIViewController 

@property(nonatomic, strong) GCKDevice *device;
@property (weak, nonatomic) IBOutlet UILabel *promptLabel;
@property (weak, nonatomic) IBOutlet UITextView *responseTextView;
@property (weak, nonatomic) IBOutlet UIButton *submitButton;
@property (weak, nonatomic) IBOutlet UIImageView *iconImageView;

@property (strong, nonatomic) NSString* promptLabelText;

- (IBAction)submitAction:(id)sender;


@end
