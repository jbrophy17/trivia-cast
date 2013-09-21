//
//  TVCSettingsViewController.h
//  TriviaCast
//
//  Created by John Brophy on 9/19/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TVCPlayer.h"

@interface TVCSettingsViewController : UIViewController <UITextFieldDelegate>

@property (strong, nonatomic) IBOutlet UITextField * nameInput;
@property (strong, nonatomic) IBOutlet UIButton * submitButton;
@property (strong, nonatomic) IBOutlet UIImageView * profileImageView;

- (IBAction)submitAction:(id)sender;

@end
