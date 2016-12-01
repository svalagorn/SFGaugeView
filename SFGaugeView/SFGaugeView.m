//
//  SFGaugeView.m
//  SFGaugeView
//
//  Created by Thomas Winkler on 15/11/13.
//  Copyright (c) 2013 Thomas Winkler. All rights reserved.
//

#import "SFGaugeView.h"

@interface SFGaugeView()

@property(nonatomic) CGFloat needleRadius;
@property(nonatomic) CGFloat bgRadius;
@property(nonatomic) CGFloat currentRadian;
@property(nonatomic) CGFloat roundedTargetValueRadian;
@property(nonatomic) NSInteger oldLevel;
@property(nonatomic, readonly) NSUInteger scale;

@property(nonatomic, strong) CADisplayLink *timer;
@property(nonatomic) CFTimeInterval lastTime;
@property(nonatomic) CGFloat animationDuration;
@property(nonatomic) CGFloat totalRadiansToRotate;
@property(nonatomic) BOOL runningSelfTest;

@end

@implementation SFGaugeView

@synthesize minlevel = _minlevel;

static const CGFloat CUTOFF = 0.5;
static const CGFloat radiansFor1 = -2.11f;
static const CGFloat radiansFor2 = -1.408f;
static const CGFloat radiansFor3 = -0.702f;
static const CGFloat radiansFor4 = 0.0000f;
static const CGFloat radiansFor5 = 0.702f;
static const CGFloat radiansFor6 = 1.408f;
static const CGFloat radiansFor7 = 2.11f;
static const CGFloat radiansForHalfSegment = 0.35165f;

static const CGFloat radiansFor1Small = -1.071f;
static const CGFloat radiansFor2Small = -0.701f;
static const CGFloat radiansFor3Small = -0.354f;
static const CGFloat radiansFor5Small = 0.357f;
static const CGFloat radiansFor6Small = 0.715f;
static const CGFloat radiansFor7Small = 1.071f;
static const CGFloat radiansForHalfSegmentSmall = 0.181f;

#pragma mark init stuff

- (id) init
{
    self = [super init];
    [self setup];
    
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.opaque = NO;
    self.contentMode = UIViewContentModeRedraw;
    
    self.currentRadian = 0;
    [self addGestureRecognizer:[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)]];
}

- (void) awakeFromNib
{
    [self setup];
    [super awakeFromNib];
}
    
#pragma mark drawing

- (void)drawRect:(CGRect)rect
{
    [self drawBg];
    [self drawNeedle];
    [self drawLabels];
    [self drawImageLabels];
}

#pragma mark timer
-(void)runSelfTest {
    self.runningSelfTest = YES;
    [self startNeedleRotationTimer];
    self.animationDuration = 0.75f;
    self.roundedTargetValueRadian = radiansFor7;
    self.totalRadiansToRotate = radiansFor7 * 2;
}

-(void)goMin {
    self.runningSelfTest = NO;
    [self startNeedleRotationTimer];
    self.animationDuration = 0.75f;
    self.roundedTargetValueRadian = radiansFor1;
    self.totalRadiansToRotate = radiansFor1 * 2;
}

- (void)rotateNeedleToClosestValue {
    [self startNeedleRotationTimer];
    self.animationDuration = 0.4f;
    self.totalRadiansToRotate = self.roundedTargetValueRadian - self.currentRadian;
}

-(void)startNeedleRotationTimer{
    self.timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(rotateNeedleForFrame:)];
    [self.timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    //NSLog(@"***TIMER STARTED***");
}

- (void)rotateNeedleForFrame:(CADisplayLink *)sender {
    if (!self.lastTime)
    {
        [[UIApplication sharedApplication] beginIgnoringInteractionEvents];
        self.lastTime = self.timer.timestamp;
        return;
    }
    sender.paused = YES;
    
    CFTimeInterval elapsedTimeSinceLastFrame = (sender.timestamp - self.lastTime);
    //NSLog(@"elapsedTimeSinceLastFrame %f", elapsedTimeSinceLastFrame);
    self.lastTime = sender.timestamp;
    
    CGFloat ratio = elapsedTimeSinceLastFrame / self.animationDuration;
    //NSLog(@"ratio %f", ratio);
    
    CGFloat radiansToRotate = self.totalRadiansToRotate * ratio;
    //NSLog(@"radiansToRotate %f", radiansToRotate);

    
    if(radiansToRotate < 0) //ROTERA MOTSOLS
    {
        if((self.currentRadian + radiansToRotate) <= self.roundedTargetValueRadian) {
            self.currentRadian = self.roundedTargetValueRadian;

        } else {
            self.currentRadian = self.currentRadian + radiansToRotate;
        }
    }
    else { //ROTERA MEDSOLS
        if((self.currentRadian + radiansToRotate) >= self.roundedTargetValueRadian) {
            self.currentRadian = self.roundedTargetValueRadian;
            
        } else {
            self.currentRadian = self.currentRadian + radiansToRotate;
        }
    }
    
    if(self.currentRadian == self.roundedTargetValueRadian) {
        //NSLog(@"Rotation finished");
        self.lastTime = 0;
        [self.timer invalidate];
        self.timer = nil;
        [self currentLevel];
        [[UIApplication sharedApplication] endIgnoringInteractionEvents];
        //NSLog(@"***TIMER ENDED***");
        if(self.runningSelfTest){
            [self goMin];
        }
    }
    sender.paused = NO;
    //draw!
    [self setNeedsDisplay];
}

//- betyder instansmetod, + betyder klassmetod.
- (BOOL)floatingPointsAreEqualEnough:(CGFloat)n1 number2:(CGFloat)n2{
    return (fabs(n1 - n2) < 0.002);
}

- (void) drawImageLabels
{
    if (self.minImage && self.maxImage) {
        
        UIImage *badImg;
        UIImage *goodImg;
        
        if (self.autoAdjustImageColors) {
            badImg = [self imageNamed:self.minImage withColor:self.needleColor drawAsOverlay:NO];
            goodImg = [self imageNamed:self.maxImage withColor:self.needleColor drawAsOverlay:NO];
        } else {
            badImg = [UIImage imageNamed:self.minImage];
            goodImg = [UIImage imageNamed: self.maxImage];
        }
        
        if (self.largeGauge){
            CGFloat scaleFactor = (self.bounds.size.width / badImg.size.width)/6 ;
            
            [badImg drawInRect:CGRectMake([self centerX] - self.bgRadius * 0.76,
                                          [self centerY] * 1.6 - badImg.size.height * scaleFactor,
                                          badImg.size.width * scaleFactor,
                                          badImg.size.height * scaleFactor)];
            [goodImg drawInRect:CGRectMake([self centerX] + self.bgRadius * 0.75 - (goodImg.size.width * scaleFactor),
                                           [self centerY] * 1.6 - goodImg.size.height * scaleFactor,
                                           goodImg.size.width * scaleFactor,
                                           goodImg.size.height * scaleFactor)];
        } else {
            CGFloat scaleFactor = (self.bounds.size.width / badImg.size.width)/12;
            [badImg drawInRect:CGRectMake([self centerX] - self.bgRadius * 1.04,
                                          [self centerY] - badImg.size.height * 2 * scaleFactor,
                                          badImg.size.width * scaleFactor,
                                          badImg.size.height * scaleFactor)];
            [goodImg drawInRect:CGRectMake([self centerX] + self.bgRadius * 1.04 - (goodImg.size.width * scaleFactor),
                                           [self centerY] - goodImg.size.height * 2 * scaleFactor,
                                           goodImg.size.width * scaleFactor,
                                           goodImg.size.height * scaleFactor)];
        }
    }
}

- (void) drawLabels
{
    CGFloat fontSize = self.bounds.size.width/18;
    UIFont* font = [UIFont fontWithName:@"Arial" size:fontSize];
    UIColor* textColor = [self needleColor];
    
    
    NSDictionary* stringAttrs = @{ NSFontAttributeName : font, NSForegroundColorAttributeName : textColor };
    
    if (!self.hideLevel && self.currentLevel != -1) {
        fontSize = [self needleRadius] + 5;
        font = [UIFont fontWithName:@"Arial" size:fontSize];
        textColor = [self bgColor];
        
        stringAttrs = @{ NSFontAttributeName : font, NSForegroundColorAttributeName : textColor };
        NSAttributedString* levelStr = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%lu", (unsigned long)[self currentLevel]] attributes:stringAttrs];
        
        CGPoint levelStrPoint = CGPointMake([self center].x - levelStr.size.width/2, [self center].y - levelStr.size.height/2);
        [levelStr drawAtPoint:levelStrPoint];
    }
}

- (void) drawBg
{
    CGFloat starttime = M_PI + CUTOFF;
    CGFloat endtime = 2 * M_PI - CUTOFF;
    CGFloat coloredTrackRadius = self.bgRadius;
    
    if(self.largeGauge){
        starttime = 0.667 * M_PI + CUTOFF;  //hax
        endtime = 0.333 * M_PI - CUTOFF;
        coloredTrackRadius = coloredTrackRadius * 0.9f;
    }
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    if(self.largeGauge){
        CGFloat bgEndAngle = (3 * M_PI_2) + self.currentRadian;

        if ((self.largeGauge && self.currentRadian > radiansFor1) || (!self.largeGauge && bgEndAngle > starttime)) {
            UIBezierPath *bgPath = [UIBezierPath bezierPath];
            [bgPath moveToPoint:[self center]];
            [bgPath addArcWithCenter:[self center] radius:coloredTrackRadius startAngle:starttime endAngle: bgEndAngle clockwise:YES];
            [bgPath addLineToPoint:[self center]];
            //[[self bgColor] set];
            [[UIColor colorWithRed:102/255.0 green:175/255.0 blue:102/255.0 alpha:1] set];
            [bgPath fill];
        }
        
        UIBezierPath *bgPath2 = [UIBezierPath bezierPath];
        [bgPath2 moveToPoint:[self center]];
        [bgPath2 addArcWithCenter:[self center] radius:coloredTrackRadius startAngle:bgEndAngle endAngle:endtime clockwise:YES];
        [[self lighterColorForColor:[self bgColor]] set];
        [bgPath2 fill];
        
        //markers
        UIBezierPath *markerpath = [UIBezierPath bezierPath];
        [markerpath addArcWithCenter:[self center] radius:self.bgRadius * 1.05f startAngle:starttime endAngle:endtime clockwise:YES];
        [markerpath addLineToPoint:[self center]];

        [[self markerColor] set];
        markerpath.lineWidth = 12; //todo calculate value
        
        CGContextSaveGState(context);
        CGFloat outerCircumference = 2 * M_PI * (self.bgRadius * 1.05f);
        CGFloat outerAdjustedDivisionFactor = 9.037236 - ((self.layer.bounds.size.width - 248) * (0.03851 / 100));
        CGFloat outerGap = outerCircumference / outerAdjustedDivisionFactor; //9.037236 vid 248, 8,998729 vid 348 > 0,03851 differens / 100 points
        CGFloat dashAndGap[] = {1.0, outerGap}; //81.47 vid 248, 114.81 vid 348
        CGContextSetLineDash(context, 0.0, dashAndGap, 2);
        [markerpath stroke];
        CGContextRestoreGState(context);
        
        //white gaps
        UIBezierPath *whiteGapPath = [UIBezierPath bezierPath];
        [whiteGapPath addArcWithCenter:[self center] radius:coloredTrackRadius * 0.9f startAngle:starttime endAngle:endtime clockwise:YES];
        [whiteGapPath addLineToPoint:[self center]];
        
        [[UIColor whiteColor] set];
        whiteGapPath.lineWidth = 33; //todo calculate value

        CGContextSaveGState(context);
        CGFloat innerCircumference = 2 * M_PI * (coloredTrackRadius * 0.9f);
        CGFloat innerAdjustedDivisionFactor = 9.253418 - ((self.layer.bounds.size.width - 248) * (0.10830 / 100));
        CGFloat innerGap = innerCircumference / innerAdjustedDivisionFactor; //9.253418 vid 248, 9.145116 vid 348 > 0.10830 differens / 100 points
        
        
        CGFloat whiteGapDashAndGap[] = {2.0, innerGap}; //61.38 vid 248, 87.15 vid 348
        CGContextSetLineDash(context, 0.0, whiteGapDashAndGap, 2);
        [whiteGapPath stroke];
        CGContextRestoreGState(context);
        
        //fill inner space
        UIBezierPath *bgPathInner = [UIBezierPath bezierPath];
        [bgPathInner moveToPoint:[self center]];
        
        CGFloat innerRadius = self.bgRadius * 0.7;
        [bgPathInner addArcWithCenter:[self center] radius:innerRadius startAngle:starttime endAngle:endtime + 1 clockwise:YES];
        
        self.backgroundColor ? [self.backgroundColor set] : [[UIColor whiteColor] set];
        [bgPathInner stroke];
        [bgPathInner fill];
    } else {
        //large markers
        UIBezierPath *markerpath = [UIBezierPath bezierPath];
        [markerpath addArcWithCenter:[self center] radius:self.bgRadius * 1.07f startAngle:starttime endAngle:endtime clockwise:YES];
        [markerpath addLineToPoint:[self center]];
        
        [[self bgColor] set];
        markerpath.lineWidth = 25;
        
        CGContextSaveGState(context);
        CGFloat outerCircumference = 2 * M_PI * (self.bgRadius * 1.07f);
        CGFloat outerAdjustedDivisionFactor = 6.24199 - ((self.layer.bounds.size.width - 248) * (0.11 / 100));
        CGFloat outerGap = outerCircumference / outerAdjustedDivisionFactor; //6,24199 vid 248, 6.13176 vid 348 > 0,110 differens / 100 points
        CGFloat dashAndGap[] = {5.0, outerGap}; //120.2 vid 248, 171.7 vid 348
        CGContextSetLineDash(context, 0.0, dashAndGap, 2);
        [markerpath stroke];
        CGContextRestoreGState(context);
        
        CGFloat smallCircumference = 2 * M_PI * (self.bgRadius * 1.09f);
        
        //small markers left side
        UIBezierPath *smallMarkerpathLeft = [UIBezierPath bezierPath];
        smallMarkerpathLeft.lineWidth = 15;
        [smallMarkerpathLeft addArcWithCenter:[self center] radius:self.bgRadius * 1.09f startAngle:starttime endAngle:(3 * M_PI / 2) clockwise:YES];
        
        CGFloat smallAdjustedDivisionFactorLeft = 19.23281 - ((self.layer.bounds.size.width - 248) * (0.45651 / 100));
        CGFloat smallGapLeft = smallCircumference / smallAdjustedDivisionFactorLeft; //19,23281 vid 248, 18,7763 vid 348 > 0,45651 differens / 100 points
        CGFloat smallDashAndGapLeft[] = {3.0, smallGapLeft}; //39.74 vid 248, 57.12 vid 348
        
        //small markers right side
        UIBezierPath *smallMarkerpathRight = [UIBezierPath bezierPath];
        smallMarkerpathRight.lineWidth = 15;
        [smallMarkerpathRight addArcWithCenter:[self center] radius:self.bgRadius * 1.09f startAngle:(3 * M_PI / 2) endAngle:endtime-0.05 clockwise:YES];
        
        CGFloat smallAdjustedDivisionFactorRight = 18.7102 - ((self.layer.bounds.size.width - 248) * (0.31394 / 100));
        CGFloat smallGapRight = smallCircumference / smallAdjustedDivisionFactorRight; //18.7102 vid 248, 18.39626 vid 348 > 0,31394 differens / 100 points
        CGFloat smallDashAndGapRight[] = {3.0, smallGapRight}; //40.85 vid 248, 58.3 vid 348
        
        CGContextSaveGState(context);
        CGContextSetLineDash(context, 0.0, smallDashAndGapLeft, 2);
        [smallMarkerpathLeft stroke];
        CGContextRestoreGState(context);
        
        CGContextSaveGState(context);
        CGContextSetLineDash(context, 2, smallDashAndGapRight, 2);
        [smallMarkerpathRight stroke];
        CGContextRestoreGState(context);
    }
    
    //todo make a better interface in general
    if(!self.largeGauge){
        UIImage *batterySymbol = [UIImage imageNamed:@"batterySymbol"];
        CGFloat scaleFactor = (self.bounds.size.width / batterySymbol.size.width)/6 ;
        
        [batterySymbol drawInRect:CGRectMake([self centerX] * 1.16 - (batterySymbol.size.width * scaleFactor),
                                             [self centerY] * 0.7 - (batterySymbol.size.height * scaleFactor),
                                             batterySymbol.size.width * scaleFactor,
                                             batterySymbol.size.height * scaleFactor)];
    }
}

- (UIImage *)imageNamed:(NSString *)name withColor:(UIColor *)color drawAsOverlay:(BOOL)overlay{
    // load the image
    UIImage *img = [UIImage imageNamed:name];
    
    // begin a new image context, to draw our colored image onto
    UIGraphicsBeginImageContextWithOptions(img.size, NO, [[UIScreen mainScreen] scale]);
    
    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // set the fill color
    [color setFill];
    
    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // set the blend mode to overlay, and the original image
    CGContextSetBlendMode(context, kCGBlendModeOverlay);
    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
    if(overlay) CGContextDrawImage(context, rect, img.CGImage);
    
    // set a mask that matches the shape of the image, then draw (overlay) a colored rectangle
    CGContextClipToMask(context, rect, img.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context,kCGPathFill);
    
    // generate a new UIImage from the graphics context we drew onto
    UIImage *coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //return the color-burned image
    return coloredImg;
}

- (void) drawNeedle
{
    CGFloat distance;
    if(self.largeGauge){
        distance = [self bgRadius] + ([self bgRadius] * 0.1);
    } else {
        distance = [self bgRadius] + ([self bgRadius] * 0.135);
    }
    //CGFloat distance = [self bgRadius] + ([self bgRadius] * 0.1);
    CGFloat starttime = 0;
    CGFloat endtime = M_PI;
    CGFloat topSpace = (distance * 0.1)/6;
    
    CGPoint center = [self center];
    
    CGPoint topPoint = CGPointMake([self center].x, [self center].y - distance);
    CGPoint topPoint1 = CGPointMake([self center].x - topSpace, [self center].y - distance + (distance * 0.1));
    CGPoint topPoint2 = CGPointMake([self center].x + topSpace, [self center].y - distance + (distance * 0.1));
    
    CGPoint finishPoint = CGPointMake([self center].x + self.needleRadius, [self center].y);
    
    UIBezierPath *needlePath = [UIBezierPath bezierPath]; //empty path
    [needlePath moveToPoint:center];
    CGPoint next;
    next.x = center.x + self.needleRadius * cos(starttime);
    next.y = center.y + self.needleRadius * sin(starttime);
    [needlePath addLineToPoint:next]; //go one end of arc
    [needlePath addArcWithCenter:center radius:self.needleRadius startAngle:starttime endAngle:endtime clockwise:YES]; //add the arc
    

    [needlePath addLineToPoint:topPoint1];
    if(self.largeGauge){
        [needlePath addQuadCurveToPoint:topPoint2 controlPoint:topPoint];
    } else{
        [needlePath addLineToPoint:topPoint2];
    }
    [needlePath addLineToPoint:finishPoint];
    
    CGAffineTransform translate = CGAffineTransformMakeTranslation(-1 * (self.bounds.origin.x + [self center].x), -1 * (self.bounds.origin.y + [self center].y));
    [needlePath applyTransform:translate];
    
    translate = CGAffineTransformMakeRotation(self.currentRadian);
    [needlePath applyTransform:translate];
    
    translate = CGAffineTransformMakeTranslation((self.bounds.origin.x + [self center].x), (self.bounds.origin.y + [self center].y));
    [needlePath applyTransform:translate];
    
    [[self needleColor] set];
    [needlePath fill];
    
    if(!self.largeGauge){
        CAShapeLayer *circleLayer = [CAShapeLayer layer];
        [circleLayer setPath:[[UIBezierPath bezierPathWithOvalInRect:CGRectMake([self center].x - (self.needleRadius * 2), [self center].y - (self.needleRadius * 2), self.needleRadius * 4, self.needleRadius * 4)] CGPath]];
        circleLayer.fillColor = [self bgColor].CGColor;
        [[self layer] addSublayer:circleLayer];
    }
}

- (UIColor *)lighterColorForColor:(UIColor *)c
{
    CGFloat r, g, b, a;
    if ([c getRed:&r green:&g blue:&b alpha:&a])
        return [UIColor colorWithRed:MIN(r + 0.12, 1.0)
                               green:MIN(g + 0.12, 1.0)
                                blue:MIN(b + 0.12, 1.0)
                               alpha:a];
    return nil;
}

#pragma mark pan gesture recognizer

- (void) handlePan: (UIPanGestureRecognizer *) gesture
{
    CGPoint currentPosition = [gesture locationInView:self];
    
    if (gesture.state == UIGestureRecognizerStateChanged)
    {
        self.currentRadian = [self calculateRadian:currentPosition];
        [self setNeedsDisplay];
        [self currentLevel];
    }
    if (gesture.state == UIGestureRecognizerStateEnded)
    {
        //NSLog(@"gesture state is 'ended'");
        if(self.largeGauge){
            //Avrunda till radianvärde för närmsta heltal (halvt segment = 0.35165 radians)
            if(self.currentRadian < radiansFor1 + radiansForHalfSegment){
                self.roundedTargetValueRadian = radiansFor1;
            }
            else if (self.currentRadian > radiansFor1 + radiansForHalfSegment && self.currentRadian < radiansFor2 + radiansForHalfSegment)
            {
                self.roundedTargetValueRadian = radiansFor2;
            }
            else if (self.currentRadian > radiansFor2 + radiansForHalfSegment && self.currentRadian < radiansFor3 + radiansForHalfSegment)
            {
                self.roundedTargetValueRadian = radiansFor3;
            }
            else if (self.currentRadian > radiansFor3 + radiansForHalfSegment && self.currentRadian < radiansFor4 + radiansForHalfSegment)
            {
                self.roundedTargetValueRadian = radiansFor4;
            }
            else if (self.currentRadian > radiansFor4 + radiansForHalfSegment && self.currentRadian < radiansFor5 + radiansForHalfSegment)
            {
                self.roundedTargetValueRadian = radiansFor5;
            }
            else if (self.currentRadian > radiansFor5 - radiansForHalfSegment && self.currentRadian < radiansFor6 + radiansForHalfSegment)
            {
                self.roundedTargetValueRadian = radiansFor6;
            }
            else if(self.currentRadian > radiansFor7 - radiansForHalfSegment){
                self.roundedTargetValueRadian = radiansFor7;
            }
            
            [self rotateNeedleToClosestValue];
        } else {
            if(self.currentRadian < radiansFor1Small + radiansForHalfSegmentSmall){
                self.roundedTargetValueRadian = radiansFor1Small;
            }
            else if (self.currentRadian > radiansFor1Small + radiansForHalfSegmentSmall && self.currentRadian < radiansFor2Small + radiansForHalfSegmentSmall)
            {
                self.roundedTargetValueRadian = radiansFor2Small;
            }
            else if (self.currentRadian > radiansFor2Small + radiansForHalfSegmentSmall && self.currentRadian < radiansFor3Small + radiansForHalfSegmentSmall)
            {
                self.roundedTargetValueRadian = radiansFor3Small;
            }
            else if (self.currentRadian > radiansFor3Small + radiansForHalfSegmentSmall && self.currentRadian < radiansFor4 + radiansForHalfSegmentSmall)
            {
                self.roundedTargetValueRadian = radiansFor4;
            }
            else if (self.currentRadian > radiansFor4 + radiansForHalfSegmentSmall && self.currentRadian < radiansFor5Small + radiansForHalfSegmentSmall)
            {
                self.roundedTargetValueRadian = radiansFor5Small;
            }
            else if (self.currentRadian > radiansFor5Small - radiansForHalfSegmentSmall && self.currentRadian < radiansFor6Small + radiansForHalfSegmentSmall)
            {
                self.roundedTargetValueRadian = radiansFor6Small;
            }
            else if(self.currentRadian > radiansFor7Small - radiansForHalfSegmentSmall){
                self.roundedTargetValueRadian = radiansFor7Small;
            }
            
            [self rotateNeedleToClosestValue];
        }
    }
}

#pragma mark calculation stuff

- (CGFloat)calculateRadian: (CGPoint) pos
{
    CGPoint tmpPoint = CGPointMake(pos.x, [self center].y);
    
    // return zero if needle in center
    if (pos.x == [self center].x) {
        return 0;
    }
    
    if (pos.y > [self center].y && !_largeGauge) { //y-axeln räknar uppifrån och ned i iOS. För largeGauge behöver vi hantera när gesture går över center-y.
        return self.currentRadian;
    }
        
    // calculate distance between pos and center
    CGFloat p12 = [self calculateDistanceFrom:pos to:[self center]];
    
    // calculate distance between pos and tmpPoint
    CGFloat p23 = [self calculateDistanceFrom:pos to: tmpPoint];
    
    // cacluate distance between tmpPont and center
    CGFloat p13 = [self calculateDistanceFrom:tmpPoint to: [self center]];
    
    CGFloat angleOfCos = acos(((p12 * p12) + (p13 * p13) - (p23 * p23))/(2 * p12 * p13));
    CGFloat result = M_PI_2 - angleOfCos;
    
    if(pos.y > [self center].y ) {
        result = M_PI_2 + angleOfCos;
    }
    
    if (pos.x <= [self center].x) {
        result = -result;
    }
    
    if(self.largeGauge){
        if (result > radiansFor7) {
            return radiansFor7;
        }
        
        if (result < radiansFor1) {
            return radiansFor1;
        }
        
        return result;
    }
    
    if (result > (M_PI_2 - CUTOFF)) {
        return M_PI_2 - CUTOFF;
    }
    
    if (result < (-M_PI_2 + CUTOFF)) {
        return -M_PI_2 + CUTOFF;
    }

    return result;
}

- (CGFloat)calculateDistanceFrom: (CGPoint) p1 to: (CGPoint) p2
{
    CGFloat dx = p2.x - p1.x;
    CGFloat dy = p2.y - p1.y;
    CGFloat distance = sqrt(dx*dx + dy*dy);
    return distance;
}

# pragma mark current level
- (NSInteger) currentLevel
{
    NSInteger level = -1;
    
    CGFloat levelSection = (M_PI - (CUTOFF * 2)) / self.scale;
    if(self.largeGauge){
        levelSection = radiansFor5;
    }

    CGFloat currentSection = -M_PI_2 + CUTOFF;
    if(self.largeGauge){
        currentSection = radiansFor1;
    }
    //CGFloat currentSection = -M_PI + CUTOFF;
    CGFloat currentPlusLevel = 0.000f;
    for (int i=1; i<=self.scale;i++) {
//        NSLog(@"[%fl, %fl] = %fl", currentSection, (currentSection + levelSection), self.currentRadian);
        currentPlusLevel = (float)(currentSection + levelSection);
        if (self.currentRadian >= currentSection && (self.currentRadian < currentPlusLevel)) {
            level = i;
            break;
        }
        currentSection += levelSection;
    }
    
    if(self.largeGauge){
        if (self.currentRadian >= radiansFor7) {
            level = self.scale + 1;
        }
    } else {
        if (self.currentRadian >= (M_PI_2 - CUTOFF)) {
            level = self.scale + 1;
        }
    }

    //corner case
    if(level == self.minlevel && [self floatingPointsAreEqualEnough:self.currentRadian number2:currentPlusLevel]){
        level++;
    }
    
    level = level + self.minlevel - 1;
    
    //    NSLog(@"Current Level is %lu", (unsigned long)level);
    if (self.oldLevel != level && self.delegate && [self.delegate respondsToSelector:@selector(sfGaugeView:didChangeLevel:)] && level != -1) {
        [self.delegate sfGaugeView:self didChangeLevel:level];
    }
    
    self.oldLevel = level;
    return level;
}

- (void) setCurrentLevel:(NSInteger)currentLevel
{
    self.oldLevel = currentLevel;
    
    if (self.largeGauge){
        switch (currentLevel) {
            case 1:
                self.currentRadian = radiansFor1;
                break;
            case 2:
                self.currentRadian = radiansFor2;
                break;
            case 3:
                self.currentRadian = radiansFor3;
                break;
            case 5:
                self.currentRadian = radiansFor5;
                break;
            case 6:
                self.currentRadian = radiansFor6;
                break;
            case 7:
                self.currentRadian = radiansFor7;
                break;
                
            default:
                self.currentRadian = 0.f;
                break;
        }
    } else {
        switch (currentLevel) {
            case 1:
                self.currentRadian = radiansFor1Small;
                break;
            case 2:
                self.currentRadian = radiansFor2Small;
                break;
            case 3:
                self.currentRadian = radiansFor3Small;
                break;
            case 5:
                self.currentRadian = radiansFor5Small;
                break;
            case 6:
                self.currentRadian = radiansFor6Small;
                break;
            case 7:
                self.currentRadian = radiansFor7Small;
                break;
                
            default:
                self.currentRadian = 0.f;
                break;
        }
    }
    [self setNeedsDisplay];
}

#pragma mark custom getter/setter

- (CGPoint)center
{
    return CGPointMake([self centerX], [self centerY]);
}

- (CGFloat)centerY
{
    if(self.largeGauge) {
        return self.bounds.size.height - (self.bounds.size.height * 0.4);
    } else {
        return self.bounds.size.height - (self.bounds.size.height * 0.2);
    }
}

- (CGFloat)centerX
{
    return self.bounds.size.width/2;
}

- (UIColor *) needleColor
{
    if (!_needleColor) {
        _needleColor = [UIColor colorWithRed:76/255.0 green:177/255.0 blue:88/255.0 alpha:1];
    }
    
    return _needleColor;
}

- (UIColor *) markerColor
{
    if(!_markerColor){
        const CGFloat* components = CGColorGetComponents(_needleColor.CGColor);
        _markerColor = [UIColor colorWithRed:components[0] green:components[1] blue:components[2] alpha:0.6];
        //force gray - todo clean up
        //_markerColor = [UIColor colorWithRed:175/255.0 green:175/255.0 blue:175/255.0 alpha:1];
        
    }
    
    return _markerColor;
}


- (UIColor *) bgColor
{
    if (!_bgColor) {
        _bgColor = [UIColor colorWithRed:211/255.0 green:211/255.0 blue:211/255.0 alpha:1];
    }
    
    return _bgColor;
}

- (CGFloat) needleRadius
{
    if (!_needleRadius) {
        //hax
        if (self.largeGauge){
            _needleRadius = self.bounds.size.height * 0.06;
        }
        else {
            _needleRadius = self.bounds.size.height * 0.03;
        }
    }
    
    return _needleRadius;
}

- (NSUInteger) maxlevel
{
    if (!_maxlevel) {
        _maxlevel = 10;
    }
    
    return _maxlevel;
}

- (void)setMinlevel:(NSUInteger)minlevel
{
    _minlevel = minlevel;
}

- (CGFloat) bgRadius
{
    if (!_bgRadius) {
        _bgRadius = [self centerX] - ([self centerX] * 0.1);
    }
    
    return _bgRadius;
}

- (NSUInteger)scale {
    return self.maxlevel - self.minlevel;
}

@end
