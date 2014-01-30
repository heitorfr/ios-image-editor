#import "HFImageEditorViewController.h"
#import <QuartzCore/QuartzCore.h>


typedef struct {
    CGPoint tl,tr,bl,br;
} Rectangle;


static const CGFloat kMaxUIImageSize = 1024;
static const CGFloat kPreviewImageSize = 120;
static const CGFloat kDefaultCropWidth = 320;
static const CGFloat kDefaultCropHeight = 320;
static const CGFloat kBoundingBoxInset = 15;
static const NSTimeInterval kAnimationIntervalReset = 0.25;
static const NSTimeInterval kAnimationIntervalTransform = 0.2;


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - HFImageEditorViewController
////////////////////////////////////////////////////////////////////////////////////////////////////
@interface HFImageEditorViewController ()
@property (nonatomic,strong) UIPanGestureRecognizer *panRecognizer;
@property (nonatomic,strong) UIRotationGestureRecognizer *rotationRecognizer;
@property (nonatomic,strong) UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic,strong) UITapGestureRecognizer *tapRecognizer;
@property (nonatomic,weak) UIImageView *imageView;
@property (nonatomic,weak) IBOutlet UIView<HFImageEditorFrame> *frameView;

@property(nonatomic,assign) NSUInteger gestureCount;
@property(nonatomic,assign) CGPoint touchCenter;
@property(nonatomic,assign) CGPoint rotationCenter;
@property(nonatomic,assign) CGPoint scaleCenter;
@property(nonatomic,assign) CGFloat scale;

@property(nonatomic, assign) CGRect initialImageFrame;
@property(nonatomic, assign) CGAffineTransform validTransform;

@end



@implementation HFImageEditorViewController

@dynamic cropBoundsInSourceImage;
@dynamic cropRect;
@dynamic cropSize;

@synthesize tapToResetEnabled = _tapToResetEnabled;
@synthesize panEnabled = _panEnabled;
@synthesize scaleEnabled = _scaleEnabled;
@synthesize rotateEnabled = _rotateEnabled;


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Initialization
////////////////////////////////////////////////////////////////////////////////////////////////////
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        [self commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit
{
    self.tapToResetEnabled = YES;
    self.panEnabled = YES;
    self.scaleEnabled = YES;
    self.rotateEnabled = YES;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -Properties
////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)setCropRect:(CGRect)cropRect
{
    self.frameView.cropRect = cropRect;
}

- (CGRect)cropRect
{
    if(self.frameView.cropRect.size.width == 0 || self.frameView.cropRect.size.height == 0) {
        self.frameView.cropRect = CGRectMake((self.frameView.bounds.size.width-kDefaultCropWidth)/2,
                                             (self.frameView.bounds.size.height-kDefaultCropHeight)/2,
                                             kDefaultCropWidth,kDefaultCropHeight);
    }
    return self.frameView.cropRect;
}

- (void)setCropSize:(CGSize)cropSize
{
    self.cropRect = CGRectMake((self.frameView.bounds.size.width-cropSize.width)/2,
                               (self.frameView.bounds.size.height-cropSize.height)/2,
                               cropSize.width,cropSize.height);
}

- (CGSize)cropSize
{
    return self.frameView.cropRect.size;
}

- (UIImage *)previewImage
{
    if(_previewImage == nil && _sourceImage != nil) {
        if(self.sourceImage.size.height > kMaxUIImageSize || self.sourceImage.size.width > kMaxUIImageSize) {
            CGFloat aspect = self.sourceImage.size.height/self.sourceImage.size.width;
            CGSize size;
            if(aspect >= 1.0) { //square or portrait
                size = CGSizeMake(kPreviewImageSize,kPreviewImageSize*aspect);
            } else { // landscape
                size = CGSizeMake(kPreviewImageSize,kPreviewImageSize*aspect);
            }
            _previewImage = [self scaledImage:self.sourceImage  toSize:size withQuality:kCGInterpolationLow];
        } else {
            _previewImage = _sourceImage;
        }
    }
    return  _previewImage;
}

- (void)setSourceImage:(UIImage *)sourceImage
{
    if(sourceImage != _sourceImage) {
        _sourceImage = sourceImage;
        self.previewImage = nil;
    }
}




- (void)setPanEnabled:(BOOL)panEnabled
{
    _panEnabled = panEnabled;
    self.panRecognizer.enabled = panEnabled;
}


- (void)setScaleEnabled:(BOOL)scaleEnabled
{
    _scaleEnabled = scaleEnabled;
    self.pinchRecognizer.enabled = scaleEnabled;
}

- (void)setRotateEnabled:(BOOL)rotateEnabled
{
    _rotateEnabled = rotateEnabled;
    self.rotationRecognizer.enabled = rotateEnabled;
}

- (void)setTapToResetEnabled:(BOOL)tapToResetEnabled
{
    _tapToResetEnabled = tapToResetEnabled;
    self.tapRecognizer.enabled = tapToResetEnabled;
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////
-(void)reset:(BOOL)animated
{
    CGFloat w = 0.0f;
    CGFloat h = 0.0f;
    CGFloat sourceAspect = self.sourceImage.size.height/self.sourceImage.size.width;
    CGFloat cropAspect = self.cropRect.size.height/self.cropRect.size.width;
    
    if(sourceAspect > cropAspect) {
        w = CGRectGetWidth(self.cropRect);
        h = sourceAspect * w;
    } else {
        h = CGRectGetHeight(self.cropRect);
        w = h / sourceAspect;
    }
    self.scale = 1;
    if(self.checkBounds) {
        self.minimumScale = 1;
    }
    self.initialImageFrame = CGRectMake(CGRectGetMidX(self.cropRect) - w/2, CGRectGetMidY(self.cropRect) - h/2,w,h);
    self.validTransform = CGAffineTransformMakeScale(self.scale, self.scale);
    
    void (^doReset)(void) = ^{
        self.imageView.transform = CGAffineTransformIdentity;
        self.imageView.frame = self.initialImageFrame;
        self.imageView.transform = self.validTransform;
    };
    if(animated) {
        self.view.userInteractionEnabled = NO;
        [UIView animateWithDuration:kAnimationIntervalReset animations:doReset completion:^(BOOL finished) {
            self.view.userInteractionEnabled = YES;
        }];
    } else {
        doReset();
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark View Lifecycle
////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.layer.masksToBounds = YES;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    [self.view insertSubview:imageView belowSubview:self.frameView];
    self.imageView = imageView;
    
    [self.view setMultipleTouchEnabled:YES];

    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panRecognizer.cancelsTouchesInView = NO;
    panRecognizer.delegate = self;
    panRecognizer.enabled = self.panEnabled;
    [self.frameView addGestureRecognizer:panRecognizer];
    self.panRecognizer = panRecognizer;

    UIRotationGestureRecognizer *rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
    rotationRecognizer.cancelsTouchesInView = NO;
    rotationRecognizer.delegate = self;
    rotationRecognizer.enabled = self.rotateEnabled;
    [self.frameView addGestureRecognizer:rotationRecognizer];
    self.rotationRecognizer = rotationRecognizer;

    UIPinchGestureRecognizer *pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
    pinchRecognizer.cancelsTouchesInView = NO;
    pinchRecognizer.delegate = self;
    pinchRecognizer.enabled = self.scaleEnabled;
    [self.frameView addGestureRecognizer:pinchRecognizer];
    self.pinchRecognizer = pinchRecognizer;

    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    tapRecognizer.numberOfTapsRequired = 2;
    tapRecognizer.enabled = self.tapToResetEnabled;
    [self.frameView addGestureRecognizer:tapRecognizer];
    self.tapRecognizer = tapRecognizer;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self reset:NO];
    self.imageView.image = self.previewImage;
    
    if(self.previewImage != self.sourceImage) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            CGImageRef hiresCGImage = NULL;
            CGFloat aspect = self.sourceImage.size.height/self.sourceImage.size.width;
            CGSize size;
            if(aspect >= 1.0) { //square or portrait
                size = CGSizeMake(kMaxUIImageSize*aspect,kMaxUIImageSize);
            } else { // landscape
                size = CGSizeMake(kMaxUIImageSize,kMaxUIImageSize*aspect);
            }
            hiresCGImage = [self newScaledImage:self.sourceImage.CGImage withOrientation:self.sourceImage.imageOrientation toSize:size withQuality:kCGInterpolationDefault];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = [UIImage imageWithCGImage:hiresCGImage scale:1.0 orientation:UIImageOrientationUp];
                CGImageRelease(hiresCGImage);
            });
        });
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Actions
////////////////////////////////////////////////////////////////////////////////////////////////////
- (IBAction)resetAction:(id)sender
{
    [self reset:NO];
}

- (IBAction)resetAnimatedAction:(id)sender
{
    [self reset:YES];
}


- (IBAction)doneAction:(id)sender
{
    self.view.userInteractionEnabled = NO;
    [self startTransformHook];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGImageRef resultRef = [self newTransformedImage:self.imageView.transform
                                        sourceImage:self.sourceImage.CGImage
                                         sourceSize:self.sourceImage.size
                                  sourceOrientation:self.sourceImage.imageOrientation
                                        outputWidth:self.outputWidth ? self.outputWidth : self.sourceImage.size.width
                                            cropRect:self.cropRect
                                    imageViewSize:self.imageView.bounds.size];
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImage *transform =  [UIImage imageWithCGImage:resultRef scale:1.0 orientation:UIImageOrientationUp];
            CGImageRelease(resultRef);
            self.view.userInteractionEnabled = YES;
            if(self.doneCallback) {
                self.doneCallback(transform, NO);
            }
            [self endTransformHook];
        });
    });

}


- (IBAction)cancelAction:(id)sender
{
    if(self.doneCallback) {
        self.doneCallback(nil, YES);
    }
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Touches
////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)handleTouches:(NSSet*)touches
{
    self.touchCenter = CGPointZero;
    if(touches.count < 2) return;
    
    [touches enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        UITouch *touch = (UITouch*)obj;
        CGPoint touchLocation = [touch locationInView:self.imageView];
        self.touchCenter = CGPointMake(self.touchCenter.x + touchLocation.x, self.touchCenter.y +touchLocation.y);
    }];
    self.touchCenter = CGPointMake(self.touchCenter.x/touches.count, self.touchCenter.y/touches.count);
}

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouches:[event allTouches]];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    [self handleTouches:[event allTouches]];
}

-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
   [self handleTouches:[event allTouches]];
}

-(void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
   [self handleTouches:[event allTouches]];
}

#pragma mark Gestures

- (CGFloat)boundedScale:(CGFloat)scale;
{
    CGFloat boundedScale = scale;
    if(self.minimumScale > 0 && scale < self.minimumScale) {
        boundedScale = self.minimumScale;
    } else if(self.maximumScale > 0 && scale > self.maximumScale) {
        boundedScale = self.maximumScale;
    }
    return boundedScale;
}

- (BOOL)handleGestureState:(UIGestureRecognizerState)state
{
    BOOL handle = YES;
    switch (state) {
        case UIGestureRecognizerStateBegan:
            self.gestureCount++;
            break;
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateEnded: {
            self.gestureCount--;
            handle = NO;
            if(self.gestureCount == 0) {
                CGFloat scale = [self boundedScale:self.scale];
                if(scale != self.scale) {
                    CGFloat deltaX = self.scaleCenter.x-self.imageView.bounds.size.width/2.0;
                    CGFloat deltaY = self.scaleCenter.y-self.imageView.bounds.size.height/2.0;
                    
                    CGAffineTransform transform =  CGAffineTransformTranslate(self.imageView.transform, deltaX, deltaY);
                    transform = CGAffineTransformScale(transform, scale/self.scale , scale/self.scale);
                    transform = CGAffineTransformTranslate(transform, -deltaX, -deltaY);
                    [self checkBoundsWithTransform:transform];
                    self.view.userInteractionEnabled = NO;
                    [UIView animateWithDuration:kAnimationIntervalTransform delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        self.imageView.transform = self.validTransform;
                    } completion:^(BOOL finished) {
                        self.view.userInteractionEnabled = YES;
                        self.scale = scale;
                    }];
                    
                } else {
                    self.view.userInteractionEnabled = NO;
                    [UIView animateWithDuration:kAnimationIntervalTransform delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        self.imageView.transform = self.validTransform;
                    } completion:^(BOOL finished) {
                        self.view.userInteractionEnabled = YES;
                    }];

                    self.imageView.transform = self.validTransform;
                }
            }
        } break;
        default:
            break;
    }
    return handle;
}


- (void)checkBoundsWithTransform:(CGAffineTransform)transform
{
    if(!self.checkBounds) {
        self.validTransform = transform;
        return;
    }
    CGRect r1 = [self boundingBoxForRect:self.cropRect rotatedByRadians:[self imageRotation]];
    Rectangle r2 = [self applyTransform:transform toRect:self.initialImageFrame];
    
    CGAffineTransform t = CGAffineTransformMakeTranslation(CGRectGetMidX(self.cropRect), CGRectGetMidY(self.cropRect));
    t = CGAffineTransformRotate(t, -[self imageRotation]);
    t = CGAffineTransformTranslate(t, -CGRectGetMidX(self.cropRect), -CGRectGetMidY(self.cropRect));
    
    Rectangle r3 = [self applyTransform:t toRectangle:r2];
    
    if(CGRectContainsRect([self CGRectFromRectangle:r3],r1)) {
        self.validTransform = transform;
    }
}



- (IBAction)handlePan:(UIPanGestureRecognizer*)recognizer
{
    if([self handleGestureState:recognizer.state]) {
        CGPoint translation = [recognizer translationInView:self.imageView];
        CGAffineTransform transform = CGAffineTransformTranslate( self.imageView.transform, translation.x, translation.y);
        self.imageView.transform = transform;
        [self checkBoundsWithTransform:transform];

        [recognizer setTranslation:CGPointMake(0, 0) inView:self.frameView];
    }
}

- (IBAction)handleRotation:(UIRotationGestureRecognizer*)recognizer
{
    if([self handleGestureState:recognizer.state]) {
        if(recognizer.state == UIGestureRecognizerStateBegan){
            self.rotationCenter = self.touchCenter;
        } 
        CGFloat deltaX = self.rotationCenter.x-self.imageView.bounds.size.width/2;
        CGFloat deltaY = self.rotationCenter.y-self.imageView.bounds.size.height/2;

        CGAffineTransform transform =  CGAffineTransformTranslate(self.imageView.transform,deltaX,deltaY);
        transform = CGAffineTransformRotate(transform, recognizer.rotation);
        transform = CGAffineTransformTranslate(transform, -deltaX, -deltaY);
        self.imageView.transform = transform;
        [self checkBoundsWithTransform:transform];

        recognizer.rotation = 0;
    }

}

- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer
{
    if([self handleGestureState:recognizer.state]) {
        if(recognizer.state == UIGestureRecognizerStateBegan){
            self.scaleCenter = self.touchCenter;
        } 
        CGFloat deltaX = self.scaleCenter.x-self.imageView.bounds.size.width/2.0;
        CGFloat deltaY = self.scaleCenter.y-self.imageView.bounds.size.height/2.0;

        CGAffineTransform transform =  CGAffineTransformTranslate(self.imageView.transform, deltaX, deltaY);
        transform = CGAffineTransformScale(transform, recognizer.scale, recognizer.scale);
        transform = CGAffineTransformTranslate(transform, -deltaX, -deltaY);
        self.scale *= recognizer.scale;
        self.imageView.transform = transform;

        recognizer.scale = 1;
        
        [self checkBoundsWithTransform:transform];
    }
}

- (IBAction)handleTap:(UITapGestureRecognizer *)recogniser {
    [self reset:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}



////////////////////////////////////////////////////////////////////////////////////////////////////
# pragma mark Image Transformation
////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)transform:(CGAffineTransform*)transform andSize:(CGSize *)size forOrientation:(UIImageOrientation)orientation
{
    *transform = CGAffineTransformIdentity;
    BOOL transpose = NO;
    
    switch(orientation)
    {
        case UIImageOrientationUp:// EXIF 1
        case UIImageOrientationUpMirrored:{ // EXIF 2
        } break;
        case UIImageOrientationDown: // EXIF 3
        case UIImageOrientationDownMirrored: { // EXIF 4
            *transform = CGAffineTransformMakeRotation(M_PI);
        } break;
        case UIImageOrientationLeftMirrored: // EXIF 5
        case UIImageOrientationLeft: {// EXIF 6
            *transform = CGAffineTransformMakeRotation(M_PI_2);
            transpose = YES;
        } break;
        case UIImageOrientationRightMirrored: // EXIF 7
        case UIImageOrientationRight: { // EXIF 8
            *transform = CGAffineTransformMakeRotation(-M_PI_2);
            transpose = YES;
        } break;
        default:
            break;
    }
    
    if(orientation == UIImageOrientationUpMirrored || orientation == UIImageOrientationDownMirrored ||
       orientation == UIImageOrientationLeftMirrored || orientation == UIImageOrientationRightMirrored) {
        *transform = CGAffineTransformScale(*transform, -1, 1);
    }
    
    if(transpose) {
        *size = CGSizeMake(size->height, size->width);
    }
}


- (UIImage *)scaledImage:(UIImage *)source toSize:(CGSize)size withQuality:(CGInterpolationQuality)quality
{
    CGImageRef cgImage  = [self newScaledImage:source.CGImage withOrientation:source.imageOrientation toSize:size withQuality:quality];
    UIImage * result = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationUp];
    CGImageRelease(cgImage);
    return result;
}


- (CGImageRef)newScaledImage:(CGImageRef)source withOrientation:(UIImageOrientation)orientation toSize:(CGSize)size withQuality:(CGInterpolationQuality)quality
{
    CGSize srcSize = size;
    CGAffineTransform transform;
    [self transform:&transform andSize:&srcSize forOrientation:orientation];
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 size.width,
                                                 size.height,
                                                 CGImageGetBitsPerComponent(source),
                                                 0,
                                                 CGImageGetColorSpace(source),
                                                 CGImageGetBitmapInfo(source)
                                                 );
    
    CGContextSetInterpolationQuality(context, quality);
    CGContextTranslateCTM(context,  size.width/2,  size.height/2);
    CGContextConcatCTM(context, transform);
    
    CGContextDrawImage(context, CGRectMake(-srcSize.width/2 ,
                                           -srcSize.height/2,
                                           srcSize.width,
                                           srcSize.height),
                       source);
    
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);

    return resultRef;
}

- (CGImageRef)newTransformedImage:(CGAffineTransform)transform
                     sourceImage:(CGImageRef)sourceImage
                    sourceSize:(CGSize)sourceSize
           sourceOrientation:(UIImageOrientation)sourceOrientation
                 outputWidth:(CGFloat)outputWidth
                    cropRect:(CGRect)cropRect
               imageViewSize:(CGSize)imageViewSize
{
    CGImageRef source = sourceImage;
    
    CGAffineTransform orientationTransform;
    [self transform:&orientationTransform andSize:&imageViewSize forOrientation:sourceOrientation];
    
    CGFloat aspect = cropRect.size.height/cropRect.size.width;
    CGSize outputSize = CGSizeMake(outputWidth, outputWidth*aspect);
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 outputSize.width,
                                                 outputSize.height,
                                                 CGImageGetBitsPerComponent(source),
                                                 0,
                                                 CGImageGetColorSpace(source),
                                                 CGImageGetBitmapInfo(source));
    CGContextSetFillColorWithColor(context,  [[UIColor clearColor] CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, outputSize.width, outputSize.height));
    
    CGAffineTransform uiCoords = CGAffineTransformMakeScale(outputSize.width/cropRect.size.width,
                                                            outputSize.height/cropRect.size.height);
    uiCoords = CGAffineTransformTranslate(uiCoords, cropRect.size.width/2.0, cropRect.size.height/2.0);
    uiCoords = CGAffineTransformScale(uiCoords, 1.0, -1.0);
    CGContextConcatCTM(context, uiCoords);
    
    CGContextConcatCTM(context, transform);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextConcatCTM(context, orientationTransform);
    
    CGContextDrawImage(context, CGRectMake(-imageViewSize.width/2.0,
                                           -imageViewSize.height/2.0,
                                           imageViewSize.width,
                                           imageViewSize.height)
                       ,source);
    
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    return resultRef;
}

- (CGRect)cropBoundsInSourceImage
{
    CGAffineTransform uiCoords = CGAffineTransformMakeScale(self.sourceImage.size.width/self.imageView.bounds.size.width,
                                                            self.sourceImage.size.height/self.imageView.bounds.size.height);
    uiCoords = CGAffineTransformTranslate(uiCoords, self.imageView.bounds.size.width/2.0, self.imageView.bounds.size.height/2.0);
    uiCoords = CGAffineTransformScale(uiCoords, 1.0, -1.0);

    CGRect crop =  CGRectMake(-self.cropRect.size.width/2.0, -self.cropRect.size.height/2.0, self.cropRect.size.width, self.cropRect.size.height);
    return CGRectApplyAffineTransform(crop, CGAffineTransformConcat(CGAffineTransformInvert(self.imageView.transform),uiCoords));
}


////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Subclass Hooks
////////////////////////////////////////////////////////////////////////////////////////////////////
- (void)startTransformHook
{
}

- (void)endTransformHook
{
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Util
////////////////////////////////////////////////////////////////////////////////////////////////////
- (CGFloat) imageRotation
{
    CGAffineTransform t = self.imageView.transform;
    return atan2f(t.b, t.a);
}

- (CGRect)boundingBoxForRect:(CGRect)rect rotatedByRadians:(CGFloat)angle
{
    CGAffineTransform t = CGAffineTransformMakeTranslation(CGRectGetMidX(rect), CGRectGetMidY(rect));
    t = CGAffineTransformRotate(t,angle);
    t = CGAffineTransformTranslate(t,-CGRectGetMidX(rect), -CGRectGetMidY(rect));
    return CGRectApplyAffineTransform(rect, t);
}

- (Rectangle)RectangleFromCGRect:(CGRect)rect
{
    return (Rectangle) {
        .tl = (CGPoint){rect.origin.x, rect.origin.y},
        .tr = (CGPoint){CGRectGetMaxX(rect), rect.origin.y},
        .br = (CGPoint){CGRectGetMaxX(rect), CGRectGetMaxY(rect)},
        .bl = (CGPoint){rect.origin.x, CGRectGetMaxY(rect)}
    };
}

-(CGRect)CGRectFromRectangle:(Rectangle)rect
{
    return (CGRect) {
        .origin = rect.tl,
        .size = (CGSize){.width = rect.tr.x - rect.tl.x, .height = rect.bl.y - rect.tl.y}
    };
}

- (Rectangle)applyTransform:(CGAffineTransform)transform toRect:(CGRect)rect
{
    CGAffineTransform t = CGAffineTransformMakeTranslation(CGRectGetMidX(rect), CGRectGetMidY(rect));
    t = CGAffineTransformConcat(self.imageView.transform, t);
    t = CGAffineTransformTranslate(t,-CGRectGetMidX(rect), -CGRectGetMidY(rect));
    
    Rectangle r = [self RectangleFromCGRect:rect];
    return (Rectangle) {
        .tl = CGPointApplyAffineTransform(r.tl, t),
        .tr = CGPointApplyAffineTransform(r.tr, t),
        .br = CGPointApplyAffineTransform(r.br, t),
        .bl = CGPointApplyAffineTransform(r.bl, t)
    };
}

- (Rectangle)applyTransform:(CGAffineTransform)t toRectangle:(Rectangle)r
{
    return (Rectangle) {
        .tl = CGPointApplyAffineTransform(r.tl, t),
        .tr = CGPointApplyAffineTransform(r.tr, t),
        .br = CGPointApplyAffineTransform(r.br, t),
        .bl = CGPointApplyAffineTransform(r.bl, t)
    };
}



@end


