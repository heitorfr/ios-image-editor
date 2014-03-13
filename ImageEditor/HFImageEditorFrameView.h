#import <UIKit/UIKit.h>
#import "HFImageEditorViewController.h"

@interface HFImageEditorFrameView : UIView <HFImageEditorFrame>

- (id)initWithFrame:(CGRect)frame useCircularImage:(BOOL)useCircularImage;

@end
