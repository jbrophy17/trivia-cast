//
//  TVCPickerView.m
//  TriviaCast
//
//  Created by John Brophy on 9/24/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import "TVCPickerView.h"
#import "TVCPlayer.h"

@implementation TVCPickerView {
    float buttonWidth;
}

- (id)initWithFrame:(CGRect)frame Players:(NSArray *)players Pictures:(NSArray *)pictures andOffset:(double)offset
{
    self = [super initWithFrame:frame];
    if (self) {
         buttonWidth = 44;
        self.players = players;
        self.offset = offset + buttonWidth;
        self.pictures = pictures;
       
        
        self.closeButton = [[UIButton alloc] initWithFrame:CGRectMake(frame.size.width - buttonWidth, 0, buttonWidth, buttonWidth)];
        
        [self.closeButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchDown];
        [self.closeButton setBackgroundColor:[UIColor colorWithRed:.5 green:0 blue:0 alpha:1]];
        [self.closeButton setTitle:@"x" forState:UIControlStateNormal];
        
        
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, buttonWidth, frame.size.width, frame.size.height)];
        [self.scrollView setScrollEnabled:NO];
        int countx = 0;
        int maxX = 1;
        int county = 0;
        //CGRect frame = CGRectMake(0, self.pageControl.frame.origin.y, self.scrollView.frame.size.width, 120);
        //CGRect frame = CGRectMake(0, [[UIScreen mainScreen] bounds].size.height, self.scrollView.frame.size.width, [[UIScreen mainScreen] bounds].size.height - self.pageControl.frame.origin.y);
        //UIScrollView * guessScrollView = [[UIScrollView alloc] initWithFrame:frame];
        self.scrollView.contentSize = CGSizeMake(self.scrollView.frame.size.width * ceil([self.players count] / 4.0 ), self.scrollView.frame.size.height);
        
        for (TVCPlayer *player in self.players) {
            frame = CGRectMake(0, 0, self.scrollView.frame.size.width / 2, self.scrollView.frame.size.height / 2);
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
            
            
            //CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
            
            
            UIButton * name = [UIButton buttonWithType:UIButtonTypeSystem];
            //[name setBackgroundColor:[UIColor redColor]];
            int bufferY = 5;
            int bufferX = 5;
            [name setFrame:CGRectMake(frame.origin.x + bufferX, frame.origin.y + bufferY, frame.size.width - bufferX, frame.size.height-bufferY)];
            
            
            
            double imageDimensions = name.frame.size.height * .6;
            //CGRect imageFrame = CGRectMake(name.frame.size.width - (imageDimensions / 2.0), 0, imageDimensions, imageDimensions);
            CGRect imageFrame = CGRectMake((name.frame.size.width / 2.0 )- (imageDimensions / 2.0), 0, imageDimensions, imageDimensions);
            UIImageView *imgView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imageFrame.size.width, imageFrame.size.height)];
            //[imgView setImage:[self.pictures objectAtIndex:[self.players indexOfObject:str]]];
            [imgView setImage:[UIImage imageNamed:@"defaultProfile.jpg"]];
            
            
            CGRect imageRect = CGRectMake(0, 0, imageFrame.size.width, imageFrame.size.height);
            
            UIGraphicsBeginImageContextWithOptions(imageFrame.size, NO, 0.0);
            // Create the clipping path and add it
            UIBezierPath *path = [UIBezierPath bezierPathWithOvalInRect:imageRect];
            [path addClip];
            
            
            [[UIImage imageNamed:@"defaultProfile.jpg"] drawInRect:imageRect];
            UIImage *roundedImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            imgView.image = roundedImage;
            [imgView setFrame:imageFrame];
            
            
            
            /* CGPathRef maskPath = CGPathCreateWithEllipseInRect(imageFrame, NULL);
            maskLayer.bounds = frame;
            [maskLayer setPath:maskPath];
            [maskLayer setFillColor:[[UIColor blackColor] CGColor]];
            maskLayer.position = CGPointMake(frame.size.width/2, frame.size.height/2);
           
            [imgView.layer setMask:maskLayer];
            */
            //UIButton * name = [[UIButton alloc] initWithFrame:frame];
            //[name setTitle:str forState:UIControlStateNormal];
            
            [name setTitle:player.name forState:UIControlStateNormal];
            [name addSubview:imgView];
            // [name setTextAlignment:NSTextAlignmentCenter];
            //[name setText:str];
            
            //CGRect labelRect = name.titleLabel.frame;
            //double labelOffset = imageFrame.size.height + ( (name.frame.size.height - imageFrame.size.height) / 2.0);
            double labelOffset = imageFrame.size.height;
            //[name.titleLabel setFrame:CGRectMake(labelRect.origin.x, 100, labelRect.size.width, labelRect.size.height)];
            [name setTitleEdgeInsets:UIEdgeInsetsMake(labelOffset, 0, 0, 0)];
            [name addTarget:self action:@selector(playerSelected:) forControlEvents:UIControlEventTouchUpInside];
            [self.scrollView addSubview:name];
        }
        
        
        
        [self.scrollView setBackgroundColor:[UIColor whiteColor]];
        [self.scrollView setPagingEnabled:YES];
        [self.scrollView setScrollEnabled:YES];
        [self.scrollView setShowsHorizontalScrollIndicator:NO];
        [self.scrollView setShowsVerticalScrollIndicator:NO];
        
        self.scrollView.delegate = self;
        CGRect PCFrame = CGRectMake(self.frame.size.width / 2.0 - 25 , self.frame.size.height - 20 + buttonWidth, 50, 10);
        self.pageControl = [[UIPageControl alloc] initWithFrame:PCFrame];
        self.pageControl.numberOfPages = ceil([self.players count] / 4.0 );
        self.pageControl.currentPage = 0;
        
        [self.pageControl setPageIndicatorTintColor:[UIColor colorWithRed:102.0/255.0 green:204.0/255.0 blue:255.0/255.0 alpha:.8]];
        [self.pageControl setCurrentPageIndicatorTintColor:[UIColor colorWithRed:0.0/255.0 green:128.0/255.0 blue:255.0/255.0 alpha:1]];
        
        //[self.pageControl setPageIndicatorTintColor:[UIColor blueColor]];
        //[self.pageControl setCurrentPageIndicatorTintColor:[UIColor redColor]];
        [self addSubview:self.scrollView];
        [self addSubview:self.pageControl];
        [self addSubview:self.closeButton];
        
    }
    return self;
}

- (void)scrollViewDidScroll:(UIScrollView *)sender {
	
    // Switch the indicator when more than 50% of the previous/next page is visible
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = floor((self.scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    self.pageControl.currentPage = page;
	
    // A possible optimization would be to unload the views+controllers which are no longer visible
}

- (void) displayPicker:(BOOL)show {
    
    [UIView beginAnimations:@"animateTableView" context:nil];
    [UIView setAnimationDuration:0.6];
    if (show) {
        NSLog(@"Frame y: %f, Bounds y: %f", self.frame.origin.y, self.bounds.origin.y);
        [self setFrame:CGRectMake( 0, self.frame.origin.y - self.offset, self.frame.size.width, self.frame.size.height)];
        NSLog(@"Frame y: %f, Bounds y: %f", self.frame.origin.y, self.bounds.origin.y);
    } else {
        [self setFrame:CGRectMake( 0, self.frame.origin.y + self.offset, self.frame.size.width, self.frame.size.height)];
    }
    [UIView commitAnimations];
    
}

- (IBAction)playerSelected:(id)sender{
    UIButton * button = (UIButton*)sender;
    
    int x = floor(button.frame.origin.x / (self.frame.size.width / 2.0));
    int y = floor(button.frame.origin.y / (self.frame.size.height / 2.0));
    
    _selectedPlayer = self.pageControl.currentPage * 2 + x;
    if (y > 0) {
        _selectedPlayer += 2;
    }
    
  /*  if (button.frame.origin.x < self.frame.size.width / 2.0) {
        if (button.frame.origin.y < self.frame.size.height / 2.0) {
            _selectedPlayer = 4 * self.pageControl.currentPage;
        } else {
            _selectedPlayer = 4 * self.pageControl.currentPage + 2;
        }
    } else {
        if (button.frame.origin.y < self.frame.size.height / 2.0) {
            _selectedPlayer = 4 * self.pageControl.currentPage + 1;
        } else {
            _selectedPlayer = 4 * self.pageControl.currentPage + 3;
        }
    }*/
    NSLog(@"Player: %d", self.selectedPlayer);
    [self displayPicker:NO];
    [self.delegate didSelectPlayer:self.selectedPlayer];
}
-(IBAction) closeButtonPressed:(id)sender {
    [self.delegate didPressCloseButton];
}

@end
