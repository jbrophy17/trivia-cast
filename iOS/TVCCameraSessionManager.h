//
//  TVCCameraSessionManager.h
//  TriviaCast
//
//  Created by John Brophy on 11/4/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

#define kImageCapturedSuccessfully @"imageCapturedSuccessfully"

@interface TVCCameraSessionManager : NSObject

@property (retain) AVCaptureVideoPreviewLayer *previewLayer;
@property (retain) AVCaptureSession *captureSession;
@property (retain) AVCaptureStillImageOutput *stillImageOutput;
@property (nonatomic, retain) UIImage *stillImage;

- (void)addVideoPreviewLayer;
- (void)addVideoInput;
- (void)toggleVideoInput;
- (void)addStillImageOutput;
- (void)captureStillImage;

@end
