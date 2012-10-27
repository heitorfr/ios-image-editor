#import <UIKit/UIKit.h>
#import "ImageEditorCropView.h"

@class  ImageEditorViewController;

typedef void(^ImageEditorDoneCallback)(UIImage *image, BOOL canceled);

@interface ImageEditorViewController : UIViewController<UIGestureRecognizerDelegate>

@property(nonatomic,copy) ImageEditorDoneCallback doneCallback;
@property(nonatomic,copy) UIImage *sourceImage;
@property(nonatomic,assign) CGFloat cropWidth;
@property(nonatomic,assign) CGFloat cropHeight;
@property(nonatomic,assign) CGFloat outputWidth;

@property (nonatomic,retain) IBOutlet UIView *frameView;

- (IBAction)done:(id)sender;
- (IBAction)reset:(id)sender;
- (IBAction)cancel:(id)sender;

@end

