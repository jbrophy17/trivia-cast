//
//  TVCLobbyViewController.m
//  TriviaCast
//
//  Created by John Brophy on 9/19/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCLobbyViewController.h"
#import "TVCDataSource.h"
#import "TVCResponseViewController.h"
#import "TVCReaderViewController.h"
#import "TVCGuesserViewController.h"

@interface TVCLobbyViewController ()

@end

@implementation TVCLobbyViewController

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
    [[appDelegate dataSource] setCurrentViewController:self];
    [[appDelegate dataSource] setLobbyViewController:self];
    //self.dataSource = [[TVCDataSource alloc] initWithDevice:self.device];
	// Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[appDelegate dataSource] setCurrentViewController:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) segueToResponseViewWithCue:(NSString *)cue {
    NSLog(@"got cue: %@", cue);
    UIStoryboard *storyboard = self.storyboard;
    TVCResponseViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"responseViewController"];
    
    // Configure the new view controller here.
    viewController.promptLabelText = cue;
    //NSLog(@"vc label: %@",viewController.promptLabel.text);
    [self presentViewController:viewController animated:YES completion:nil];
    //[self.navigationController pushViewController:viewController animated:YES];
}

-(void) segueToGuesserViewWithResponses:(NSDictionary *)responseDictionary andPlayers:(NSArray*)players {
    
    UIStoryboard *storyboard = self.storyboard;
    TVCGuesserViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"guesserViewController"];
    
    // Configure the new view controller here.
    NSMutableArray * keyHold = [NSMutableArray array];
    for(id key in responseDictionary) {
        [keyHold addObject:key];
    }
    viewController.responses = [NSMutableArray arrayWithArray:keyHold];
    viewController.players = [NSMutableArray arrayWithArray:players];
    viewController.responseDictionary = [NSMutableDictionary dictionaryWithDictionary:responseDictionary];
    [self presentViewController:viewController animated:YES completion:nil];
}

- (IBAction)startRoundAction:(id)sender {
    
    [[[appDelegate dataSource] getMessageStream] sendNextRound];
    
}

-(void) segueToReaderViewWithResponses:(NSDictionary *)responseDictionary {
    UIStoryboard *storyboard = self.storyboard;
    TVCReaderViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"readerViewController"];
    
    // Configure the new view controller here.
    NSMutableArray * keyHold = [NSMutableArray array];
    for(id key in responseDictionary) {
        [keyHold addObject:key];
    }
    viewController.responses = [NSMutableArray arrayWithArray:keyHold];
    //NSLog(@"vc label: %@",viewController.promptLabel.text);
    [self presentViewController:viewController animated:YES completion:nil];
    //[self.navigationController pushViewController:viewController animated:YES];
}

@end
