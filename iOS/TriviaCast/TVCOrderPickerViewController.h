//
//  TVCOrderPickerViewController.h
//  TriviaCast
//
//  Created by John Brophy on 12/10/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TVCOrderPickerViewController : UIViewController
@property (weak, nonatomic) IBOutlet UILabel *instructionsLabel;
@property (weak, nonatomic) IBOutlet UIButton *orderButton;
- (IBAction)orderButtonAction:(id)sender;

@end
