//
//  TVCPickerView.h
//  TriviaCast
//
//  Created by John Brophy on 9/24/13.
//  Copyright (c) 2013 smokeHau5. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TVCPickerViewDelegate

- (void) didSelectPlayer:(int) player;

@end


@interface TVCPickerView : UIView <UIScrollViewDelegate>
@property (nonatomic, strong) UIScrollView * scrollView;
@property (nonatomic, strong) UIPageControl * pageControl;
@property (nonatomic, strong) NSArray * players;
@property (nonatomic, strong) NSArray * pictures;
@property (nonatomic) double offset;
@property(nonatomic, strong, readwrite) id<TVCPickerViewDelegate> delegate;
@property (nonatomic, readonly) int selectedPlayer;

- (id) initWithFrame:(CGRect)frame Players:(NSArray*)players Pictures:(NSArray*)pictures andOffset:(double)offset;
- (void) displayPicker: (BOOL) show;

-(IBAction)playerSelected:(id)sender;

@end
