#import <UIKit/UIKit.h>

@protocol HFImageEditorFrame
@required
@property(nonatomic,assign) CGRect cropRect;
@end

@class  HFImageEditorViewController;

typedef void(^HFImageEditorDoneCallback)(UIImage *image, BOOL canceled);

@interface HFImageEditorViewController : UIViewController<UIGestureRecognizerDelegate>

@property (nonatomic, assign) IBOutlet UIView<HFImageEditorFrame> *frameView;
@property (nonatomic, strong) HFImageEditorDoneCallback doneCallback;
@property (nonatomic, strong) UIImage *sourceImage;
@property (nonatomic, strong) UIImage *previewImage;
@property (nonatomic) CGRect cropRect;
@property (nonatomic) CGSize cropSize;
@property (nonatomic) CGFloat outputWidth;
@property (nonatomic) CGFloat minimumScale;
@property (nonatomic) CGFloat maximumScale;

@property (nonatomic) BOOL panEnabled;
@property (nonatomic) BOOL rotateEnabled;
@property (nonatomic) BOOL scaleEnabled;
@property (nonatomic) BOOL tapToResetEnabled;
@property (nonatomic) BOOL checkBounds;

@property (nonatomic, readonly) CGRect cropBoundsInSourceImage;

@property (nonatomic, strong) UIImage *imageForBuilder;
@property (nonatomic, strong) CDTheme *theme;
@property (nonatomic) BOOL isLockscreen;

- (void)resetImage:(BOOL)animated;

- (void)doneAction;
- (void)doneActionWithAdditionalPadding:(CGSize)padding;

@end


