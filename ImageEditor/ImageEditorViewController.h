#import <UIKit/UIKit.h>
#import "ImageEditorCropView.h"

@class  ImageEditorViewController;

typedef void(^ImageEditorDoneCallback)(UIImage *image, BOOL canceled);

@interface ImageEditorViewController : UIViewController<UIGestureRecognizerDelegate>

@property(nonatomic,copy) ImageEditorDoneCallback doneCallback;
@property(nonatomic,copy) UIImage *sourceImage;

@property (nonatomic,retain) IBOutlet UIImageView *imageView;
@property (nonatomic,retain) IBOutlet ImageEditorCropView *cropView;

- (IBAction)done:(id)sender;
- (IBAction)reset:(id)sender;
- (IBAction)cancel:(id)sender;

@end

