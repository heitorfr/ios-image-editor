#import "ImageEditorViewController.h"

@interface ImageEditorViewController ()
@property (nonatomic,retain) UIImageView *imageView;
@property (nonatomic,assign) CGRect cropRect;
@property (retain, nonatomic) IBOutlet UIPanGestureRecognizer *panRecognizer;
@property (retain, nonatomic) IBOutlet UIRotationGestureRecognizer *rotationRecognizer;
@property (retain, nonatomic) IBOutlet UIPinchGestureRecognizer *pinchRecognizer;

@property(nonatomic,assign) CGAffineTransform toCommitTranform;
@property(nonatomic,assign) CGFloat currentScale;
@property(nonatomic,assign) CGFloat toCommitScale;
@property(nonatomic,assign) BOOL isScaling;
@property(nonatomic,assign) NSUInteger gestureCount;
@property(nonatomic,assign) CGPoint touchCenter;
@property(nonatomic,assign) CGPoint rotationCenter;
@property(nonatomic,assign) CGPoint scaleCenter;
@property(nonatomic,assign) CGFloat scale;
@end

static const CGFloat kMaxUIImageSize = 1024;
static const CGFloat kPreviewImageSize = 120;
static const CGFloat kDefaultCropWidth = 320;
static const CGFloat kDefaultCropHeight = 320;
static const CGFloat kBoundingBoxInset = 15;
static const NSTimeInterval kAnimationIntervalReset = 0.25;
static const NSTimeInterval kAnimationIntervalTransform = 0.1;

@implementation ImageEditorViewController

@synthesize doneCallback = _doneCallback;
@synthesize sourceImage = _sourceImage;
@synthesize previewImage = _previewImage;
@synthesize cropSize = _cropSize;
@synthesize outputWidth = _outputWidth;
@synthesize frameView = _frameView;
@synthesize imageView = _imageView;
@synthesize panRecognizer = _panRecognizer;
@synthesize rotationRecognizer = _rotationRecognizer;
@synthesize pinchRecognizer = _pinchRecognizer;
@synthesize touchCenter = _touchCenter;
@synthesize rotationCenter = _rotationCenter;
@synthesize scaleCenter = _scaleCenter;
@synthesize scale = _scale;
@synthesize minimumScale = _minimumScale;
@synthesize maximumScale = _maximumScale;
@synthesize toCommitTranform = _toCommitTranform;
@synthesize currentScale = _currentScale;
@synthesize toCommitScale = _toCommitScale;
@synthesize isScaling = _isScaling;
@synthesize gestureCount = _gestureCount;

- (void) dealloc
{

    [_imageView release];
    [_frameView release];
    [_doneCallback release];
    [_sourceImage release];
    [_previewImage release];
    [_panRecognizer release];
    [_rotationRecognizer release];
    [_pinchRecognizer release];
    [super dealloc];
}

- (void)setCropSize:(CGSize)cropSize
{
    _cropSize = cropSize;
    [self updateCropRect];
}

- (CGSize)cropSize
{
    if(_cropSize.width == 0 || _cropSize.height == 0) {
        _cropSize = CGSizeMake(kDefaultCropWidth, kDefaultCropHeight);
    }
    return _cropSize;
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
            _previewImage = [[self scaleImage:self.sourceImage  toSize:size withQuality:kCGInterpolationLow] retain];
        } else {
            _previewImage = [_sourceImage retain];
        }
    }
    return  _previewImage;
}

- (void)setSourceImage:(UIImage *)sourceImage
{
    if(sourceImage != _sourceImage) {
        [_sourceImage release];
        _sourceImage = [sourceImage retain];
        self.previewImage = nil;
    }
}


- (void)updateCropRect
{
    self.cropRect = CGRectMake((self.frameView.bounds.size.width-self.cropSize.width)/2,
                               (self.frameView.bounds.size.height-self.cropSize.height)/2,
                               self.cropSize.width, self.cropSize.height);
    
    self.frameView.cropRect = self.cropRect;
}


#pragma mark View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateCropRect];
    UIImageView *imageView = [[UIImageView alloc] init];
    [self.view insertSubview:imageView belowSubview:self.frameView];
    self.imageView = imageView;
    [imageView release];
    [self reset:nil];
    
    [self.view setMultipleTouchEnabled:YES];
    
    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
    _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];

    self.panRecognizer.cancelsTouchesInView = NO;
    self.panRecognizer.delegate = self;
    [self.frameView addGestureRecognizer:self.panRecognizer];
    self.rotationRecognizer.cancelsTouchesInView = NO;
    self.rotationRecognizer.delegate = self;
    [self.frameView addGestureRecognizer:self.rotationRecognizer];
    self.pinchRecognizer.cancelsTouchesInView = NO;
    self.pinchRecognizer.delegate = self;
    [self.frameView addGestureRecognizer:self.pinchRecognizer];
}


- (void)viewDidUnload
{
    [self setPanRecognizer:nil];
    [self setRotationRecognizer:nil];
    [self setPinchRecognizer:nil];
    [self setFrameView:nil];
    [self setImageView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated
{
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
            hiresCGImage = [self scaleImage:self.sourceImage.CGImage withOrientation:self.sourceImage.imageOrientation toSize:size withQuality:kCGInterpolationDefault];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                self.imageView.image = [UIImage imageWithCGImage:hiresCGImage scale:1.0 orientation:UIImageOrientationUp];
                CGImageRelease(hiresCGImage);
            });
        });
    }
}

#pragma mark Action
-(void)doResetAnimated:(BOOL)animated
{
    // TODO disable interaction during animation?
    CGFloat aspect = self.sourceImage.size.height/self.sourceImage.size.width;
    CGFloat w = CGRectGetWidth(self.cropRect);
    CGFloat h = aspect * w;
    self.scale = 1;
    
    void (^doReset)(void) = ^{
        self.imageView.transform = CGAffineTransformIdentity;
        self.imageView.frame = CGRectMake(CGRectGetMidX(self.cropRect) - w/2, CGRectGetMidY(self.cropRect) - h/2,w,h);
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

- (IBAction)reset:(id)sender
{
    [self doResetAnimated:NO];
}

- (IBAction)resetAnimated:(id)sender
{
    [self doResetAnimated:YES];
}


- (IBAction)done:(id)sender
{
    self.view.userInteractionEnabled = NO;
    [self startTransformHook];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        CGImageRef resultRef = [self applyTransform:self.imageView.transform
                                        sourceImage:self.sourceImage.CGImage
                                         sourceSize:self.sourceImage.size
                                  sourceOrientation:self.sourceImage.imageOrientation
                                        outputWidth:self.outputWidth ? self.outputWidth : self.sourceImage.size.width
                                            cropSize:self.cropSize
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


- (IBAction)cancel:(id)sender
{
    if(self.doneCallback) {
        self.doneCallback(nil, YES);
    }
}

#pragma mark Touches

- (void)handleTouches:(NSSet*)touches
{
    self.touchCenter = CGPointZero;
    if(touches.count == 0) {
        self.imageView.transform = self.toCommitTranform;
        return;
    } 
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

- (void)beginGesture
{
    if(self.gestureCount == 0) {
        self.toCommitTranform = self.imageView.transform;
    }
    self.gestureCount++;
}

- (void)endGesture
{
    self.gestureCount--;
    if(self.gestureCount == 0) {
        self.view.userInteractionEnabled = NO;
        [UIView animateWithDuration:kAnimationIntervalTransform delay:0 options:UIViewAnimationCurveEaseOut animations:^{
            self.imageView.transform = self.toCommitTranform;

        } completion:^(BOOL finished) {
            self.view.userInteractionEnabled = YES;
        }];
    }
}

- (BOOL)handleTransform:(CGAffineTransform)transform
{
    self.imageView.transform = transform;
    BOOL valid = NO;
    if(self.isScaling && ((self.minimumScale != 0 && self.currentScale < self.minimumScale) ||
                          (self.maximumScale != 0 && self.currentScale > self.maximumScale))) {
        valid = NO;
    } else {
        CGAffineTransform t = CGAffineTransformMakeTranslation(-self.imageView.bounds.size.width/2.0, -self.imageView.bounds.size.height/2.0);
        t = CGAffineTransformConcat(t, transform);
        CGRect transformedBounds = CGRectApplyAffineTransform(self.imageView.bounds, t);
        CGRect boundsInFrame = CGRectMake(CGRectGetMinX(transformedBounds)+self.imageView.center.x,
                                          CGRectGetMinY(transformedBounds)+self.imageView.center.y,
                                          transformedBounds.size.width,
                                          transformedBounds.size.height);
        
        CGRect testBounds = (boundsInFrame.size.width > 2*kBoundingBoxInset && boundsInFrame.size.height > 2*kBoundingBoxInset) ?
        CGRectInset(boundsInFrame, kBoundingBoxInset, kBoundingBoxInset) : boundsInFrame;
        valid = (CGRectIntersectsRect(testBounds, self.cropRect));
    }
    if(valid) {
        self.toCommitTranform = transform;
    }
    return valid;
}

- (IBAction)handlePan:(UIPanGestureRecognizer*)recognizer
{

    CGPoint translation = [recognizer translationInView:self.imageView];
    CGAffineTransform transform = CGAffineTransformTranslate( self.imageView.transform, translation.x, translation.y);
    self.imageView.transform = transform;

    [recognizer setTranslation:CGPointMake(0, 0) inView:self.frameView];

}

- (IBAction)handleRotation:(UIRotationGestureRecognizer*)recognizer
{

   if(recognizer.state == UIGestureRecognizerStateBegan){
        self.rotationCenter = self.touchCenter;
    } 
    CGFloat deltaX = self.rotationCenter.x-self.imageView.bounds.size.width/2;
    CGFloat deltaY = self.rotationCenter.y-self.imageView.bounds.size.height/2;

    CGAffineTransform transform =  CGAffineTransformTranslate(self.imageView.transform,deltaX,deltaY);
    transform = CGAffineTransformRotate(transform, recognizer.rotation);
    transform = CGAffineTransformTranslate(transform, -deltaX, -deltaY);
    self.imageView.transform = transform;

    recognizer.rotation = 0;

}

- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer
{
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
     
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

# pragma mark Image Transformation


- (UIImage *)scaleImage:(UIImage *)source toSize:(CGSize)size withQuality:(CGInterpolationQuality)quality
{
    CGImageRef cgImage  = [self scaleImage:source.CGImage withOrientation:source.imageOrientation toSize:size withQuality:quality];
    UIImage * result = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationUp];
    CGImageRelease(cgImage);
    return result;
}


- (CGImageRef)scaleImage:(CGImageRef)source withOrientation:(UIImageOrientation)orientation toSize:(CGSize)size withQuality:(CGInterpolationQuality)quality
{
    CGSize srcSize = size;
    CGFloat rotation = 0.0;
    
    switch(orientation)
    {
        case UIImageOrientationUp: {
            rotation = 0;
        } break;
        case UIImageOrientationDown: {
            rotation = M_PI;
        } break;
        case UIImageOrientationLeft:{
            rotation = M_PI_2;
            srcSize = CGSizeMake(size.height, size.width);
        } break;
        case UIImageOrientationRight: {
            rotation = -M_PI_2;
            srcSize = CGSizeMake(size.height, size.width);
        } break;
        default:
            break;
    }
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 size.width,
                                                 size.height,
                                                 8, //CGImageGetBitsPerComponent(source),
                                                 0,
                                                 CGImageGetColorSpace(source),
                                                 kCGImageAlphaNoneSkipFirst//CGImageGetBitmapInfo(source)
                                                 );
    
    CGContextSetInterpolationQuality(context, quality);
    CGContextTranslateCTM(context,  size.width/2,  size.height/2);
    CGContextRotateCTM(context,rotation);
    
    CGContextDrawImage(context, CGRectMake(-srcSize.width/2 ,
                                           -srcSize.height/2,
                                           srcSize.width,
                                           srcSize.height),
                       source);
    
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);

    return resultRef;
}

- (CGImageRef)applyTransform:(CGAffineTransform)transform
                     sourceImage:(CGImageRef)sourceImage
                    sourceSize:(CGSize)sourceSize
           sourceOrientation:(UIImageOrientation)sourceOrientation
                 outputWidth:(CGFloat)outputWidth
                    cropSize:(CGSize)cropSize
               imageViewSize:(CGSize)imageViewSize
{
    CGImageRef source = [self scaleImage:sourceImage
                         withOrientation:sourceOrientation
                                  toSize:sourceSize
                             withQuality:kCGInterpolationNone];
    
    CGFloat aspect = cropSize.height/cropSize.width;
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
    
    CGAffineTransform uiCoords = CGAffineTransformMakeScale(outputSize.width/cropSize.width,
                                                            outputSize.height/cropSize.height);
    uiCoords = CGAffineTransformTranslate(uiCoords, cropSize.width/2.0, cropSize.height/2.0);
    uiCoords = CGAffineTransformScale(uiCoords, 1.0, -1.0);
    CGContextConcatCTM(context, uiCoords);
    
    CGContextConcatCTM(context, transform);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(-imageViewSize.width/2.0,
                                           -imageViewSize.height/2.0,
                                           imageViewSize.width,
                                           imageViewSize.height)
                       ,source);
    
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    return resultRef;
}

#pragma mark Subclass Hooks

- (void)startTransformHook
{
}

- (void)endTransformHook
{
}



@end
