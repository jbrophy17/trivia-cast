//
//  TVCSettingsViewController.m
//  TriviaCast
//
//  Created by John Brophy on 9/19/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCSettingsViewController.h"
#import "TVCAppDelegate.h"
#import "TVCDataSource.h"
#import "TVCLobbyViewController.h"


@interface TVCSettingsViewController () {
    NSMutableData *urlData;
    NSString * nameHold;
    bool changedPicture;
}

@end

@implementation TVCSettingsViewController

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
    self.nameInput.delegate = self;
    NSString *userName = [appDelegate userName];
    if (userName && userName.length > 0) {
        [self.nameInput setText:userName];
    }
    
    [self.profileImageView setUserInteractionEnabled:YES];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectPicture)];
    [tap setNumberOfTouchesRequired:1];
    [tap setNumberOfTapsRequired:1];
    [tap setDelegate:self];
    [self.profileImageView addGestureRecognizer:tap];
    
    NSString* path = [[appDelegate applicationDocumentDirectory] stringByAppendingFormat:@"/profilePic.jpg"];
    UIImage* profileImage = [UIImage imageWithContentsOfFile:path];
    
    if (!profileImage) {
        profileImage = [UIImage imageNamed:@"defaultProfile.jpg"];
    }
    
    changedPicture = NO;
    
    //[self setPicture:[UIImage imageNamed:@"defaultProfile.jpg"]];
    [self.profileImageView setImage:profileImage];
    /*[self.profileImageView setImage:[UIImage imageNamed:@"defaultProfile.jpg"]];
    
    
    CGRect imageRect = CGRectMake(0, 0, self.profileImageView.frame.size.width, self.profileImageView.frame.size.height);
    
    UIGraphicsBeginImageContextWithOptions(self.profileImageView.frame.size, NO, 0.0);
    // Create the clipping path and add it
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:imageRect];
    [path addClip];
    
    
    [[UIImage imageNamed:@"defaultProfile.jpg"] drawInRect:imageRect];
    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.profileImageView.image = roundedImage;
    //[self.profileImageView setFrame:imageFrame];
    */
	// Do any additional setup after loading the view.
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[appDelegate dataSource] setCurrentViewController:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)submitAction:(id)sender {
    if ([self.nameInput hasText]) {
        bool changedName = NO;
        if ( ![self.nameInput.text isEqualToString:[appDelegate userName]]) {
            NSString * name = [self.nameInput text];
            [appDelegate setUserName:name];
        
            //[[[appDelegate dataSource] getMessageStream] updateSettingsWithName:name];
            //nameHold = name;
            changedName = YES;
        }
        
        if (changedPicture) {
            
            [self sendImageToServer];
            NSString* path = [[appDelegate applicationDocumentDirectory] stringByAppendingFormat:@"/profilePic.jpg"];
            NSData* imageData = [NSData dataWithData:UIImageJPEGRepresentation(self.profileImageView.image, 1.0)];
            NSError *writeError = nil;
            
            if([imageData writeToFile:path options:NSDataWritingAtomic error:&writeError]) {
                
                if(writeError!=nil) {
                    NSLog(@"%@: Error saving image: %@", [self class], [writeError localizedDescription]);
                }
            } else {
                NSLog(@"Error unable to write to file");
            }
            
        } else if (changedName) {
            [[[appDelegate dataSource] getMessageStream] updateSettingsWithName:[appDelegate userName] andURL:[appDelegate profilePicUrl]];
        }
        
    }
    

    
    
    
    
    [self dismissViewControllerAnimated:YES completion:^(void){
        
        if ([[[appDelegate dataSource] lobbyViewController] missedCue]) {
            [[appDelegate dataSource] didReceiveRoundStartedWithCue:[[[appDelegate dataSource] lobbyViewController] cue]];
        }
    }];
}

- (IBAction)reviseOrderAction:(id)sender {
    
    [[[appDelegate dataSource] getMessageStream] sendInitializeOrderMessage];
    
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self animateTextField: textField up: YES];
}


- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self animateTextField: textField up: NO];
}

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return [textField.text length] > 0;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)disablesAutomaticKeyboardDismissal {
    return NO;
}

- (void) animateTextField: (UITextField*) textField up: (BOOL) up
{
    const int movementDistance = 80; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (up ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    self.view.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];
}

-(void)selectPicture {
    UIStoryboard *storyboard = self.storyboard;
    TVCCameraViewController *camVC = [storyboard instantiateViewControllerWithIdentifier:@"cameraViewController"];
    camVC.delegate = self;
    [self presentViewController:camVC animated:YES completion:nil];
   /* UIImagePickerController * imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.delegate = self;
    imagePicker.showsCameraControls = NO;
    [self presentViewController:imagePicker animated:YES completion:nil];*/
    
}

-(void) sendImageToServer {
    // Dictionary that holds post parameters. You can set your post parameters that your server accepts or programmed to accept.
    NSMutableDictionary* _params = [[NSMutableDictionary alloc] init];
    [_params setObject:@"1.0" forKey:@"ver"];
    [_params setObject:@"en" forKey:@"lan"];
    [_params setObject:[NSString stringWithFormat:@"%d", [[[appDelegate dataSource] player] playerNumber]] forKey:@"playerID"];
    //[_params setObject:[NSString stringWithFormat:@"%@",title] forKey:@"title"];
    
    // the boundary string : a random string, that will not repeat in post data, to separate post data fields.
    NSString *BoundaryConstant = @"---------------------------14737809831466499882746641449";
    
    // string constant for the post parameter 'file'. My server uses this name: `file`. Your's may differ
    NSString* FileParamConstant = @"file";
    
    // the server url to which the image (or the media) is uploaded. Use your server url here
    NSURL* requestURL = [NSURL URLWithString:@"http://www.jeffastephens.com/trivia-cast/uploadPic.php"];
    
    
    // create request
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setHTTPShouldHandleCookies:NO];
    [request setTimeoutInterval:120];
    [request setHTTPMethod:@"POST"];
    
    // set Content-Type in HTTP header
    NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", BoundaryConstant];
    [request setValue:contentType forHTTPHeaderField: @"Content-Type"];
    
    // post body
    NSMutableData *body = [NSMutableData data];
    
    // add params (all params are strings)
    for (NSString *param in _params) {
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", param] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", [_params objectForKey:param]] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    // add image data
    NSData *imageData = UIImageJPEGRepresentation(self.profileImageView.image, 1.0);
    if (imageData) {
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"image.jpg\"\r\n", FileParamConstant] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Type: image/jpeg\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:imageData];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
    }
    
    [body appendData:[[NSString stringWithFormat:@"%@--\r\n", BoundaryConstant] dataUsingEncoding:NSUTF8StringEncoding]];
    
    // setting the body of the post to the reqeust
    [request setHTTPBody:body];
    
    // set the content-length
    NSString *postLength = [NSString stringWithFormat:@"%d", [body length]];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    // set URL
    NSLog(@"sent");
    NSLog(@"%@", requestURL);
    [request setURL:requestURL];
    
    [[NSURLConnection connectionWithRequest:request delegate:self] start];
    
}

//overkill
-(void) setPicture:(UIImage *)image {
   // [self.profileImageView setImage:[UIImage imageNamed:@"defaultProfile.jpg"]];
    
    NSLog(@"[%f,%f]",image.size.width, image.size.height);
    
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.width);
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, 0.0);
    // Create the clipping path and add it
    UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:imageRect];
    [path addClip];
    
    
    [image drawInRect:imageRect];
    UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.profileImageView.image = roundedImage;
}

#pragma mark TVCCameraViewControllerDelegate methods

-(void) didCaptureImage:(UIImage *)image {
    NSLog(@"Got image");
    [self.profileImageView setImage:image];
    changedPicture = YES;
    
}

#pragma mark NSURLConnectionDelegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"error");
}
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
   urlData = [[NSMutableData alloc] init];
    NSLog(@"response: %@", response);
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [urlData appendData:data];
    NSLog(@"data: %@", data);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    NSError *jsonParsingError = nil;
    id object = [NSJSONSerialization JSONObjectWithData:urlData options:0 error:&jsonParsingError];
    
    if (jsonParsingError) {
        NSLog(@"JSON ERROR: %@", [jsonParsingError localizedDescription]);
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *dict = (NSMutableDictionary*) (object);
        int error = [dict gck_integerForKey:@"error"] ;
        
        if (error != 0) {
            NSLog(@"url errorcode: %i", error);
        } else {
            NSLog(@"OBJECT: %@", dict);
            NSString* urlString = [dict gck_stringForKey:@"filename"];
            NSLog(@"got url from request: %@", urlString);
#warning @"TODO: write completion block for receiving the url"
            [appDelegate setProfilePicUrl:urlString];
            [[[appDelegate dataSource] player] setImageUrlString:urlString completion:nil];
            NSLog(@"received new url, app del url is %@", [appDelegate profilePicUrl]);
            [[[appDelegate dataSource] getMessageStream] updateSettingsWithName:[appDelegate userName] andURL:urlString];
            
        }
    }
}

@end
