//
//  TVCOrderPickerViewController.m
//  TriviaCast
//
//  Created by John Brophy on 12/10/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCOrderPickerViewController.h"
#import "TVCAppDelegate.h"
#import "TVCDataSource.h"

@interface TVCOrderPickerViewController ()

@end

@implementation TVCOrderPickerViewController

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

- (IBAction)orderButtonAction:(id)sender {
    [[[appDelegate dataSource] getMessageStream] sendOrderMessage];
    [[self orderButton] setEnabled:NO];
    [[self instructionsLabel] setText:@"Order set. Please wait for the remaining players..."];
}
@end
