//
//  TVCCameraViewController.m
//  TriviaCast
//
//  Created by John Brophy on 11/4/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCCameraViewController.h"

@interface TVCCameraViewController ()


    - (void) imageCaptured;
@end

@implementation TVCCameraViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.sessionManager = [[TVCCameraSessionManager alloc] init];
    [self.sessionManager addVideoInput];
    [self.sessionManager addVideoPreviewLayer];
    [self.sessionManager addStillImageOutput];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageCaptured) name:kImageCapturedSuccessfully object:nil];
    
    float padding = self.maskImageVIew.frame.origin.y;
    
    [[self.sessionManager previewLayer] setFrame:CGRectMake(0, padding, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.width)];
    
    [[self.view layer] addSublayer:[[self sessionManager] previewLayer]];
    
    [self.view bringSubviewToFront:self.maskImageVIew];
    [[self.sessionManager captureSession] startRunning];
    
	// Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) imageCaptured {
    [self.delegate didCaptureImage:[[self sessionManager] stillImage]];
    [self dismissViewControllerAnimated:YES completion:^(void){
        self.sessionManager = nil;
    }];
}

- (IBAction)cameraAction:(id)sender {
    [[self sessionManager] captureStillImage];
}

- (IBAction)libraryAction:(id)sender {
}

- (IBAction)cancelAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:^(void){
        self.sessionManager = nil;
    }];
}

- (IBAction)reverseCameraAction:(id)sender {
    [[self sessionManager] toggleVideoInput];
}
@end
