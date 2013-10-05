#import "HFImageEditorViewController.h"

@interface HFImageEditorViewController (Private)

@property (nonatomic,retain) IBOutlet UIView<HFImageEditorFrame> *frameView;

- (void)startTransformHook;
- (void)endTransformHook;

@end


