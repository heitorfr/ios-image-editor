#import <UIKit/UIKit.h>

@protocol ImageEditorFrameView
@required
@property(nonatomic,assign) CGRect cropRect;
@end

@class  ImageEditorViewController;

typedef void(^ImageEditorDoneCallback)(UIImage *image, BOOL canceled);

@interface ImageEditorViewController : UIViewController<UIGestureRecognizerDelegate>

@property(nonatomic,copy) ImageEditorDoneCallback doneCallback;
@property(nonatomic,copy) UIImage *sourceImage;
@property(nonatomic,assign) CGSize cropSize;
@property(nonatomic,assign) CGFloat outputWidth;

@property (nonatomic,retain) IBOutlet UIView<ImageEditorFrameView> *frameView;

- (IBAction)done:(id)sender;
- (IBAction)reset:(id)sender;
- (IBAction)cancel:(id)sender;

@end

