//
//  MasterViewController.m
//  CAEmitterMaker
//
//  Created by Nick Brice on 1/8/13.
//  Copyright (c) 2013 Nick Brice. All rights reserved.
//

#import "MasterViewController.h"
#import <QuartzCore/QuartzCore.h>

#define UI_ELEMENT_START_Y  79
#define SLIDER_SIZE         NSMakeSize(212,21)
#define TEXTFIELD_SIZE      NSMakeSize(212,21)
#define ELEMENT_START_X     18
#define ELEMENT_WIDTH       212
#define ELEMENT_HEIGHT      21
#define BUFFER_Y            15

#define TOTAL_UI_ELEMENTS   24

#define SCROLL_VIEW_HEIGHT  ((ELEMENT_HEIGHT * 2) + BUFFER_Y) * TOTAL_UI_ELEMENTS

@interface MasterViewController ()

@property (nonatomic, strong) IBOutlet NSView *emitterView;
@property (nonatomic, strong) IBOutlet NSScrollView *settingsView;

@property (nonatomic, strong) NSSlider *lifetimeSlider;
@property (nonatomic, strong) NSSlider *lifetimeRangeSlider;
@property (nonatomic, strong) NSSlider *birthRateSlider;
@property (nonatomic, strong) NSSlider *scaleSpeedSlider;
@property (nonatomic, strong) NSSlider *velocitySlider;
@property (nonatomic, strong) NSSlider *velocityRangeSlider;
@property (nonatomic, strong) NSSlider *xAccelSlider;
@property (nonatomic, strong) NSSlider *yAccelSlider;
@property (nonatomic, strong) NSSlider *zAccelSlider;

@property (nonatomic, strong) NSSlider *redRangeSlider;
@property (nonatomic, strong) NSSlider *redSpeedSlider;
@property (nonatomic, strong) NSSlider *greenRangeSlider;
@property (nonatomic, strong) NSSlider *greenSpeedSlider;
@property (nonatomic, strong) NSSlider *blueRangeSlider;
@property (nonatomic, strong) NSSlider *blueSpeedSlider;
@property (nonatomic, strong) NSSlider *alphaRangeSlider;
@property (nonatomic, strong) NSSlider *alphaSpeedSlider;

@property (nonatomic, strong) NSSlider *scaleSlider;
@property (nonatomic, strong) NSSlider *scaleRangeSlider;

@property (nonatomic, strong) NSSlider *spinSlider;
@property (nonatomic, strong) NSSlider *spinRangeSlider;

@property (nonatomic, strong) NSSlider *emissionLattitudeSlider;
@property (nonatomic, strong) NSSlider *emissionLongitudeSlider;
@property (nonatomic, strong) NSSlider *emissionRange;

@end

@implementation MasterViewController

- (void) createUIElements
{
    int uiIndex = 0;
    
    NSTextField *label = [self labelForIndex:uiIndex];

}

- (NSTextField *) labelForIndex:(int) index
{
    NSRect labelFrame = [self textViewRectForIndex:index];
    NSTextField *label = [[NSTextField alloc] initWithFrame:labelFrame];
    [label setBackgroundColor:[NSColor clearColor]];
    [label setEditable:NO];
    return label;
}

- (NSRect) textViewRectForIndex:(int) index
{
    int yPos = SCROLL_VIEW_HEIGHT - ((( 2 * ELEMENT_HEIGHT ) + BUFFER_Y) * index);
    return NSMakeRect(ELEMENT_START_X, yPos, ELEMENT_WIDTH, ELEMENT_HEIGHT);
}

- (NSRect) sliderRectForIndex:(int) index
{
    int yPos = SCROLL_VIEW_HEIGHT - ((( 2 * ELEMENT_HEIGHT ) + BUFFER_Y) * index) - ELEMENT_HEIGHT;
    return NSMakeRect(ELEMENT_START_X, yPos, ELEMENT_WIDTH, ELEMENT_HEIGHT);
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    if( self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil] )
    {
        
    }
    
    return self;
}

- (void) loadView
{
    [super loadView];
    
    [self.settingsView.documentView setFrame:NSMakeRect(0, 0, 250, SCROLL_VIEW_HEIGHT)];
    [self.settingsView.documentView scrollPoint:NSMakePoint(0, SCROLL_VIEW_HEIGHT)];
    [self.settingsView setHasHorizontalScroller:NO];
    
    // Create the emitter layer and set our emitter view to use it
    CAEmitterLayer *emitterLayer = [[CAEmitterLayer alloc] init];
    self.emitterView.layer = emitterLayer;
}

@end
