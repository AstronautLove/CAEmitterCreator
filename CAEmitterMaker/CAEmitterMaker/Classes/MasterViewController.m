//
//  MasterViewController.m
//  CAEmitterMaker
//
//  Created by Nick Brice on 1/8/13.
//  Copyright (c) 2013 Nick Brice. All rights reserved.
//

#import "MasterViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "NSControl+EmitterProperty.h"
#import "CAEmitterCell+ImageName.h"

#define UI_ELEMENT_START_Y  400
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
@property (nonatomic, strong) IBOutlet NSTextField *emitterPosXField;
@property (nonatomic, strong) IBOutlet NSTextField *emitterPosYField;
@property (nonatomic, strong) IBOutlet NSTextField *emitterSizeWidthField;
@property (nonatomic, strong) IBOutlet NSTextField *emitterSizeHeightField;
@property NSInteger repititionCount;
@property (nonatomic, strong) IBOutlet NSPopUpButton *renderModeSelector;
@property (nonatomic, strong) IBOutlet NSPopUpButton *emitterShapeSelector;
@property (nonatomic, strong) IBOutlet NSTextField *emitterCellImageNameTextField;
@property (nonatomic, strong) IBOutlet NSTextField *backgroundImageNameTextField;

@property (nonatomic, strong) NSImageView *backgroundImage;

@property (nonatomic, strong) CAEmitterLayer *emitterLayer;
@property (nonatomic, strong) CAEmitterCell *emitterCell;

@property (nonatomic, strong) NSArray *allUIElements;
@property (nonatomic, strong) NSMutableArray *allControls;

@end

@implementation MasterViewController

- (void)awakeFromNib
{
    self.repititionCount = 0;
    
    self.allUIElements = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"UIElements" ofType:@"plist"]];
    
    [self createUIElements];
    
    // Create the emitter layer and set our emitter view to use it
    self.emitterCell = [CAEmitterCell emitterCell];
    self.emitterCell.name = @"name";
    self.emitterLayer.emitterCells = [NSMutableArray arrayWithObject:self.emitterCell];
    self.emitterLayer.birthRate = 0.0f;
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
    self.allControls = [NSMutableArray arrayWithCapacity:self.allUIElements.count];
    [self.renderModeSelector removeAllItems];
    [self.renderModeSelector addItemsWithTitles:@[@"unordered", @"oldest first", @"oldest last", @"back to front", @"additive"]];
    [self.renderModeSelector selectItemAtIndex:4];
    
    [self.emitterShapeSelector removeAllItems];
    [self.emitterShapeSelector addItemsWithTitles:@[@"point", @"line", @"rectangle", @"cuboid", @"circle", @"sphere"]];
    [self.emitterShapeSelector selectItemAtIndex:0];
    
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
        
        control.label = textField;
        
        [self.settingsView.documentView addSubview:textField];
        [self.settingsView.documentView addSubview:control];
        
        [self.allControls addObject:control];
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
    self.emitterCell.imageName = imageURL.lastPathComponent;

    self.emitterCell.color = [[NSColor whiteColor] CGColor];
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
        self.backgroundImageNameTextField.stringValue = fileURL.lastPathComponent;
    }
}

- (IBAction)renderModeSelectorGotEvent:(id)sender
{
    self.emitterLayer.renderMode = [MasterViewController renderModeForIndex:[self.renderModeSelector indexOfSelectedItem]];
}

- (IBAction)emitterShapeSelectorGotEvent:(id)sender
{
    self.emitterLayer.emitterShape = [MasterViewController emitterShapeForIndex:[self.emitterShapeSelector indexOfSelectedItem]];
}

- (IBAction)changeEmitterPositionX:(id)sender
{
    NSTextField *textField = (NSTextField *)sender;
    self.emitterLayer.emitterPosition = CGPointMake(textField.floatValue, self.emitterLayer.emitterPosition.y);
}

- (IBAction)changeEmitterPositionY:(id)sender
{
    NSTextField *textField = (NSTextField *)sender;
    self.emitterLayer.emitterPosition = CGPointMake(self.emitterLayer.emitterPosition.x, 768 - textField.floatValue);
}

- (IBAction)changeEmitterSizeWidth:(id)sender
{
    NSTextField *textField = (NSTextField *)sender;
    self.emitterLayer.emitterSize = CGSizeMake(textField.floatValue, self.emitterLayer.emitterSize.height);
}

- (IBAction)changeEmitterSizeHeight:(id)sender
{
    NSTextField *textField = (NSTextField *)sender;
    self.emitterLayer.emitterSize = CGSizeMake(self.emitterLayer.emitterSize.width, textField.floatValue);
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
        self.emitterCellImageNameTextField.stringValue = fileURL.lastPathComponent;
    }
}

- (IBAction)exportButtonGotEvent:(id)sender
{
    NSSavePanel *saveDialog = [NSSavePanel savePanel];
    
    if ([saveDialog runModal] == NSOKButton)
    {
        NSURL *fileURL = saveDialog.URL;
        
        NSData *serializedEmitter = [self serializedEmitter];
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager createFileAtPath:fileURL.path contents:serializedEmitter attributes:nil];
    }
}

- (IBAction)loadButtonPressed:(id)sender
{
    NSOpenPanel *openDialog = [NSOpenPanel openPanel];
    
    if ([openDialog runModal] == NSOKButton)
    {
        NSURL *fileURL = [openDialog URLs][0];
        NSData *data = [[NSMutableData alloc] initWithContentsOfFile:fileURL.path];
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        NSDictionary *deserializedEmitterCell = [unarchiver decodeObjectForKey:@"Some Key Value"];
        [unarchiver finishDecoding];
        
        [self loadEmitterCellFromDictionary:deserializedEmitterCell];
    }
}

- (void)loadEmitterCellFromDictionary:(NSDictionary *)emitterCellAsDictionary
{
    NSMutableDictionary *layerProperties = [emitterCellAsDictionary mutableCopy];
    NSDictionary *emitterProperties = layerProperties[@"cellProperties"];
    [layerProperties removeObjectForKey:@"cellProperties"];
    [self.emitterLayer setValuesForKeysWithDictionary:layerProperties];
    
    self.emitterPosXField.stringValue = [NSString stringWithFormat:@"%.2f", self.emitterLayer.emitterPosition.x];
    self.emitterPosYField.stringValue = [NSString stringWithFormat:@"%.2f", self.emitterLayer.emitterPosition.y];
    
    self.emitterSizeWidthField.stringValue = [NSString stringWithFormat:@"%.2f", self.emitterLayer.emitterSize.width];
    self.emitterSizeHeightField.stringValue = [NSString stringWithFormat:@"%.2f", self.emitterLayer.emitterSize.height];
    
    [self.renderModeSelector selectItemAtIndex:[MasterViewController indexForRenderMode:self.emitterLayer.renderMode]];
    [self.emitterShapeSelector selectItemAtIndex:[MasterViewController indexForEmitterShape:self.emitterLayer.emitterShape]];
    
    CAEmitterCell *cell = [CAEmitterCell emitterCell];
    [cell setValuesForKeysWithDictionary:emitterProperties];
    
    self.emitterLayer.birthRate = 0.0f;
    
    for (NSString *propertyName in [emitterProperties allKeys])
    {
        for (NSControl *control in self.allControls)
        {
            if ([control.emitterPropertyToModify isEqualToString:propertyName])
            {
                float controlAmount = [emitterCellAsDictionary[propertyName] floatValue];
                control.floatValue = controlAmount;
                [control drawCellInside:control.cell];
                NSInteger index = [self.allControls indexOfObject:control];
                NSDictionary *elementDetails = self.allUIElements[index];
                NSTextField *textField = control.label;
                float propVal = [[cell valueForKey:propertyName] floatValue];
                textField.stringValue = [NSString stringWithFormat:@"%@: %.3f", elementDetails[@"labelString"], propVal];
            }
        }
    }
    
    self.emitterCell = cell;
    self.emitterLayer.emitterCells = @[];
    self.emitterLayer.emitterCells = @[cell];
}

- (NSData *)serializedEmitter
{
    NSMutableDictionary *propertiesToSave = [NSMutableDictionary dictionaryWithCapacity:self.allControls.count];
    for (NSControl *propertyControl in self.allControls)
    {
        propertiesToSave[propertyControl.emitterPropertyToModify] = [self.emitterCell valueForKey:propertyControl.emitterPropertyToModify];
    }
    
    propertiesToSave[@"imageName"] = self.emitterCell.imageName;
    
    NSMutableDictionary *layerProperties = [NSMutableDictionary dictionary];
    layerProperties[@"renderMode"] = self.emitterLayer.renderMode;
    layerProperties[@"emitterShape"] = self.emitterLayer.emitterShape;
    layerProperties[@"emitterPosition"] = [NSValue valueWithPoint:self.emitterLayer.emitterPosition];
    layerProperties[@"emitterSize"] = [NSValue valueWithSize:self.emitterLayer.emitterSize];
    layerProperties[@"cellProperties"] = propertiesToSave;
    
    NSMutableData *serializedProperties = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:serializedProperties];
    [archiver encodeObject:layerProperties forKey:@"Some Key Value"];
    [archiver finishEncoding];
    
    return serializedProperties;
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

+ (NSString * const)renderModeForIndex:(NSUInteger)index
{
    switch (index)
    {
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

+ (NSUInteger)indexForRenderMode:(NSString * const)renderMode
{
    if ([renderMode isEqualToString:kCAEmitterLayerUnordered])
        return 0;
    else if ([renderMode isEqualToString:kCAEmitterLayerOldestFirst])
        return 1;
    else if ([renderMode isEqualToString:kCAEmitterLayerOldestLast])
        return 2;
    else if ([renderMode isEqualToString:kCAEmitterLayerBackToFront])
        return 3;
    else
        return 4;
}

+ (NSString * const)emitterShapeForIndex:(NSUInteger)index
{
    switch (index)
    {
        case 0:
            return kCAEmitterLayerPoint;
        case 1:
            return kCAEmitterLayerLine;
        case 2:
            return kCAEmitterLayerRectangle;
        case 3:
            return kCAEmitterLayerCuboid;
        case 4:
            return kCAEmitterLayerCircle;
        case 5:
            return kCAEmitterLayerSphere;
        default:
            return kCAEmitterLayerPoint;
    }
}

+ (NSUInteger)indexForEmitterShape:(NSString * const)shape
{
    if ([shape isEqualToString:kCAEmitterLayerPoint])
        return 0;
    else if ([shape isEqualToString:kCAEmitterLayerLine])
        return 1;
    else if ([shape isEqualToString:kCAEmitterLayerRectangle])
        return 2;
    else if ([shape isEqualToString:kCAEmitterLayerCuboid])
        return 3;
    else if ([shape isEqualToString:kCAEmitterLayerCircle])
        return 4;
    else if ([shape isEqualToString:kCAEmitterLayerSphere])
        return 5;
    else
        return 0;
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
