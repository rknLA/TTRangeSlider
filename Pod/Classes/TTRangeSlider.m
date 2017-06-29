//
//  TTRangeSlider.m
//
//  Created by Tom Thorpe

#import "TTRangeSlider.h"

const int HANDLE_TOUCH_AREA_EXPANSION = -30; //expand the touch area of the handle by this much (negative values increase size) so that you don't have to touch right on the handle to activate it.
const float TEXT_HEIGHT = 14;

@interface TTRangeSlider ()

@property (nonatomic, strong) CALayer *sliderLine;
@property (nonatomic, strong) CALayer *sliderLineBetweenHandles;

@property (nonatomic, strong) CAShapeLayer *leftHandle;
@property (nonatomic, assign) BOOL leftHandleSelected;
@property (nonatomic, strong) CAShapeLayer *rightHandle;
@property (nonatomic, assign) BOOL rightHandleSelected;

@property (nonatomic, strong) CATextLayer *minLabel;
@property (nonatomic, strong) CATextLayer *maxLabel;

@property (nonatomic, assign) CGSize minLabelTextSize;
@property (nonatomic, assign) CGSize maxLabelTextSize;

@property (nonatomic, strong) NSNumberFormatter *decimalNumberFormatter; // Used to format values if formatType is YLRangeSliderFormatTypeDecimal

// strong reference needed for UIAccessibilityContainer
// see http://stackoverflow.com/questions/13462046/custom-uiview-not-showing-accessibility-on-voice-over
@property (nonatomic, strong) NSMutableArray *accessibleElements;
@end

/**
 An accessibility element that increments and decrements the left slider
 */
@interface TTRangeSliderLeftElement : UIAccessibilityElement
@end

/**
 An accessibility element that increments and decrements the right slider
 */
@interface TTRangeSliderRightElement : UIAccessibilityElement
@end

static const CGFloat kLabelsFontSize = 12.0f;

@implementation TTRangeSlider

//do all the setup in a common place, as there can be two initialisers called depending on if storyboards or code are used. The designated initialiser isn't always called :|
- (void)initialiseControl {
    //defaults:
    _minimumValue = 0;
    _selectedMinimum = 10;
    _maximumValue = 100;
    _selectedMaximum  = 90;

    _minDistance = -1;
    _maxDistance = -1;

    _enableRange = YES;

    _enableStep = NO;
    _step = 0.1f;

    _hideLabels = NO;
    
    _handleDiameter = 16.0;
    _selectedHandleDiameterMultiplier = 1.7;
    
    _lineHeight = 1.0;
    
    _handleBorderWidth = 0.0;
    _handleBorderColor = self.tintColor;
    
    _labelPadding = 8.0;
    
    //draw the slider line
    self.sliderLine = [CALayer layer];
    self.sliderLine.backgroundColor = self.tintColor.CGColor;
    [self.layer addSublayer:self.sliderLine];
    
    //draw the track distline
    self.sliderLineBetweenHandles = [CALayer layer];
    self.sliderLineBetweenHandles.backgroundColor = self.tintColor.CGColor;
    [self.layer addSublayer:self.sliderLineBetweenHandles];

    [self drawHandles];

    //draw the text labels
    self.minLabel = [[CATextLayer alloc] init];
    self.minLabel.alignmentMode = kCAAlignmentCenter;
    self.minLabel.fontSize = kLabelsFontSize;
    self.minLabel.frame = CGRectMake(0, 0, 75, TEXT_HEIGHT);
    self.minLabel.contentsScale = [UIScreen mainScreen].scale;
    self.minLabel.contentsScale = [UIScreen mainScreen].scale;
    if (self.minLabelColour == nil){
        self.minLabel.foregroundColor = self.tintColor.CGColor;
    } else {
        self.minLabel.foregroundColor = self.minLabelColour.CGColor;
    }
    self.minLabelFont = [UIFont systemFontOfSize:kLabelsFontSize];
    [self.layer addSublayer:self.minLabel];

    self.maxLabel = [[CATextLayer alloc] init];
    self.maxLabel.alignmentMode = kCAAlignmentCenter;
    self.maxLabel.fontSize = kLabelsFontSize;
    self.maxLabel.frame = CGRectMake(0, 0, 75, TEXT_HEIGHT);
    self.maxLabel.contentsScale = [UIScreen mainScreen].scale;
    if (self.maxLabelColour == nil){
        self.maxLabel.foregroundColor = self.tintColor.CGColor;
    } else {
        self.maxLabel.foregroundColor = self.maxLabelColour.CGColor;
    }
    self.maxLabelFont = [UIFont systemFontOfSize:kLabelsFontSize];
    [self.layer addSublayer:self.maxLabel];

    // TODO Create a bundle that allows localization of default accessibility labels and hints
    if (!self.minLabelAccessibilityLabel || self.minLabelAccessibilityLabel.length == 0) {
      self.minLabelAccessibilityLabel = @"Left Handle";
    }
  
    if (!self.minLabelAccessibilityHint || self.minLabelAccessibilityHint.length == 0) {
      self.minLabelAccessibilityHint = @"Minimum value in slider";
    }
  
    if (!self.maxLabelAccessibilityLabel || self.maxLabelAccessibilityLabel.length == 0) {
      self.maxLabelAccessibilityLabel = @"Right Handle";
    }
  
    if (!self.maxLabelAccessibilityHint || self.maxLabelAccessibilityHint.length == 0) {
      self.maxLabelAccessibilityHint = @"Maximum value in slider";
    }
  
    [self refresh];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    //positioning for the slider line
    float barSidePadding = 0.0f;
    CGRect currentFrame = self.frame;
    float yMiddle = currentFrame.size.height/2.0;
    CGPoint lineLeftSide = CGPointMake(barSidePadding, yMiddle);
    CGPoint lineRightSide = CGPointMake(currentFrame.size.width-barSidePadding, yMiddle);
    self.sliderLine.frame = CGRectMake(lineLeftSide.x, lineLeftSide.y, lineRightSide.x-lineLeftSide.x, self.lineHeight);
    
    self.sliderLine.cornerRadius = self.lineHeight / 2.0;

    [self updateLabelValues];
    [self updateHandlePositions];
    [self updateLabelPositions];
}

- (id)initWithCoder:(NSCoder *)aCoder
{
    self = [super initWithCoder:aCoder];

    if(self)
    {
        [self initialiseControl];
    }
    return self;
}

-  (id)initWithFrame:(CGRect)aRect
{
    self = [super initWithFrame:aRect];

    if (self)
    {
        [self initialiseControl];
    }

    return self;
}

- (CGSize)intrinsicContentSize{
    return CGSizeMake(UIViewNoIntrinsicMetric, 65);
}

- (void)drawHandles {
    //draw the minimum slider handle
    if (self.leftHandle == nil) {
        self.leftHandle = [CAShapeLayer layer];
        self.leftHandle.fillColor = self.tintColor.CGColor;
        self.leftHandle.strokeColor = self.handleBorderColor.CGColor;
        self.leftHandle.lineWidth = self.handleBorderWidth;
        [self.layer addSublayer:self.leftHandle];
    }
    UIBezierPath *leftSemicircle = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.handleDiameter / 2, self.handleDiameter / 2) radius:(self.handleDiameter / 2) startAngle:M_PI_2  endAngle:-M_PI_2 clockwise:YES];
    [leftSemicircle closePath];
    self.leftHandle.path = leftSemicircle.CGPath;

    //draw the maximum slider handle
    if (self.rightHandle == nil) {
        self.rightHandle = [CAShapeLayer layer];
        self.rightHandle.fillColor = self.tintColor.CGColor;
        self.rightHandle.strokeColor = self.handleBorderColor.CGColor;
        self.rightHandle.lineWidth = self.handleBorderWidth;
        [self.layer addSublayer:self.rightHandle];

    }
    if (self.enableRange) {
        self.rightHandle.backgroundColor = [UIColor clearColor].CGColor;
        self.rightHandle.borderWidth = 0;
        self.rightHandle.cornerRadius = 0;
        UIBezierPath *rightSemicircle = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.handleDiameter / 2, self.handleDiameter / 2) radius:(self.handleDiameter / 2) startAngle:M_PI_2  endAngle:-M_PI_2 clockwise:NO];
        [rightSemicircle closePath];
        self.rightHandle.path = rightSemicircle.CGPath;
    } else {
        self.rightHandle.backgroundColor = self.handleColor.CGColor;
        self.rightHandle.borderColor = self.handleBorderColor.CGColor;
        self.rightHandle.borderWidth = self.handleBorderWidth;
        self.rightHandle.cornerRadius = self.handleDiameter / 2;
        self.rightHandle.path = NULL;
    }


    self.leftHandle.frame = CGRectMake(0, 0, self.handleDiameter, self.handleDiameter);
    self.rightHandle.frame = CGRectMake(0, 0, self.handleDiameter, self.handleDiameter);
}

- (void)tintColorDidChange {
    CGColorRef color = self.tintColor.CGColor;

    [CATransaction begin];
    [CATransaction setAnimationDuration:0.5];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] ];
    self.sliderLine.backgroundColor = color;
    if (self.handleColor == nil) {
        self.leftHandle.fillColor = color;
        self.rightHandle.fillColor = color;
    }

    if (self.minLabelColour == nil){
        self.minLabel.foregroundColor = color;
    }
    if (self.maxLabelColour == nil){
        self.maxLabel.foregroundColor = color;
    }
    [CATransaction commit];
}

- (float)getPercentageAlongLineForValue:(float) value {
    if (self.minimumValue == self.maximumValue){
        return 0; //stops divide by zero errors where maxMinDif would be zero. If the min and max are the same the percentage has no point.
    }

    //get the difference between the maximum and minimum values (e.g if max was 100, and min was 50, difference is 50)
    float maxMinDif = self.maximumValue - self.minimumValue;

    //now subtract value from the minimumValue (e.g if value is 75, then 75-50 = 25)
    float valueSubtracted = value - self.minimumValue;

    //now divide valueSubtracted by maxMinDif to get the percentage (e.g 25/50 = 0.5)
    return valueSubtracted / maxMinDif;
}

- (float)getXPositionAlongLineForValue:(float) value {
    //first get the percentage along the line for the value
    float percentage = [self getPercentageAlongLineForValue:value];

    //get the difference between the maximum and minimum coordinate position x values (e.g if max was x = 310, and min was x=10, difference is 300)
    float maxMinDif = CGRectGetMaxX(self.sliderLine.frame) - CGRectGetMinX(self.sliderLine.frame) - self.handleDiameter;

    //now multiply the percentage by the minMaxDif to see how far along the line the point should be, and add it onto the minimum x position.
    float offset = percentage * maxMinDif;

    return CGRectGetMinX(self.sliderLine.frame) + offset + (self.handleDiameter / 2);
}

- (void)updateLabelValues {
    if (self.hideLabels || [self.numberFormatterOverride isEqual:[NSNull null]]){
        self.minLabel.string = @"";
        self.maxLabel.string = @"";
        return;
    }

    NSNumberFormatter *formatter = (self.numberFormatterOverride != nil) ? self.numberFormatterOverride : self.decimalNumberFormatter;

    self.minLabel.string = [formatter stringFromNumber:@(self.selectedMinimum)];
    self.maxLabel.string = [formatter stringFromNumber:@(self.selectedMaximum)];
    
    self.minLabelTextSize = [self.minLabel.string sizeWithAttributes:@{NSFontAttributeName:self.minLabelFont}];
    self.maxLabelTextSize = [self.maxLabel.string sizeWithAttributes:@{NSFontAttributeName:self.maxLabelFont}];
}

- (void)updateAccessibilityElements {
  [_accessibleElements removeAllObjects];
  [_accessibleElements addObject:[self leftHandleAccessibilityElement]];
  [_accessibleElements addObject:[self rightHandleAccessbilityElement]];
}

#pragma mark - Set Positions
- (void)updateHandlePositions {
    CGPoint leftHandleCenter = CGPointMake([self getXPositionAlongLineForValue:self.selectedMinimum], CGRectGetMidY(self.sliderLine.frame));
    self.leftHandle.position = leftHandleCenter;

    CGPoint rightHandleCenter = CGPointMake([self getXPositionAlongLineForValue:self.selectedMaximum], CGRectGetMidY(self.sliderLine.frame));
    self.rightHandle.position = rightHandleCenter;
    
    //positioning for the dist slider line
    CGFloat leftPosition = self.leftHandle.position.x;
    CGFloat cornerRadius = 0.0;
    if (self.enableRange == NO) {
        leftPosition = self.sliderLine.frame.origin.x;
        cornerRadius = self.sliderLine.cornerRadius;
    }
    self.sliderLineBetweenHandles.frame = CGRectMake(leftPosition, self.sliderLine.frame.origin.y, self.rightHandle.position.x-leftPosition, self.lineHeight);
    self.sliderLineBetweenHandles.cornerRadius = cornerRadius;
}

- (void)updateLabelPositions {
    //the centre points for the labels are X = the same x position as the relevant handle. Y = the y position of the handle minus half the height of the text label, minus some padding.
    float padding = self.labelPadding;
    float minSpacingBetweenLabels = 8.0f;

    CGPoint leftHandleCentre = [self getCentreOfRect:self.leftHandle.frame];
    CGPoint newMinLabelCenter = CGPointMake(leftHandleCentre.x, self.leftHandle.frame.origin.y - (self.minLabel.frame.size.height/2) - padding);

    CGPoint rightHandleCentre = [self getCentreOfRect:self.rightHandle.frame];
    CGPoint newMaxLabelCenter = CGPointMake(rightHandleCentre.x, self.rightHandle.frame.origin.y - (self.maxLabel.frame.size.height/2) - padding);

    CGSize minLabelTextSize = self.minLabelTextSize;
    CGSize maxLabelTextSize = self.maxLabelTextSize;
    
    
    self.minLabel.frame = CGRectMake(0, 0, minLabelTextSize.width, minLabelTextSize.height);
    self.maxLabel.frame = CGRectMake(0, 0, maxLabelTextSize.width, maxLabelTextSize.height);

    float newLeftMostXInMaxLabel = newMaxLabelCenter.x - maxLabelTextSize.width/2;
    float newRightMostXInMinLabel = newMinLabelCenter.x + minLabelTextSize.width/2;
    float newSpacingBetweenTextLabels = newLeftMostXInMaxLabel - newRightMostXInMinLabel;

    if (self.enableRange == NO || newSpacingBetweenTextLabels > minSpacingBetweenLabels) {
        self.minLabel.position = newMinLabelCenter;
        self.maxLabel.position = newMaxLabelCenter;
    }
    else {
        float increaseAmount = minSpacingBetweenLabels - newSpacingBetweenTextLabels;
        newMinLabelCenter = CGPointMake(newMinLabelCenter.x - increaseAmount/2, newMinLabelCenter.y);
        newMaxLabelCenter = CGPointMake(newMaxLabelCenter.x + increaseAmount/2, newMaxLabelCenter.y);
        self.minLabel.position = newMinLabelCenter;
        self.maxLabel.position = newMaxLabelCenter;

        //Update x if they are still in the original position
        if (self.minLabel.position.x == self.maxLabel.position.x && self.leftHandle != nil) {
            self.minLabel.position = CGPointMake(leftHandleCentre.x, self.minLabel.position.y);
            self.maxLabel.position = CGPointMake(leftHandleCentre.x + self.minLabel.frame.size.width/2 + minSpacingBetweenLabels + self.maxLabel.frame.size.width/2, self.maxLabel.position.y);
        }
    }
}

#pragma mark - Touch Tracking


- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    CGPoint gesturePressLocation = [touch locationInView:self];

    if (CGRectContainsPoint(CGRectInset(self.leftHandle.frame, HANDLE_TOUCH_AREA_EXPANSION, HANDLE_TOUCH_AREA_EXPANSION), gesturePressLocation) || CGRectContainsPoint(CGRectInset(self.rightHandle.frame, HANDLE_TOUCH_AREA_EXPANSION, HANDLE_TOUCH_AREA_EXPANSION), gesturePressLocation))
    {
        //the touch was inside one of the handles so we're definitely going to start movign one of them. But the handles might be quite close to each other, so now we need to find out which handle the touch was closest too, and activate that one.

        // rkn update: with the visual changes, when the handles are equal (and thus fully overlapping), they still visually look like they're adjacent, so take the distance from the left and right of the handles instead of the center, so that the right handle is still selectable in the overlapping case.
        float distanceFromLeftHandle = [self distanceBetweenPoint:gesturePressLocation andPoint:[self getLeftOfRect:self.leftHandle.frame]];
        float distanceFromRightHandle = [self distanceBetweenPoint:gesturePressLocation andPoint:[self getRightOfRect:self.rightHandle.frame]];

        if (distanceFromLeftHandle < distanceFromRightHandle && self.enableRange == YES){
            self.leftHandleSelected = YES;
            [self animateHandle:self.leftHandle withSelection:YES];
        } else {
            if (self.selectedMaximum == self.maximumValue && [self getCentreOfRect:self.leftHandle.frame].x == [self getCentreOfRect:self.rightHandle.frame].x) {
                self.leftHandleSelected = YES;
                [self animateHandle:self.leftHandle withSelection:YES];
            }
            else {
                self.rightHandleSelected = YES;
                [self animateHandle:self.rightHandle withSelection:YES];
            }
        }

        if ([self.delegate respondsToSelector:@selector(didStartTouchesInRangeSlider:)]){
            [self.delegate didStartTouchesInRangeSlider:self];
        }

        return YES;
    } else {
        return NO;
    }
}

- (void)refresh {
    [self refresh:YES];
}

- (void)refresh:(BOOL)sendActions {

    if (self.enableStep && self.step>=0.0f){
        _selectedMinimum = roundf(self.selectedMinimum/self.step)*self.step;
        _selectedMaximum = roundf(self.selectedMaximum/self.step)*self.step;
    }

    float diff = self.selectedMaximum - self.selectedMinimum;

    if (self.minDistance != -1 && diff < self.minDistance) {
        if(self.leftHandleSelected){
            _selectedMinimum = self.selectedMaximum - self.minDistance;
        }else{
            _selectedMaximum = self.selectedMinimum + self.minDistance;
        }
    }else if(self.maxDistance != -1 && diff > self.maxDistance){

        if(self.leftHandleSelected){
            _selectedMinimum = self.selectedMaximum - self.maxDistance;
        }else if(self.rightHandleSelected){
            _selectedMaximum = self.selectedMinimum + self.maxDistance;
        }
    }

    //ensure the minimum and maximum selected values are within range. Access the values directly so we don't cause this refresh method to be called again (otherwise changing the properties causes a refresh)
    if (self.selectedMinimum < self.minimumValue){
        _selectedMinimum = self.minimumValue;
    }
    if (self.selectedMaximum > self.maximumValue){
        _selectedMaximum = self.maximumValue;
    }

    //update the frames in a transaction so that the tracking doesn't continue until the frame has moved.
    [CATransaction begin];
    [CATransaction setDisableActions:YES] ;
    [self updateHandlePositions];
    [self updateLabelPositions];
    [CATransaction commit];
    [self updateLabelValues];
    [self updateAccessibilityElements];

    if (sendActions) {
        //update the delegate
        if ([self.delegate respondsToSelector:@selector(rangeSlider:didChangeSelectedMinimumValue:andMaximumValue:)] &&
            (self.leftHandleSelected || self.rightHandleSelected)){

            [self.delegate rangeSlider:self didChangeSelectedMinimumValue:self.selectedMinimum andMaximumValue:self.selectedMaximum];
        }

        [self sendActionsForControlEvents:UIControlEventValueChanged];
    }
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {

    CGPoint location = [touch locationInView:self];

    //find out the percentage along the line we are in x coordinate terms (subtracting half the frames width to account for moving the middle of the handle, not the left hand side)
    float percentage = ((location.x-CGRectGetMinX(self.sliderLine.frame)) - self.handleDiameter/2) / (CGRectGetMaxX(self.sliderLine.frame) - CGRectGetMinX(self.sliderLine.frame));

    //multiply that percentage by self.maximumValue to get the new selected minimum value
    float selectedValue = percentage * (self.maximumValue - self.minimumValue) + self.minimumValue;

    if (self.leftHandleSelected)
    {
        if (selectedValue < self.selectedMaximum){
            [self setSelectedMinimum:selectedValue sendActions:YES];
        }
        else {
            [self setSelectedMinimum:self.selectedMaximum sendActions:YES];
        }

    }
    else if (self.rightHandleSelected)
    {
        if (selectedValue > self.selectedMinimum || (!self.enableRange && selectedValue >= self.minimumValue)){ //don't let the dots cross over, (unless range is disabled, in which case just dont let the dot fall off the end of the screen)
            [self setSelectedMaximum:selectedValue sendActions:YES];
        }
        else {
            [self setSelectedMaximum:self.selectedMinimum sendActions:YES];
        }
    }

    //no need to refresh the view because it is done as a sideeffect of setting the property

    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if (self.leftHandleSelected){
        self.leftHandleSelected = NO;
        [self animateHandle:self.leftHandle withSelection:NO];
    } else {
        self.rightHandleSelected = NO;
        [self animateHandle:self.rightHandle withSelection:NO];
    }
    if ([self.delegate respondsToSelector:@selector(didEndTouchesInRangeSlider:)]) {
        [self.delegate didEndTouchesInRangeSlider:self];
    }
}

#pragma mark - Animation
- (void)animateHandle:(CALayer*)handle withSelection:(BOOL)selected {
    if (selected){
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.3];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] ];
        handle.transform = CATransform3DMakeScale(self.selectedHandleDiameterMultiplier, self.selectedHandleDiameterMultiplier, 1);

        //the label above the handle will need to move too if the handle changes size
        [self updateLabelPositions];

        [CATransaction setCompletionBlock:^{
        }];
        [CATransaction commit];

    } else {
        [CATransaction begin];
        [CATransaction setAnimationDuration:0.3];
        [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] ];
        handle.transform = CATransform3DIdentity;

        //the label above the handle will need to move too if the handle changes size
        [self updateLabelPositions];

        [CATransaction commit];
    }
}

#pragma mark - Calculating nearest handle to point
- (float)distanceBetweenPoint:(CGPoint)point1 andPoint:(CGPoint)point2
{
    CGFloat xDist = (point2.x - point1.x);
    CGFloat yDist = (point2.y - point1.y);
    return sqrt((xDist * xDist) + (yDist * yDist));
}

- (CGPoint)getCentreOfRect:(CGRect)rect
{
    return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect));
}

- (CGPoint)getLeftOfRect:(CGRect)rect
{
    return CGPointMake(CGRectGetMinX(rect), CGRectGetMidY(rect));
}

- (CGPoint)getRightOfRect:(CGRect)rect
{
    return CGPointMake(CGRectGetMaxX(rect), CGRectGetMidY(rect));
}


#pragma mark - Properties
-(void)setTintColor:(UIColor *)tintColor{
    [super setTintColor:tintColor];

    struct CGColor *color = self.tintColor.CGColor;

    [CATransaction begin];
    [CATransaction setAnimationDuration:0.5];
    [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] ];
    self.sliderLine.backgroundColor = color;

    if (self.minLabelColour == nil){
        self.minLabel.foregroundColor = color;
    }
    if (self.maxLabelColour == nil){
        self.maxLabel.foregroundColor = color;
    }
    [CATransaction commit];
}

- (void)setEnableRange:(BOOL)enableRange {
    _enableRange = enableRange;
    if (!_enableRange){
        self.leftHandle.hidden = YES;
        self.minLabel.hidden = YES;
    } else {
        self.leftHandle.hidden = NO;
        self.minLabel.hidden = NO;
    }
    [self drawHandles];
}

- (NSNumberFormatter *)decimalNumberFormatter {
    if (!_decimalNumberFormatter){
        _decimalNumberFormatter = [[NSNumberFormatter alloc] init];
        _decimalNumberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
        _decimalNumberFormatter.maximumFractionDigits = 0;
    }
    return _decimalNumberFormatter;
}

- (void)setMinimumValue:(float)minimumValue {
    _minimumValue = minimumValue;
    [self refresh:NO];
}

- (void)setMaximumValue:(float)maximumValue {
    _maximumValue = maximumValue;
    [self refresh:NO];
}

- (void)setSelectedMinimum:(float)selectedMinimum {
    [self setSelectedMinimum:selectedMinimum sendActions:NO];
}

- (void)setSelectedMinimum:(float)selectedMinimum sendActions:(BOOL)sendActions {
    if (selectedMinimum < self.minimumValue){
        selectedMinimum = self.minimumValue;
    }

    _selectedMinimum = selectedMinimum;
    [self refresh:sendActions];
}

- (void)setSelectedMaximum:(float)selectedMaximum {
    [self setSelectedMaximum:selectedMaximum sendActions:NO];
}

- (void)setSelectedMaximum:(float)selectedMaximum sendActions:(BOOL)sendActions {
    if (selectedMaximum > self.maximumValue){
        selectedMaximum = self.maximumValue;
    }

    _selectedMaximum = selectedMaximum;
    [self refresh:sendActions];
}

- (float)value {
    if (_enableRange) {
        abort();
    }
    return _selectedMaximum;
}

- (void)setValue:(float)value {
    if (self.enableRange) {
        abort();
    }
    self.selectedMaximum = value;
}

-(void)setMinLabelColour:(UIColor *)minLabelColour{
    _minLabelColour = minLabelColour;
    self.minLabel.foregroundColor = _minLabelColour.CGColor;
}

-(void)setMaxLabelColour:(UIColor *)maxLabelColour{
    _maxLabelColour = maxLabelColour;
    self.maxLabel.foregroundColor = _maxLabelColour.CGColor;
}

-(void)setMinLabelFont:(UIFont *)minLabelFont{
    _minLabelFont = minLabelFont;
    self.minLabel.font = (__bridge CFTypeRef)_minLabelFont.fontName;
    self.minLabel.fontSize = _minLabelFont.pointSize;
}

-(void)setMaxLabelFont:(UIFont *)maxLabelFont{
    _maxLabelFont = maxLabelFont;
    self.maxLabel.font = (__bridge CFTypeRef)_maxLabelFont.fontName;
    self.maxLabel.fontSize = _maxLabelFont.pointSize;
}

-(void)setNumberFormatterOverride:(NSNumberFormatter *)numberFormatterOverride{
    _numberFormatterOverride = numberFormatterOverride;
    [self updateLabelValues];
}

-(void)setHandleImage:(UIImage *)handleImage{
    _handleImage = handleImage;
    
    CGRect startFrame = CGRectMake(0.0, 0.0, 31, 32);
    self.leftHandle.contents = (id)handleImage.CGImage;
    self.leftHandle.frame = startFrame;
    
    self.rightHandle.contents = (id)handleImage.CGImage;
    self.rightHandle.frame = startFrame;
    
    //Force layer background to transparant
    self.leftHandle.backgroundColor = [[UIColor clearColor] CGColor];
    self.rightHandle.backgroundColor = [[UIColor clearColor] CGColor];
}

-(void)setHandleColor:(UIColor *)handleColor{
    _handleColor = handleColor;
    self.leftHandle.fillColor = [handleColor CGColor];
    self.rightHandle.fillColor = [handleColor CGColor];
}

-(void)setHandleBorderColor:(UIColor *)handleBorderColor{
    _handleBorderColor = handleBorderColor;
    self.leftHandle.strokeColor = [handleBorderColor CGColor];
    self.rightHandle.strokeColor = [handleBorderColor CGColor];
}

-(void)setHandleBorderWidth:(CGFloat)handleBorderWidth{
    _handleBorderWidth = handleBorderWidth;
    self.leftHandle.lineWidth = handleBorderWidth;
    self.rightHandle.lineWidth = handleBorderWidth;
}

-(void)setHandleDiameter:(CGFloat)handleDiameter{
    _handleDiameter = handleDiameter;

    [self drawHandles];
}

-(void)setTintColorBetweenHandles:(UIColor *)tintColorBetweenHandles{
    _tintColorBetweenHandles = tintColorBetweenHandles;
    self.sliderLineBetweenHandles.backgroundColor = [tintColorBetweenHandles CGColor];
}

-(void)setLineHeight:(CGFloat)lineHeight{
    _lineHeight = lineHeight;
    [self setNeedsLayout];
}

-(void)setLabelPadding:(CGFloat)labelPadding {
    _labelPadding = labelPadding;
    [self updateLabelPositions];
}

#pragma mark - UIAccessibility

- (BOOL)isAccessibilityElement
{
  return NO;
}

#pragma mark - UIAccessibilityContainer Protocol

- (NSArray *)accessibleElements
{
  if(_accessibleElements != nil) {
    return _accessibleElements;
  }
  
  _accessibleElements = [[NSMutableArray alloc] init];
  [_accessibleElements addObject:[self leftHandleAccessibilityElement]];
  [_accessibleElements addObject:[self rightHandleAccessbilityElement]];
  
  return _accessibleElements;
}

- (NSInteger)accessibilityElementCount
{
  return [[self accessibleElements] count];
}

- (id)accessibilityElementAtIndex:(NSInteger)index
{
  return [[self accessibleElements] objectAtIndex:index];
}

- (NSInteger)indexOfAccessibilityElement:(id)element
{
  return [[self accessibleElements] indexOfObject:element];
}

- (UIAccessibilityElement *)leftHandleAccessibilityElement
{
  TTRangeSliderLeftElement *element = [[TTRangeSliderLeftElement alloc] initWithAccessibilityContainer:self];
  element.isAccessibilityElement = YES;
  element.accessibilityLabel = self.minLabelAccessibilityLabel;
  element.accessibilityHint = self.minLabelAccessibilityHint;
  element.accessibilityValue = self.minLabel.string;
  element.accessibilityFrame = [self convertRect:self.leftHandle.frame toView:nil];
  element.accessibilityTraits = UIAccessibilityTraitAdjustable;
  return element;
}

- (UIAccessibilityElement *)rightHandleAccessbilityElement
{
  TTRangeSliderRightElement *element = [[TTRangeSliderRightElement alloc] initWithAccessibilityContainer:self];
  element.isAccessibilityElement = YES;
  element.accessibilityLabel = self.maxLabelAccessibilityLabel;
  element.accessibilityHint = self.maxLabelAccessibilityHint;
  element.accessibilityValue = self.maxLabel.string;
  element.accessibilityFrame = [self convertRect:self.rightHandle.frame toView:nil];
  element.accessibilityTraits = UIAccessibilityTraitAdjustable;
  return element;
}

@end

@implementation TTRangeSliderLeftElement

- (void)accessibilityIncrement {
  TTRangeSlider* slider = (TTRangeSlider*)self.accessibilityContainer;
  slider.selectedMinimum += slider.step;
  self.accessibilityValue = slider.minLabel.string;
}

- (void)accessibilityDecrement {
  TTRangeSlider* slider = (TTRangeSlider*)self.accessibilityContainer;
  slider.selectedMinimum -= slider.step;
  self.accessibilityValue = slider.minLabel.string;
}

@end

@implementation TTRangeSliderRightElement

- (void)accessibilityIncrement {
  TTRangeSlider* slider = (TTRangeSlider*)self.accessibilityContainer;
  slider.selectedMaximum += slider.step;
  self.accessibilityValue = slider.maxLabel.string;
}

- (void)accessibilityDecrement {
  TTRangeSlider* slider = (TTRangeSlider*)self.accessibilityContainer;
  slider.selectedMaximum -= slider.step;
  self.accessibilityValue = slider.maxLabel.string;
}

@end

