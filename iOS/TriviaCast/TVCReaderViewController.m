//
//  TVCReaderViewController.m
//  TriviaCast
//
//  Created by John Brophy on 9/22/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCReaderViewController.h"
#import "TVCAppDelegate.h"
#import "TVCDataSource.h"

@interface TVCReaderViewController ()
{
    BOOL finishedReading;
}
@end

@implementation TVCReaderViewController

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
    finishedReading = NO;
	
    // a page is the width of the scroll view
    self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * [self.responses count], self.scrollView.frame.size.height);
    self.scrollView.showsHorizontalScrollIndicator = NO;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self. scrollView.scrollsToTop = NO;
    self.scrollView.delegate = self;
    
	
    self.pageControl.numberOfPages = [self.responses count];
    self.pageControl.currentPage = 0;
	
    // pages are created on demand
    // load the visible page
    // load the page on either side to avoid flashes when the user starts scrolling
    [self loadScrollView];
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    [[appDelegate dataSource] setCurrentViewController:self];
}

- (void)loadScrollView {
	
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
	
    if(!finishedReading && page == [self.responses count]) {
        [[[appDelegate dataSource] getMessageStream] sendReaderIsDone];
    }
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


@end
