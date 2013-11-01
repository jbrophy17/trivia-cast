//
//  TVCGuesserViewController.h
//  TriviaCast
//
//  Created by John Brophy on 9/23/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TVCPickerView.h"
#import "TVCAppDelegate.h"
#import "TVCDataSource.h"

@interface TVCGuesserViewController : UIViewController <UIScrollViewDelegate, TVCPickerViewDelegate> {
    BOOL pageControlUsed;
}

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIButton *guessButton;

@property (nonatomic, strong) NSMutableArray * responses;
@property (nonatomic, strong) NSMutableArray * players;

@property (nonatomic, strong) NSMutableDictionary * responseDictionary;

- (IBAction)guessAction:(id)sender;
-(void) didMakeCorrectGuess;
@end
