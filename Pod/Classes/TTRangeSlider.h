//
//  TTRangeSliderView.h
//
//  Created by Tom Thorpe
//

#import <UIKit/UIKit.h>
#import "TTRangeSliderDelegate.h"


@interface TTRangeSlider : UIControl <UIGestureRecognizerDelegate>

/**
 * Optional delegate.
 */
@property (nonatomic, weak) IBOutlet id<TTRangeSliderDelegate> delegate;

/**
 * The minimum possible value to select in the range
 */
@property (nonatomic, assign) float minimumValue;

/**
 * The maximum possible value to select in the range
 */
@property (nonatomic, assign) float maximumValue;

/**
 * The selected minumum value
 * (note: This should be less than the selectedMaximum)
 */
@property (nonatomic, assign) float selectedMinimum;

/**
 * The selected maximum value
 * (note: This should be greater than the selectedMinimum)
 */
@property (nonatomic, assign) float selectedMaximum;

/**
 * The selected value when range is disabled.
 * This is just a bridge to selectedMaximum so that TTRangeSlider is API-compatible with UISlider.
 * Raises an exception if called when range is enabled.
 */
@property (nonatomic, assign) float value;

/**
 * Each handle in the slider has a label above it showing the current selected value. By default, this is displayed as a decimal format.
 * You can override this default here by supplying your own NSNumberFormatter. For example, you could supply an NSNumberFormatter that has a currency style, or a prefix or suffix.
 * If this property is nil, the default decimal format will be used. Note: If you want no labels at all, please use the hideLabels flag. */
@property (nonatomic, strong) NSNumberFormatter *numberFormatterOverride;

/**
 * Hides the labels above the slider controls. YES = labels will be hidden. NO = labels will be shown. Default is NO.
 */
@property (nonatomic, assign) BOOL hideLabels;

/**
 * The color of the minimum value text label. If not set, the default is the tintColor.
 */
@property (nonatomic, strong) UIColor *minLabelColour;

/**
 * The color of the maximum value text label. If not set, the default is the tintColor.
 */
@property (nonatomic, strong) UIColor *maxLabelColour;


/**
 * The font of the minimum value text label. If not set, the default is system font size 12.
 */
@property (nonatomic, strong) UIFont *minLabelFont;

/**
 * The font of the maximum value text label. If not set, the default is system font size 12.
 */
@property (nonatomic, strong) UIFont *maxLabelFont;

/**
 * The label displayed in accessibility mode for minimum value handler
 */
@property (nonatomic, strong) NSString *minLabelAccessibilityLabel;

/**
 * The label displayed in accessibility mode for maximum value handler
 */
@property (nonatomic, strong) NSString *maxLabelAccessibilityLabel;

/**
 * The brief description displayed in accessibility mode for minimum value handler
 */
@property (nonatomic, strong) NSString *minLabelAccessibilityHint;

/**
 * The brief description displayed in accessibility mode for maximum value handler
 */
@property (nonatomic, strong) NSString *maxLabelAccessibilityHint;

/**
 * If false, the control will mimic a normal slider and have only one handle rather than a range.
 * In this case, the selectedMinValue will be not functional anymore. Use selectedMaxValue instead to determine the value the user has selected.
 */
@property (nonatomic, assign) BOOL enableRange;

@property (nonatomic, assign) float minDistance;

@property (nonatomic, assign) float maxDistance;

/**
 * If true the control will snap to point at each step between minValue and maxValue
 */
@property (nonatomic, assign) BOOL enableStep;

/**
 * The step value, this control the value of each step. If not set the default is 0.1.
 * (note: this is ignored if <= 0.0)
 */
@property (nonatomic, assign) float step;

/**
 *Set padding between label and handle (default 8.0)
 */
@property (nonatomic, assign) CGFloat labelPadding;

/**
 *Handle slider with custom image, you can set custom image for your handle
 */
@property (nonatomic, strong) UIImage *handleImage;

/**
 *Handle slider with custom color, you can set custom color for your handle
 */
@property (nonatomic, strong) UIColor *handleColor;

/**
 *Handle slider with custom border color, you can set custom border color for your handle
 */
@property (nonatomic, strong) UIColor *handleBorderColor;

/**
 *Handle border width (default 0.0)
 */
@property (nonatomic, assign) CGFloat handleBorderWidth;

/**
 *Handle diameter (default 16.0)
 */
@property (nonatomic, assign) CGFloat handleDiameter;

/**
 *Selected handle diameter multiplier (default 1.7)
 */
@property (nonatomic, assign) CGFloat selectedHandleDiameterMultiplier;

/**
 *Set slider line tint color between handles
 */
@property (nonatomic, strong) UIColor *tintColorBetweenHandles;

/**
 *Set the slider line height (default 1.0)
 */
@property (nonatomic, assign) CGFloat lineHeight;

@end
