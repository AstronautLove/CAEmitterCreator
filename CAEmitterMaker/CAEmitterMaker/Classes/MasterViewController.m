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
@property (nonatomic, strong) CAEmitterLayer *emitterLayer;
@property (nonatomic, strong) CAEmitterCell *emitterCell;

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

- (void) awakeFromNib
{
    [self.settingsView.documentView setFrame:NSMakeRect(0, 0, 250, SCROLL_VIEW_HEIGHT)];
    [self.settingsView.documentView scrollPoint:NSMakePoint(0, SCROLL_VIEW_HEIGHT)];
    [self.settingsView setHasHorizontalScroller:NO];
    
    [self createUIElements];
    
    // Create the emitter layer and set our emitter view to use it
    self.emitterCell = [CAEmitterCell emitterCell];
    [self setEmitterCellImage:@"spark.png"];
    self.emitterCell.velocity = 100;
    self.emitterCell.velocityRange = 50;
    self.emitterCell.birthRate = 10;
    self.emitterCell.lifetime = 2.0f;
    self.emitterCell.lifetimeRange = 0.0f;
    self.emitterCell.color = [[NSColor colorWithDeviceRed:1.0 green:0.0 blue:0.0 alpha:1.0] CGColor];
    self.emitterCell.emissionLatitude = 0.0f;
    self.emitterCell.emissionRange = M_PI_2;
    self.emitterCell.name = @"spark";
    
    CALayer *rootLayer = [CALayer layer];
    rootLayer.bounds = [self.view bounds];
    rootLayer.frame = rootLayer.bounds;
    rootLayer.backgroundColor = CGColorGetConstantColor(kCGColorBlack);
    
    self.emitterLayer = [[CAEmitterLayer alloc] init];
    self.emitterLayer.frame = rootLayer.bounds;
    self.emitterLayer.emitterPosition = CGPointMake(self.emitterView.bounds.size.width / 2,
                                                    self.emitterView.bounds.size.height / 2);
    NSLog(@"%@", NSStringFromPoint(self.emitterLayer.emitterPosition));
    self.emitterLayer.emitterSize = CGSizeMake(32, 32);
    self.emitterLayer.emitterCells = @[self.emitterCell];
    
    [rootLayer addSublayer:self.emitterLayer];
    [self.emitterView setLayer:rootLayer];
    [self.emitterView setWantsLayer:YES];
    [self.view setNeedsDisplay:YES];
}

- (void) createUIElements
{
    int index = 0;
    
    NSTextField *lifetimeText = [MasterViewController labelForIndex:index withText:@"Lifetime"];
    [self.settingsView.documentView addSubview:lifetimeText];
    
    self.lifetimeSlider = [MasterViewController sliderForIndex:0 minValue:0 maxValue:10 target:self];
    [self.settingsView.documentView addSubview:self.lifetimeSlider];
}

- (void) sliderValueChanged:(id) sender
{
    NSSlider *slider = (NSSlider *)sender;
    [self.emitterCell setValue:@(slider.floatValue) forKey:@"lifetime"];
    self.emitterLayer.emitterCells = @[];
    self.emitterLayer.emitterCells = @[self.emitterCell];
    NSLog(@"lifetime value: %f", self.emitterCell.lifetime);
}

- (void) setEmitterCellImage:(NSString *) imageName
{
    CFURLRef url = (__bridge CFURLRef) [[NSBundle mainBundle] URLForResource:imageName withExtension:nil];
    CGImageSourceRef source = CGImageSourceCreateWithURL(url, NULL);
    CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
    CFRelease(source);
    [self.emitterCell setContents:(id)CFBridgingRelease(image)];
}

+ (NSTextField *) labelForIndex:(int)index withText:(NSString *)text
{
    NSRect labelFrame = [self textViewRectForIndex:index];
    NSTextField *label = [[NSTextField alloc] initWithFrame:labelFrame];
    [label setBackgroundColor:[NSColor clearColor]];
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setAlignment:NSCenterTextAlignment];
    [label setFont:[NSFont fontWithName:[[label font] fontName] size:20]];
    [label setStringValue:text];
    return label;
}

+ (NSSlider *) sliderForIndex:(int)index
                     minValue:(double)minValue
                     maxValue:(double)maxValue
                       target:(id) target
{
    NSRect sliderFrame = [self sliderRectForIndex:index];
    NSSlider *slider = [[NSSlider alloc] initWithFrame:sliderFrame];
    [slider setMinValue:minValue];
    [slider setMaxValue:maxValue];
    [slider setContinuous:YES];
    [slider setTarget:target];
    [slider setAction:@selector(sliderValueChanged:)];
    
    return slider;
}

+ (NSRect) textViewRectForIndex:(int) index
{
    int yPos = SCROLL_VIEW_HEIGHT - UI_ELEMENT_START_Y - ((( 2 * ELEMENT_HEIGHT ) + BUFFER_Y) * index);
    return NSMakeRect(ELEMENT_START_X, yPos, ELEMENT_WIDTH, ELEMENT_HEIGHT);
}

+ (NSRect) sliderRectForIndex:(int) index
{
    int yPos = SCROLL_VIEW_HEIGHT - UI_ELEMENT_START_Y - ((( 2 * ELEMENT_HEIGHT ) + BUFFER_Y) * index) - ELEMENT_HEIGHT;
    return NSMakeRect(ELEMENT_START_X, yPos, ELEMENT_WIDTH, ELEMENT_HEIGHT);
}

@end
