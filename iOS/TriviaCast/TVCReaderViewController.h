//
//  TVCReaderViewController.h
//  TriviaCast
//
//  Created by John Brophy on 9/22/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TVCReaderViewController : UIViewController <UIScrollViewDelegate> {
    BOOL pageControlUsed;
}
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;

@property (nonatomic, strong) NSMutableArray * responses;

@end
