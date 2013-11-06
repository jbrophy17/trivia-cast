//
//  TVCCameraViewController.h
//  TriviaCast
//
//  Created by John Brophy on 11/4/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TVCCameraSessionManager.h"

@protocol TVCCameraViewControllerDelegate

/*
 * Called when the camera has successfully taken a picture
 *
 * @param image The UIImage that was captured by the camera
 */
-(void) didCaptureImage:(UIImage*)image;

@end


@interface TVCCameraViewController : UIViewController

@property (retain) TVCCameraSessionManager *sessionManager;
@property(nonatomic, strong, readwrite) id<TVCCameraViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIButton *cameraButton;
@property (weak, nonatomic) IBOutlet UIButton *libraryButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIImageView *maskImageVIew;
@property (weak, nonatomic) IBOutlet UIButton *reverseCameraButton;

- (IBAction)cameraAction:(id)sender;
- (IBAction)libraryAction:(id)sender;
- (IBAction)cancelAction:(id)sender;
- (IBAction)reverseCameraAction:(id)sender;
@end
