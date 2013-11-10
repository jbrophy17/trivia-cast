//
//  TVCCameraSessionManager.m
//  TriviaCast
//
//  Created by John Brophy on 11/4/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCCameraSessionManager.h"
#import <ImageIO/ImageIO.h>

@interface TVCCameraSessionManager ()
{
    NSArray* listOfDevices;
    int currentDevice;
    AVCaptureDeviceInput *currentInput;
}

@end

@implementation TVCCameraSessionManager

- (id)init {
	if ((self = [super init])) {
		[self setCaptureSession:[[AVCaptureSession alloc] init]];
	}
	return self;
}

- (void)addVideoPreviewLayer {
    [self setPreviewLayer:[[AVCaptureVideoPreviewLayer alloc] initWithSession:[self captureSession]]];
	
	[[self previewLayer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
}

- (void)addVideoInput {
    listOfDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    currentDevice = 0;
	AVCaptureDevice *videoDevice = [listOfDevices objectAtIndex:currentDevice];
    [self incrementDevice];
    //AVCaptureDevice *videoDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
	if (videoDevice) {
		NSError *error;
		currentInput = [AVCaptureDeviceInput deviceInputWithDevice:videoDevice error:&error];
		if (!error) {
			if ([[self captureSession] canAddInput:currentInput])
				[[self captureSession] addInput:currentInput];
			else
				NSLog(@"Couldn't add video input");
		}
		else
			NSLog(@"Couldn't create video input");
	}
	else
		NSLog(@"Couldn't create video capture device");
}

- (void)addStillImageOutput
{
    [self setStillImageOutput:[[AVCaptureStillImageOutput alloc] init]];
    NSDictionary *outputSettings = [[NSDictionary alloc] initWithObjectsAndKeys:AVVideoCodecJPEG,AVVideoCodecKey,nil];
    [[self stillImageOutput] setOutputSettings:outputSettings];
    
    AVCaptureConnection *videoConnection = nil;
    for (AVCaptureConnection *connection in [[self stillImageOutput] connections]) {
        for (AVCaptureInputPort *port in [connection inputPorts]) {
            if ([[port mediaType] isEqual:AVMediaTypeVideo] ) {
                videoConnection = connection;
                break;
            }
        }
        if (videoConnection) {
            break;
        }
    }
    
    [[self captureSession] addOutput:[self stillImageOutput]];
}

- (void)captureStillImage
{
	AVCaptureConnection *videoConnection = nil;
	for (AVCaptureConnection *connection in [[self stillImageOutput] connections]) {
		for (AVCaptureInputPort *port in [connection inputPorts]) {
			if ([[port mediaType] isEqual:AVMediaTypeVideo]) {
				videoConnection = connection;
				break;
			}
		}
		if (videoConnection) {
            break;
        }
	}
    
	NSLog(@"about to request a capture from: %@", [self stillImageOutput]);
	[[self stillImageOutput] captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef imageSampleBuffer, NSError *error) {
            CFDictionaryRef exifAttachments = CMGetAttachment(imageSampleBuffer, kCGImagePropertyExifDictionary, NULL);
            if (exifAttachments) {
                 NSLog(@"attachements: %@", exifAttachments);
             } else {
                 NSLog(@"no attachments");
             }
             NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageSampleBuffer];
             UIImage *image = [[UIImage alloc] initWithData:imageData];
            CGRect cropRect = CGRectMake((image.size.height - image.size.width) / 2, 0, image.size.width, image.size.width);
            CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], cropRect);
            UIImage *img = [UIImage imageWithCGImage:imageRef scale:image.scale orientation:image.imageOrientation];
            CGImageRelease(imageRef);
        
        
        
        CGRect imageRect = CGRectMake(0, 0, img.size.width, img.size.height);
        
        UIGraphicsBeginImageContextWithOptions(img.size, NO, 0.0);
        // Create the clipping path and add it
        UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:imageRect];
        [path addClip];
        
        
        [img drawInRect:imageRect];
        UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        
        
        
        
        

             [self setStillImage:roundedImage];
            
             [[NSNotificationCenter defaultCenter] postNotificationName:kImageCapturedSuccessfully object:nil];
        }];
}

-(void) toggleVideoInput {
    if (currentInput) {
        [[self captureSession] removeInput:currentInput];
        NSError *error;
		currentInput = [AVCaptureDeviceInput deviceInputWithDevice:[listOfDevices objectAtIndex:currentDevice] error:&error];
        if (!error) {
            if ([[self captureSession] canAddInput:currentInput]) {
                [[self captureSession] addInput:currentInput];
                [self incrementDevice];
            } else {
                NSLog(@"Couldn't add video input");
            }
        } else {
			NSLog(@"Couldn't create video input");
        }
    }
}

-(void) incrementDevice {
    currentDevice++;
    if (currentDevice > [listOfDevices count] -1) {
        currentDevice = 0;
    }
}

@end
