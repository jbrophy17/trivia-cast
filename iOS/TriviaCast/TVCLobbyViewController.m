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
#import "TVCPlayer.h"

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
     NSLog(@"view did load");
    [[appDelegate dataSource] setCurrentViewController:self];
    [[appDelegate dataSource] setLobbyViewController:self];
    //self.dataSource = [[TVCDataSource alloc] initWithDevice:self.device];
	// Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
     NSLog(@"view will appear");
    [[appDelegate dataSource] setCurrentViewController:self];
    [self.navigationController.navigationItem setHidesBackButton:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) segueToResponseViewWithCue:(NSString *)cue {
    UIStoryboard *storyboard = self.storyboard;
    TVCResponseViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"responseViewController"];
    
    // Configure the new view controller here.
    viewController.promptLabelText = cue;
    //NSLog(@"vc label: %@",viewController.promptLabel.text);
    [self presentViewController:viewController animated:YES completion:nil];
    
    [self.roundStartButton setHidden:YES];
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
    
    NSMutableArray * updatedPlayers = [NSMutableArray array];
    
    viewController.responses = [NSMutableArray arrayWithArray:keyHold];
    
    
    for (TVCPlayer* p in players) {
        if(p.playerNumber != [[appDelegate dataSource] player].playerNumber) {
            [updatedPlayers addObject:p];
        }
    }
    viewController.players = [NSMutableArray arrayWithArray:updatedPlayers];
    viewController.responseDictionary = [NSMutableDictionary dictionaryWithDictionary:responseDictionary];
    [self presentViewController:viewController animated:YES completion:nil];
}

- (IBAction)startRoundAction:(id)sender {
    
    [[[appDelegate dataSource] getMessageStream] sendNextRound];
    
}

- (IBAction)quitAction:(id)sender {
    [[[appDelegate dataSource] getMessageStream] leaveGame];
    [self.navigationController popViewControllerAnimated:YES];
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
