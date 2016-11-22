//
//  SFViewController.h
//  TachometerView
//
//  Created by Thomas Winkler on 15/11/13.
//  Copyright (c) 2013 Thomas Winkler. All rights reserved.
//

#import "SFViewController.h"
#import "SFGaugeView.h"
#import "SFViewXIB.h"


@interface SFViewController ()

@property (weak, nonatomic) IBOutlet SFGaugeView *middleTachometer;

@property (weak, nonatomic) IBOutlet SFGaugeView *topTachometer;
@property (weak, nonatomic) IBOutlet SFGaugeView *leftTachometer;

@end

@implementation SFViewController

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    
    // Load from XIB/NIB example:
//    SFViewXIB* view = [[[NSBundle mainBundle] loadNibNamed:@"SFViewXIB" owner:nil options:nil] lastObject];
//    view.graphSlider.bgColor     = [UIColor colorWithRed:0/255.0 green:124/255.0 blue:205/255.0 alpha:1];
//    view.graphSlider.needleColor = [UIColor colorWithRed:0/255.0 green:39/255.0 blue:64/255.0 alpha:1];
//    view.graphSlider.hideLevel   = YES;
//    
//    view.graphSlider.maxlevel = 115; // initial
//    view.graphSlider.currentLevel = 0;
//    
//    view.frame = self.view.frame;
//    [self.view addSubview:view];
    
    self.topTachometer.bgColor = [UIColor colorWithRed:0/255.0 green:124/255.0 blue:205/255.0 alpha:1];
    self.topTachometer.needleColor = [UIColor colorWithRed:0/255.0 green:39/255.0 blue:64/255.0 alpha:1];
    self.topTachometer.hideLevel = YES;
    self.topTachometer.minImage = @"minImage";
    self.topTachometer.maxImage = @"maxImage";
    self.topTachometer.autoAdjustImageColors = YES;
    
    self.middleTachometer.largeGauge = true;
    //self.middleTachometer.bgColor = [UIColor colorWithRed:102/255.0 green:175/255.0 blue:102/255.0 alpha:1];
    self.middleTachometer.needleColor = [UIColor colorWithRed:27/255.0 green:103/255.0 blue:107/255.0 alpha:1];
    self.middleTachometer.maxlevel = 7;
    self.middleTachometer.minlevel = 1;
    self.middleTachometer.minImage = @"minImage";
    self.middleTachometer.maxImage = @"maxImage";
    self.middleTachometer.currentLevel = 1;
    self.middleTachometer.hideLevel = NO;
    self.middleTachometer.identifier = @"largeGauge";
    self.middleTachometer.delegate = self;


    self.leftTachometer.maxlevel = 7;
    self.leftTachometer.minlevel = 1;
    //self.leftTachometer.bgColor = [UIColor colorWithRed:249/255.0 green:203/255.0 blue:0/255.0 alpha:1];
    self.leftTachometer.needleColor = [UIColor colorWithRed:230/255.0 green:10/255.0 blue:10/255.0 alpha:1];
    self.leftTachometer.minImage = @"emptySymbol";
    self.leftTachometer.maxImage = @"fullSymbol";
    self.leftTachometer.currentLevel = 4;
    self.leftTachometer.autoAdjustImageColors = NO;
    self.leftTachometer.identifier = @"fuelGauge";
    self.leftTachometer.delegate = self;
    
    [self.middleTachometer runSelfTest];
    
}

- (void) sfGaugeView:(SFGaugeView *)gaugeView didChangeLevel:(NSInteger)level
{
    NSLog(@"Value of %@ changed to %ld", gaugeView.identifier, (long)level);
}

@end
