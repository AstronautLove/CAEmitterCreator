//
//  MasterViewController.m
//  CAEmitterMaker
//
//  Created by Nick Brice on 1/8/13.
//  Copyright (c) 2013 Nick Brice. All rights reserved.
//

#import "MasterViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface MasterViewController ()

@property (nonatomic, strong) IBOutlet NSView *emitterView;
@property (nonatomic, strong) IBOutlet NSScrollView *settingsView;

@end

@implementation MasterViewController

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
    
    // Create the emitter layer and set our emitter view to use it
    CAEmitterLayer *emitterLayer = [[CAEmitterLayer alloc] init];
    self.emitterView.layer = emitterLayer;
}

@end
