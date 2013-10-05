#import <UIKit/UIKit.h>

@protocol HFImageEditorFrame
@required
@property(nonatomic,assign) CGRect cropRect;
@end

@class  HFImageEditorViewController;

typedef void(^HFImageEditorDoneCallback)(UIImage *image, BOOL canceled);

@interface HFImageEditorViewController : UIViewController<UIGestureRecognizerDelegate>

@property(nonatomic,copy) HFImageEditorDoneCallback doneCallback;
@property(nonatomic,copy) UIImage *sourceImage;
@property(nonatomic,copy) UIImage *previewImage;
@property(nonatomic,assign) CGSize cropSize;
@property(nonatomic,assign) CGRect cropRect;
@property(nonatomic,assign) CGFloat outputWidth;
@property(nonatomic,assign) CGFloat minimumScale;
@property(nonatomic,assign) CGFloat maximumScale;

@property(nonatomic,assign) BOOL panEnabled;
@property(nonatomic,assign) BOOL rotateEnabled;
@property(nonatomic,assign) BOOL scaleEnabled;
@property(nonatomic,assign) BOOL tapToResetEnabled;
@property(nonatomic,assign) BOOL checkBounds;

@property(nonatomic,readonly) CGRect cropBoundsInSourceImage;

- (void)reset:(BOOL)animated;

@end


