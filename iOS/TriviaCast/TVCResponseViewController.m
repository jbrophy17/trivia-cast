//
//  TVCResponseViewController.m
//  TriviaCast
//
//  Created by John Brophy on 9/22/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCResponseViewController.h"
#import "TVCAppDelegate.h"
#import "TVCMessageStream.h"
#import "TVCGame.h"
#import "TVCDataSource.h"

#import <GCKFramework/GCKFramework.h>

@interface TVCResponseViewController () 

@property (nonatomic) TVCPlayer * player;

@end

@implementation TVCResponseViewController

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
	// Do any additional setup after loading the view.
    [[appDelegate dataSource] setCurrentViewController:self];
   // self.responseTextView.delegate = self;
    [self.promptLabel setText:self.promptLabelText];
    [self.promptLabel setNumberOfLines:0];
    [self.promptLabel setLineBreakMode:NSLineBreakByWordWrapping];
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


// Start the remote application session when the view appears.
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([[[appDelegate dataSource] player] isReader]) {
        [self.iconImageView setImage:[UIImage imageNamed:@"readerIcon.png"]];
        NSLog(@"reader");
    } else if ([[[appDelegate dataSource] player] isGuessing]) {
        [self.iconImageView setImage:[UIImage imageNamed:@"guesserIcon.png"]];
        NSLog(@"guesser");
    } else {
        NSLog(@"none");
        [self.iconImageView setImage:nil];
    }
    
    //[self startSession];
}

// End the remote application session when the view disappears.
- (void)viewDidDisappear:(BOOL)animated {
    //[self endSession];
    [super viewDidDisappear:animated];
}

- (void) shouldDisplayOverlay:(BOOL) value {
    
    
}


- (IBAction)submitAction:(id)sender {
    NSString *responseString = self.responseTextView.text;
    NSLog(@"Submit");
    [[[appDelegate dataSource] getMessageStream] sendResponseWithText:responseString];
    [self.responseTextView resignFirstResponder];
    
    //[self dismissViewControllerAnimated:YES completion:nil];
    //NSLog(@"%hhd",[_messageStream joinGameWithName:[self currentUserName]]);
}



@end
