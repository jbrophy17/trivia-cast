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
#import "TVCOrderPickerViewController.h"
#import "TVCPlayer.h"
#import "TVCScoreView.h"

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
    self.missedCue = NO;
    [[appDelegate dataSource] setCurrentViewController:self];
    [[appDelegate dataSource] setLobbyViewController:self];
    //self.dataSource = [[TVCDataSource alloc] initWithDevice:self.device];
	// Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[appDelegate dataSource] setCurrentViewController:self];
    [self.navigationController.navigationItem setHidesBackButton:YES];
    
    NSString* path = [[appDelegate applicationDocumentDirectory] stringByAppendingFormat:@"/profilePic.jpg"];
    UIImage* profileImage = [UIImage imageWithContentsOfFile:path];
    
    if (!profileImage) {
        profileImage = [UIImage imageNamed:@"defaultProfile.jpg"];
    }
    
    [self.profileThumbnailImageView setImage:profileImage];
    
    
    [self.currentScoreLabel setText:[NSString stringWithFormat:@"%i", [[self dataSource] currentScore]]];
  

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
    [self.descriptionLabel setText:@"Please wait for all responses to be submitted"];
    //[self.navigationController pushViewController:viewController animated:YES];
}

-(void) segueToGuesserViewWithResponses:(NSDictionary *)responseDictionary andPlayers:(NSArray*)players {
    
    UIStoryboard *storyboard = self.storyboard;
    TVCGuesserViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"guesserViewController"];
    
    // Configure the new view controller here.
    NSMutableArray * keyHold = [NSMutableArray array];
    for(id key in responseDictionary) {
         NSLog(@"key: %@",key);
       // [keyHold addObject:[responseDictionary objectForKey:key]];
        [keyHold addObject:[NSString stringWithString:[responseDictionary objectForKey:key]]];
    }
    NSLog(@"length of responses: %i",[keyHold count]);
    NSMutableArray * updatedPlayers = [NSMutableArray array];
    
    viewController.responses = [NSMutableArray arrayWithArray:keyHold];
    
    
    for (TVCPlayer* p in players) {
        if(p.playerNumber != [[appDelegate dataSource] player].playerNumber) {
            [updatedPlayers addObject:p];
        }
    }
    viewController.players = [NSMutableArray arrayWithArray:updatedPlayers];
    viewController.responseDictionary = [NSMutableDictionary dictionaryWithDictionary:responseDictionary];
    
    NSLog(@"segue to guesser view");
    
    if ([[[appDelegate dataSource] currentViewController] isKindOfClass:[TVCReaderViewController class]]) {
        NSLog(@"guesser view, should dissmiss");
        [[[appDelegate dataSource] currentViewController] dismissViewControllerAnimated:YES completion:^(void) {
            [self presentViewController:viewController animated:YES completion:nil];
        }];
    } else {
        NSLog(@"Wasn't in reader view");
        [self presentViewController:viewController animated:YES completion:nil];
    }
}

- (void) segueToOrderPickerView {
    UIStoryboard *storyboard = self.storyboard;
    TVCOrderPickerViewController *viewController = [storyboard instantiateViewControllerWithIdentifier:@"orderPickerViewController"];
    [appDelegate dataSource].orderPickerViewController = viewController;
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
        NSLog(@"key: %@",key);
        [keyHold addObject:[NSString stringWithString:[responseDictionary objectForKey:key]]];
    }
        NSLog(@"length of responses: %i",[keyHold count]);
    viewController.responses = [NSMutableArray arrayWithArray:keyHold];
    //NSLog(@"vc label: %@",viewController.promptLabel.text);
    [self presentViewController:viewController animated:YES completion:nil];
    //[self.navigationController pushViewController:viewController animated:YES];
}

-(void) updateScoreList {
    
    for (UIView* subview in self.scoresScrollView.subviews) {
        [subview removeFromSuperview];
    }
    int newScore = *([[[appDelegate dataSource] player] score]);
    [self.currentScoreLabel setText:[NSString stringWithFormat:@"%i", newScore]] ;
    
    int ycount = 0;
   // int xcount = 0;
    int buffer = 10;
    int scoreHeight = 90;
    int scoreWidth = self.scoresScrollView.frame.size.width;
    
    
    for(TVCPlayer *curP in [[appDelegate dataSource] players]) {
        if (curP.playerNumber != [[[appDelegate dataSource] player] playerNumber]) {
            
            //UIImageView* imgView = (UIImageView*)[self.imageDict objectForKey:[NSNumber numberWithInt:curP.playerNumber]];
            
            UIImage* img = [curP profilePicture]; //[curP profilePicture];
            
            if (!img) {
                img = [UIImage imageNamed:@"defaultProfile.jpg"];
                
               // [self.imageDict setObject:imgView forKey:[NSNumber numberWithInt:curP.playerNumber]];
            }
           // float xCoord = buffer + xcount * scoreHeight;
            float yCoord = ycount * (scoreHeight + buffer);
            
            TVCScoreView * holdScore = [[TVCScoreView alloc] initWithFrame:CGRectMake(0, yCoord, scoreWidth, scoreHeight)];
            
            [[holdScore profileThumbnail ] setImage:img];
            [[holdScore scoreLabel] setText:[NSString stringWithFormat:@"%i",*curP.score]];
            [[holdScore nameLabel] setText:curP.name];
            
            [self.scoresScrollView addSubview:holdScore];
            [holdScore bringSubviewToFront:self.scoresScrollView];
            
            ycount++;
            
           /* if (ycount > 0) {
                xcount++;
                ycount = 0;
            } else {
                ycount++;
            }*/
            
        }
        
        
        
    }
    NSLog(@"imageDict: %@", self.imageDict);
}


@end
