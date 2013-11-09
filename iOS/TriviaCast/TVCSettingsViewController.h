//
//  TVCSettingsViewController.h
//  TriviaCast
//
//  Created by John Brophy on 9/19/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TVCPlayer.h"
#import "TVCCameraViewController.h"

@interface TVCSettingsViewController : UIViewController <UITextFieldDelegate,UIGestureRecognizerDelegate, TVCCameraViewControllerDelegate,NSURLConnectionDelegate>

@property (strong, nonatomic) IBOutlet UITextField * nameInput;
@property (strong, nonatomic) IBOutlet UIButton * submitButton;
@property (strong, nonatomic) IBOutlet UIImageView * profileImageView;
@property (weak, nonatomic) IBOutlet UIImageView *maskImageView;

- (IBAction)submitAction:(id)sender;
- (void)selectPicture;
- (void) setPicture:(UIImage*)image;
@end
