//
//  TVCGuesserViewController.m
//  TriviaCast
//
//  Created by John Brophy on 9/23/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCGuesserViewController.h"
#import "TVCPlayer.h"

@interface TVCGuesserViewController ()
{
    TVCPickerView * pickerView;
    int guessedPlayer;
}
@end

@implementation TVCGuesserViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

/*
 // Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
 */
- (void)viewDidLoad {
	[super viewDidLoad];
    //testing
   /* self.responses = [NSMutableArray arrayWithArray: @[@"Jeff's Asshole", @"Bears", @"Niggers"]];
    TVCPlayer *p1 = [[TVCPlayer alloc] initWithName:@"name1" andNumber:0];
    TVCPlayer *p2 = [[TVCPlayer alloc] initWithName:@"name2" andNumber:1];
    TVCPlayer *p3 = [[TVCPlayer alloc] initWithName:@"name3" andNumber:2];
    TVCPlayer *p4 = [[TVCPlayer alloc] initWithName:@"name4" andNumber:3];
    TVCPlayer *p5 = [[TVCPlayer alloc] initWithName:@"name5" andNumber:5];
    TVCPlayer *p6 = [[TVCPlayer alloc] initWithName:@"name6" andNumber:6];
    TVCPlayer *p7 = [[TVCPlayer alloc] initWithName:@"name7" andNumber:7];
    TVCPlayer *p8 = [[TVCPlayer alloc] initWithName:@"name8" andNumber:8];
    
    self.players = [NSMutableArray arrayWithArray: @[p1,p2,p3,p4,p5,p6,p7,p8]];
	*/
    // a page is the width of the scroll view
    
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self. scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    
	
    
	
    // pages are created on demand
    // load the visible page
    // load the page on either side to avoid flashes when the user starts scrolling
    [self loadScrollView];
    self.pageControl.currentPage = 0;
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [[appDelegate dataSource] setCurrentViewController:self];
}

- (void)loadScrollView {
    for (UIView *subview in self.scrollView.subviews) {
        [subview removeFromSuperview];
    }
    
	self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [self.responses count], self.scrollView.frame.size.height);
    
    self.pageControl.numberOfPages = [self.responses count];

    
    for (NSString *str in self.responses) {
        CGRect frame = self.scrollView.frame;
        frame.origin.x = frame.size.width * [self.responses indexOfObject:str];
        frame.origin.y = 0;
        UILabel * curResponse = [[UILabel alloc] initWithFrame:frame];
        [curResponse setText:str];
        [curResponse setTextAlignment:NSTextAlignmentCenter];
        
        [self.scrollView addSubview:curResponse];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    // We don't want a "feedback loop" between the UIPageControl and the scroll delegate in
    // which a scroll event generated from the user hitting the page control triggers updates from
    // the delegate method. We use a boolean to disable the delegate logic when the page control is used.
    if (pageControlUsed) {
        // do nothing - the scroll was initiated from the page control, not the user dragging
        return;
    }
	
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
	
    NSLog(@"GuesserView current page: %i", page);
    // A possible optimization would be to unload the views+controllers which are no longer visible
}

// At the begin of scroll dragging, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    pageControlUsed = NO;
}

// At the end of scroll animation, reset the boolean used when scrolls originate from the UIPageControl
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    pageControlUsed = NO;
}

- (IBAction)changePage:(id)sender {
    int page = self.pageControl.currentPage;
    
	// update the scroll view to the appropriate page
    CGRect frame = self.scrollView.frame;
    frame.origin.x = frame.size.width * page;
    frame.origin.y = 0;
    [self.scrollView scrollRectToVisible:frame animated:YES];
    
	// Set the boolean used when scrolls originate from the UIPageControl. See scrollViewDidScroll: above.
    pageControlUsed = YES;
}

/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (IBAction)guessAction:(id)sender {
     //CGRect frame = CGRectMake(0, [[UIScreen mainScreen] bounds].size.height, self.scrollView.frame.size.width, [[UIScreen mainScreen] bounds].size.height - self.pageControl.frame.origin.y);
    [self.scrollView setScrollEnabled:NO];
    CGRect frame = CGRectMake(0,  [[UIScreen mainScreen] bounds].size.height, self.scrollView.frame.size.width, [[UIScreen mainScreen] bounds].size.height - self.pageControl.frame.origin.y);
    
    
    UIImage * img = [UIImage imageNamed:@"guesserIcon.png"];
    NSMutableArray * hold = [NSMutableArray arrayWithObject:img];
    [hold insertObject:img atIndex:0];
        [hold insertObject:img atIndex:0];
        [hold insertObject:img atIndex:0];
        [hold insertObject:img atIndex:0];
        [hold insertObject:img atIndex:0];
    double off =  [[UIScreen mainScreen] bounds].size.height - self.pageControl.frame.origin.y;
    NSArray *imgs = [NSArray arrayWithObject:img];
   
    
    if (pickerView) {
        [pickerView removeFromSuperview];
    }
    pickerView = [[TVCPickerView alloc] initWithFrame:frame Players:self.players Pictures:imgs andOffset:off];
    pickerView.delegate = self;
    [self.view addSubview:pickerView];
    [pickerView displayPicker:YES];
    
    /*
     [self.scrollView setScrollEnabled:NO];
    int countx = 0;
    int maxX = 1;
    int county = 0;
    //CGRect frame = CGRectMake(0, self.pageControl.frame.origin.y, self.scrollView.frame.size.width, 120);
    CGRect frame = CGRectMake(0, [[UIScreen mainScreen] bounds].size.height, self.scrollView.frame.size.width, [[UIScreen mainScreen] bounds].size.height - self.pageControl.frame.origin.y);
    UIScrollView * guessScrollView = [[UIScrollView alloc] initWithFrame:frame];
    guessScrollView.contentSize = CGSizeMake(guessScrollView.frame.size.width * ceil([self.players count] / 4.0 ), guessScrollView.frame.size.height);
    
    for (NSString *str in self.players) {
        frame = CGRectMake(0, 0, guessScrollView.frame.size.width / 2, guessScrollView.frame.size.height / 2);
        frame.origin.x = (frame.size.width) * countx;
        frame.origin.y = (frame.size.height) * county;
        
        countx++;
        NSLog(@"count x: %d", countx);
        if (countx > maxX) {
            county++;
            countx = maxX - 1;
        }
        if (county > 1) {
            county = 0;
            maxX += 2;
            countx = maxX - 1;
        }
        
        //UIButton * name = [[UIButton alloc] initWithFrame:frame];
        //[name setTitle:str forState:UIControlStateNormal];
        UIButton * name = [UIButton buttonWithType:UIButtonTypeSystem];
        int buffer = 5;
        [name setFrame:CGRectMake(frame.origin.x + buffer, frame.origin.y + buffer, frame.size.width - buffer, frame.size.height-buffer)];
        [name setTitle:str forState:UIControlStateNormal];
       // [name setTextAlignment:NSTextAlignmentCenter];
        //[name setText:str];
        [guessScrollView addSubview:name];
    }
    [guessScrollView setBackgroundColor:[UIColor whiteColor]];
    [guessScrollView setPagingEnabled:YES];
    [guessScrollView setScrollEnabled:YES];
    //guessScrollView.delegate = self;
    [self.view addSubview:guessScrollView];
    
    [UIView beginAnimations:@"animateTableView" context:nil];
    [UIView setAnimationDuration:0.6];
    [guessScrollView setFrame:CGRectMake( 0, self.pageControl.frame.origin.y, guessScrollView.frame.size.width, guessScrollView.frame.size.height)]; //notice this is ON screen!
    [UIView commitAnimations];
    */
    /*const int movementDistance = 80; // tweak as needed
    const float movementDuration = 0.3f; // tweak as needed
    
    int movement = (self.guessButton ? -movementDistance : movementDistance);
    
    [UIView beginAnimations: @"anim" context: nil];
    [UIView setAnimationBeginsFromCurrentState: YES];
    [UIView setAnimationDuration: movementDuration];
    guessScrollView.frame = CGRectOffset(self.view.frame, 0, movement);
    [UIView commitAnimations];*/
}

#pragma mark TVCPickerViewDelegate methods

- (void) didSelectPlayer:(int)player {
    NSLog(@"responseDict: %@", self.responseDictionary);
    
  //  NSNumber* responseID = (NSNumber*)[self.responseDictionary objectForKey:[self.responses objectAtIndex:self.pageControl.currentPage]];
    NSNumber* responseID;
    for(id key in self.responseDictionary) {
        if ([[self.responseDictionary objectForKey:key] isEqualToString:[self.responses objectAtIndex:self.pageControl.currentPage]]) {
            responseID = key;
            break;
        }
    }
    
    NSInteger holdInt = responseID.integerValue;
    guessedPlayer = player;
    TVCPlayer * playerToReturn = [self.players objectAtIndex:player];
    int playerID = playerToReturn.playerNumber;
    
    NSLog(@"player index: %i with ID: %i and response %@ with responseID %i", player,playerID,[self.responses objectAtIndex:self.pageControl.currentPage], responseID.integerValue);
    
    [[[appDelegate dataSource] getMessageStream] sendGuessWithPlayer:&playerID  andResponseId:&holdInt];
    
}

- (void) didPressCloseButton {
    [self.scrollView setScrollEnabled:YES];
    [pickerView displayPicker:NO];
}

-(void) didMakeCorrectGuess {
    [self.responseDictionary removeObjectForKey:[self.responses objectAtIndex:self.pageControl.currentPage]];
    [self.responses removeObjectAtIndex:self.pageControl.currentPage];
    
    if (self.pageControl.currentPage >= [self.responses count]) {
        self.pageControl.currentPage = [self.responses count] -1;
    }
    
    [self.players removeObjectAtIndex:guessedPlayer];
    
    guessedPlayer = -1;
    
    [self loadScrollView];
    
    
    [self.scrollView setScrollEnabled:YES];
}

@end
