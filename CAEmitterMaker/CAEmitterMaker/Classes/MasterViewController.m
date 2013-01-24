//
//  MasterViewController.m
//  CAEmitterMaker
//
//  Created by Nick Brice on 1/8/13.
//  Copyright (c) 2013 Nick Brice. All rights reserved.
//

#import "MasterViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "NSControl+EmitterProperty.h"

#define UI_ELEMENT_START_Y  150
#define SLIDER_SIZE         NSMakeSize(212,21)
#define TEXTFIELD_SIZE      NSMakeSize(212,21)
#define ELEMENT_START_X     18
#define ELEMENT_WIDTH       300
#define ELEMENT_HEIGHT      21
#define BUFFER_Y            15

@interface MasterViewController ()

@property (nonatomic, strong) IBOutlet NSView *emitterView;
@property (nonatomic, strong) IBOutlet NSScrollView *settingsView;
@property (nonatomic, strong) IBOutlet NSTextField *durationField;
@property (nonatomic, strong) IBOutlet NSTextField *repititionField;
@property NSInteger repititionCount;
@property (nonatomic, strong) IBOutlet NSPopUpButton *renderModeSelector;

@property (nonatomic, strong) NSImageView *backgroundImage;

@property (nonatomic, strong) CAEmitterLayer *emitterLayer;
@property (nonatomic, strong) CAEmitterCell *emitterCell;

@property (nonatomic, strong) NSArray *allUIElements;

@end

@implementation MasterViewController

- (void)awakeFromNib
{
    self.repititionCount = 0;
    
    self.allUIElements = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"UIElements" ofType:@"plist"]];
    
    [self createUIElements];
    
    // Create the emitter layer and set our emitter view to use it
    self.emitterCell = [CAEmitterCell emitterCell];
    self.emitterCell.velocity = 100;
    self.emitterCell.velocityRange = 50;
    self.emitterCell.birthRate = 10;
    self.emitterCell.lifetime = 2.0f;
    self.emitterCell.lifetimeRange = 0.0f;
    self.emitterCell.emissionLatitude = 0.0f;
    self.emitterCell.emissionRange = M_PI_2;
    self.emitterCell.duration = 5.0f;
    self.emitterLayer.emitterCells = [NSMutableArray arrayWithObject:self.emitterCell];
    self.emitterLayer.lifetime = 0.0f;
    self.emitterLayer.renderMode = [MasterViewController renderModeForIndex:[self.renderModeSelector indexOfSelectedItem]];
    
    CALayer *rootLayer = [CALayer layer];
    rootLayer.bounds = [self.view bounds];
    rootLayer.frame = rootLayer.bounds;
    
    self.emitterLayer = [[CAEmitterLayer alloc] init];
    self.emitterLayer.frame = rootLayer.bounds;
    self.emitterLayer.emitterPosition = CGPointMake(self.emitterView.bounds.size.width / 2,
                                                    self.emitterView.bounds.size.height / 2);
    NSLog(@"%@", NSStringFromPoint(self.emitterLayer.emitterPosition));
    self.emitterLayer.emitterSize = CGSizeMake(32, 32);
    
    [rootLayer addSublayer:self.emitterLayer];
    [self.emitterView setLayer:rootLayer];
    [self.emitterView setWantsLayer:YES];
    [self.view setNeedsDisplay:YES];
}

- (void)createUIElements
{
    [self.renderModeSelector removeAllItems];
    [self.renderModeSelector addItemsWithTitles:@[@"unordered", @"oldest first", @"oldest last", @"back to front", @"additive"]];
    [self.renderModeSelector selectItemAtIndex:4];
    
    NSInteger scrollViewHeight = ((ELEMENT_HEIGHT * 2) + BUFFER_Y) * self.allUIElements.count;
    [self.settingsView.documentView setFrame:NSMakeRect(0, 0, 500, [self scrollViewHeight])];
    [self.settingsView.documentView scrollPoint:NSMakePoint(0, [self scrollViewHeight])];
    [self.settingsView setHasHorizontalScroller:NO];
    
    self.durationField.stringValue = @"0.0";
    
    for ( int index = 0; index < self.allUIElements.count; ++index )
    {
        NSDictionary *elementDetails = self.allUIElements[index];
        NSTextField *textField = [self labelForIndex:index];
        
        NSControl *control = nil;
        if ( [elementDetails[@"type"] isEqualToString:@"slider"] )
        {
            control = [self sliderForIndex:index
                                  minValue:[elementDetails[@"min"] doubleValue]
                                  maxValue:[elementDetails[@"max"] doubleValue]
                                    target:self
                                  property:elementDetails[@"emitterProperty"]
                                     label:textField];
            control.tag = index;
            textField.stringValue = [NSString stringWithFormat:@"%@: %.3f", elementDetails[@"labelString"], control.floatValue];
        }
        
        [self.settingsView.documentView addSubview:textField];
        [self.settingsView.documentView addSubview:control];
    }
}

- (void)sliderValueChanged:(id)sender
{
    NSSlider *slider = (NSSlider *)sender;
    [self.emitterCell setValue:@(slider.floatValue) forKey:slider.emitterPropertyToModify];
    self.emitterLayer.emitterCells = @[self.emitterCell];
    NSString *labelText = (self.allUIElements[slider.tag])[@"labelString"];
    slider.label.stringValue = [NSString stringWithFormat:@"%@: %.3f", labelText, slider.floatValue];
}

- (void)setEmitterCellImage:(NSURL *)imageURL
{
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)imageURL, NULL);
    CGImageRef image = CGImageSourceCreateImageAtIndex(source, 0, NULL);
    CFRelease(source);
    [self.emitterCell setContents:(id)CFBridgingRelease(image)];
}

- (IBAction)showButtonGotEvent:(id)sender
{
    [self stopEmitting:YES];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    self.repititionCount = [self.repititionField.stringValue integerValue];
    NSLog(@"%li", self.repititionCount);
    self.emitterLayer.birthRate = 1.0f;
    [self startEmitting];
}

- (IBAction)changeBackgroundImageButtonGotEvent:(id)sender
{
    NSOpenPanel* openDialog = [NSOpenPanel openPanel];
    
    [openDialog setCanChooseFiles:YES];
    [openDialog setAllowsMultipleSelection:NO];
    [openDialog setCanChooseDirectories:NO];
    
    if ( [openDialog runModal] == NSOKButton )
    {
        NSURL *fileURL = [openDialog URLs][0];
        NSImage *image = [[NSImage alloc] initWithContentsOfURL:fileURL];
        self.backgroundImage.image = image;
    }
}

- (IBAction)renderModeSelectorGotEvent:(id)sender
{
    self.emitterLayer.renderMode = [MasterViewController renderModeForIndex:[self.renderModeSelector indexOfSelectedItem]];
}

- (IBAction)changeEmitterImage:(id)sender
{
    NSOpenPanel* openDialog = [NSOpenPanel openPanel];
    
    [openDialog setCanChooseFiles:YES];
    [openDialog setAllowsMultipleSelection:NO];
    [openDialog setCanChooseDirectories:NO];
    
    if ( [openDialog runModal] == NSOKButton )
    {
        NSURL *fileURL = [openDialog URLs][0];
        [self setEmitterCellImage:fileURL];
    }
}

- (void)startEmitting
{
    self.emitterLayer.emitterCells = @[];
    self.emitterLayer.emitterCells = @[self.emitterCell];
    float duration = fabsf([[self.durationField stringValue] floatValue]);
    [self performSelector:@selector(stopEmitting) withObject:nil afterDelay:duration];
}

- (void)repeat
{
    self.emitterLayer.birthRate = 1.0f;
    [self startEmitting];
}

- (void)stopEmitting
{
    [self stopEmitting:YES];
}

- (void)stopEmitting:(BOOL)repeat
{
    --self.repititionCount;
    
    self.emitterLayer.birthRate = 0.0f;
    if ( self.repititionCount > 0 && repeat )
    {
        [self performSelector:@selector(repeat) withObject:nil afterDelay:self.emitterCell.lifetime + self.emitterCell.lifetimeRange + 0.5];
    }
}

+ (NSString * const) renderModeForIndex:(NSUInteger)index
{
    switch (index) {
        case 0:
            return kCAEmitterLayerUnordered;
        case 1:
            return kCAEmitterLayerOldestFirst;
        case 2:
            return kCAEmitterLayerOldestLast;
        case 3:
            return kCAEmitterLayerBackToFront;
        case 4:
            return kCAEmitterLayerAdditive;
        default:
            return kCAEmitterLayerAdditive;
    }
}

- (NSTextField *)labelForIndex:(int)index
{
    NSRect labelFrame = [self textViewRectForIndex:index];
    NSTextField *label = [[NSTextField alloc] initWithFrame:labelFrame];
    [label setBackgroundColor:[NSColor clearColor]];
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setAlignment:NSLeftTextAlignment];
    [label setFont:[NSFont fontWithName:[[label font] fontName] size:20]];
    return label;
}

- (NSSlider *)sliderForIndex:(int)index
                    minValue:(double)minValue
                    maxValue:(double)maxValue
                      target:(id) target
                    property:(NSString*) property
                       label:(NSTextField *) label
{
    NSRect sliderFrame = [self sliderRectForIndex:index];
    NSSlider *slider = [[NSSlider alloc] initWithFrame:sliderFrame];
    [slider setMinValue:minValue];
    [slider setMaxValue:maxValue];
    [slider setContinuous:YES];
    [slider setTarget:target];
    [slider setAction:@selector(sliderValueChanged:)];
    [slider setEmitterPropertyToModify:property];
    [slider setLabel:label];
    
    return slider;
}

- (NSRect)textViewRectForIndex:(int) index
{
    NSInteger yPos = [self scrollViewHeight] - UI_ELEMENT_START_Y - ((( 2 * ELEMENT_HEIGHT ) + BUFFER_Y) * index);
    return NSMakeRect(ELEMENT_START_X, yPos, ELEMENT_WIDTH, ELEMENT_HEIGHT);
}

- (NSRect)sliderRectForIndex:(int) index
{
    NSInteger yPos = [self scrollViewHeight] - UI_ELEMENT_START_Y - ((( 2 * ELEMENT_HEIGHT ) + BUFFER_Y) * index) - ELEMENT_HEIGHT;
    return NSMakeRect(ELEMENT_START_X, yPos, ELEMENT_WIDTH, ELEMENT_HEIGHT);
}

- (NSInteger) scrollViewHeight
{
    return UI_ELEMENT_START_Y + ((ELEMENT_HEIGHT * 2) + BUFFER_Y) * (self.allUIElements.count + 3);
}

@end
