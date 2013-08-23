#import "HFImageEditorViewController.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat kMaxUIImageSize = 1024;
static const CGFloat kPreviewImageSize = 120;
static const CGFloat kDefaultCropWidth = 320;
static const CGFloat kDefaultCropHeight = 320;
static const CGFloat kBoundingBoxInset = 15;
static const NSTimeInterval kAnimationIntervalReset = 0.25;
static const NSTimeInterval kAnimationIntervalTransform = 0.2;

@interface HFImageEditorViewController ()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIPanGestureRecognizer *panRecognizer;
@property (nonatomic, strong) IBOutlet UIRotationGestureRecognizer *rotationRecognizer;
@property (nonatomic, strong) IBOutlet UIPinchGestureRecognizer *pinchRecognizer;
@property (nonatomic, strong) IBOutlet UITapGestureRecognizer *tapRecognizer;

@property(nonatomic) NSUInteger gestureCount;
@property(nonatomic) CGPoint touchCenter;
@property(nonatomic) CGPoint rotationCenter;
@property(nonatomic) CGPoint scaleCenter;
@property(nonatomic) CGFloat scale;

@end

@implementation HFImageEditorViewController

@synthesize cropRect = _cropRect;
@synthesize previewImage = _previewImage;

@dynamic panEnabled;
@dynamic rotateEnabled;
@dynamic scaleEnabled;
@dynamic tapToResetEnabled;
@dynamic cropBoundsInSourceImage;

-(void)awakeFromNib {
	[super awakeFromNib];

	_panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
	_rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
	_pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
	_tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
}

- (void) dealloc {
#if !__has_feature(objc_arc)
    [_imageView release];
    [_frameView release];
    [_doneCallback release];
    [_sourceImage release];
    [_previewImage release];
    [_panRecognizer release];
    [_rotationRecognizer release];
    [_pinchRecognizer release];
    [_tapRecognizer release];
    [super dealloc];
#else
    _imageView = nil;
    _frameView = nil;
    _doneCallback = nil;
    _sourceImage = nil;
    _previewImage = nil;
    _panRecognizer = nil;
    _rotationRecognizer = nil;
    _pinchRecognizer = nil;
    _tapRecognizer = nil;
#endif
}

#pragma mark Properties

-(void)setCropRect:(CGRect)cropRect {
	_cropRect = cropRect;
	[self updateCropRect];
}

- (void)setCropSize:(CGSize)cropSize {
	CGRect r = (CGRect) {
		.origin = CGPointZero,
		.size = cropSize
	};

	[self setCropRect:r];
}

- (CGSize)cropSize {
    if(_cropRect.size.width == 0 || _cropRect.size.height == 0) {
		[self setCropSize:CGSizeMake(kDefaultCropWidth, kDefaultCropHeight)];
    }

    return self.cropRect.size;
}

- (CGRect)cropRect {
	if (CGRectEqualToRect(_cropRect, CGRectZero)) {
		self.cropRect = CGRectMake((self.frameView.bounds.size.width-self.cropSize.width)/2,
								   (self.frameView.bounds.size.height-self.cropSize.height)/2,
								   self.cropSize.width, self.cropSize.height);

	}

	return _cropRect;
}

- (UIImage *)previewImage {
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
#if !__has_feature(objc_arc)
				[_previewImage retain];
#endif
			
        } else {
            _previewImage = _sourceImage;
#if !__has_feature(objc_arc)
				[_previewImage retain];
#endif
        }
    }
    return  _previewImage;
}

-(void)setPreviewImage:(UIImage *)previewImage {
    if(previewImage != _previewImage) {
#if !__has_feature(objc_arc)
        [_previewImage release];
		[previewImage retain]
#endif
        _previewImage = previewImage;
		[self setupImageViews];
    }
}

- (void)setSourceImage:(UIImage *)sourceImage {
    if(sourceImage != _sourceImage) {
#if !__has_feature(objc_arc)
        [_sourceImage release];
		[sourceImage retain];
#endif
        _sourceImage = sourceImage;
        self.previewImage = nil;
		[self setupImageViews];
    }
}

- (void)updateCropRect {
    self.frameView.cropRect = self.cropRect;
}

- (void)setPanEnabled:(BOOL)panEnabled {
    self.panRecognizer.enabled = panEnabled;
}

- (BOOL)panEnabled {
    return self.panRecognizer.enabled;
}

- (void)setScaleEnabled:(BOOL)scaleEnabled {
    self.pinchRecognizer.enabled = scaleEnabled;
}

- (BOOL)scaleEnabled {
    return self.pinchRecognizer.enabled;
}


- (void)setRotateEnabled:(BOOL)rotateEnabled {
    self.rotationRecognizer.enabled = rotateEnabled;
}

- (BOOL)rotateEnabled {
    return self.rotationRecognizer.enabled;
}

- (void)setTapToResetEnabled:(BOOL)tapToResetEnabled {
    self.tapRecognizer.enabled = tapToResetEnabled;
}

- (BOOL)tapToResetEnabled {
    return self.tapToResetEnabled;
}

#pragma mark -
-(void)resetImage:(BOOL)animated {
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
    
    void (^doReset)(void) = ^{
        self.imageView.transform = CGAffineTransformIdentity;
        self.imageView.frame = CGRectMake(CGRectGetMidX(self.cropRect) - w/2, CGRectGetMidY(self.cropRect) - h/2,w,h);
        self.imageView.transform = CGAffineTransformMakeScale(self.scale, self.scale);
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

#pragma mark View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.layer.masksToBounds = YES;
    
    UIImageView *imageView = [[UIImageView alloc] init];
    [self.view insertSubview:imageView belowSubview:self.frameView];
    self.imageView = imageView;
#if !__has_feature(objc_arc)
    [imageView release];
#endif
    
    [self.view setMultipleTouchEnabled:YES];

    self.panRecognizer.cancelsTouchesInView = NO;
    self.panRecognizer.delegate = self;
    [self.frameView addGestureRecognizer:self.panRecognizer];
    self.rotationRecognizer.cancelsTouchesInView = NO;
    self.rotationRecognizer.delegate = self;
    [self.frameView addGestureRecognizer:self.rotationRecognizer];
    self.pinchRecognizer.cancelsTouchesInView = NO;
    self.pinchRecognizer.delegate = self;
    [self.frameView addGestureRecognizer:self.pinchRecognizer];
    self.tapRecognizer.numberOfTapsRequired = 2;
    [self.frameView addGestureRecognizer:self.tapRecognizer];
}


- (void)viewDidUnload {
    [super viewDidUnload];
    
    [self setFrameView:nil];
    [self setImageView:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

	[self setupImageViews];
}

-(void)setupImageViews {
    [self updateCropRect];

	if (self.previewImage && self.sourceImage) {
		[self resetImage:NO];

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
				hiresCGImage = [[self class] newScaledImage:self.sourceImage.CGImage withOrientation:self.sourceImage.imageOrientation toSize:size withQuality:kCGInterpolationDefault];

				dispatch_async(dispatch_get_main_queue(), ^{
					self.imageView.image = [UIImage imageWithCGImage:hiresCGImage scale:1.0 orientation:UIImageOrientationUp];
					CGImageRelease(hiresCGImage);
				});
			});
		}
	}
}

#pragma mark Actions

- (void)doneAction {
	[self doneActionWithAdditionalPadding:CGSizeZero];
}

- (void)doneActionWithAdditionalPadding:(CGSize)padding {
    self.view.userInteractionEnabled = NO;
    [self startTransformHook];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		CGSize s = self.cropSize;
//		is this needed?
//		s.width += padding.width;
//		s.height += padding.height;

        CGImageRef resultRef = [[self class] newTransformedImage:self.imageView.transform
                                        sourceImage:self.sourceImage.CGImage
                                         sourceSize:self.sourceImage.size
                                  sourceOrientation:self.sourceImage.imageOrientation
                                        outputWidth:self.outputWidth ? self.outputWidth : self.sourceImage.size.width
                                            cropSize:s
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

- (void)cancelAction {
    if(self.doneCallback) {
        self.doneCallback(nil, YES);
    }
}

#pragma mark Touches

- (void)handleTouches:(NSSet*)touches {
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

- (CGFloat)boundedScale:(CGFloat)scale; {
    CGFloat boundedScale = scale;
    if(self.minimumScale > 0 && scale < self.minimumScale) {
        boundedScale = self.minimumScale;
    } else if(self.maximumScale > 0 && scale > self.maximumScale) {
        boundedScale = self.maximumScale;
    }
    return boundedScale;
}

- (BOOL)handleGestureState:(UIGestureRecognizerState)state {
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
                    self.view.userInteractionEnabled = NO;
                    [UIView animateWithDuration:kAnimationIntervalTransform delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        self.imageView.transform = transform;            
                    } completion:^(BOOL finished) {
                        self.view.userInteractionEnabled = YES;
                        self.scale = scale;
                    }];
                    
                }
                if(self.checkBounds) [self doCheckBounds];
            }
        } break;
        default:
            break;
    }
    return handle;
}

-(void)doCheckBounds {
    CGFloat yOffset = 0;
    CGFloat xOffset = 0;
    
    if(self.imageView.frame.origin.x > self.cropRect.origin.x){
        xOffset =  - (self.imageView.frame.origin.x - self.cropRect.origin.x);
        CGFloat newRightX = CGRectGetMaxX(self.imageView.frame) + xOffset;
        if(newRightX < CGRectGetMaxX(self.cropRect)) {
            xOffset =  CGRectGetMaxX(self.cropRect) - CGRectGetMaxX(self.imageView.frame);
        }
    } else if(CGRectGetMaxX(self.imageView.frame) < CGRectGetMaxX(self.cropRect)){
        xOffset = CGRectGetMaxX(self.cropRect) - CGRectGetMaxX(self.imageView.frame);
        CGFloat newLeftX = self.imageView.frame.origin.x + xOffset;
        if(newLeftX > self.cropRect.origin.x) {
            xOffset = self.cropRect.origin.x - self.imageView.frame.origin.x;
        }
    }
    if (self.imageView.frame.origin.y > self.cropRect.origin.y) {
        yOffset = - (self.imageView.frame.origin.y - self.cropRect.origin.y);
        CGFloat newBottomY = CGRectGetMaxY(self.imageView.frame) + yOffset;
        if(newBottomY < CGRectGetMaxY(self.cropRect)) {
            yOffset = CGRectGetMaxY(self.cropRect) - CGRectGetMaxY(self.imageView.frame);
        }
    } else if(CGRectGetMaxY(self.imageView.frame) < CGRectGetMaxY(self.cropRect)){
        yOffset = CGRectGetMaxY(self.cropRect) - CGRectGetMaxY(self.imageView.frame);
        CGFloat newTopY = self.imageView.frame.origin.y + yOffset;
        if(newTopY > self.cropRect.origin.y) {
            yOffset = self.cropRect.origin.y - self.imageView.frame.origin.y;
        }
    }   
    if(xOffset || yOffset){
        self.view.userInteractionEnabled = NO;
        CGAffineTransform transform =
        CGAffineTransformTranslate(self.imageView.transform,
                                   xOffset/self.scale, yOffset/self.scale);
        [UIView animateWithDuration:kAnimationIntervalTransform delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.imageView.transform = transform;
        } completion:^(BOOL finished) {
            self.view.userInteractionEnabled = YES;
        }];
    }
}

- (void)handlePan:(UIPanGestureRecognizer*)recognizer {
    if([self handleGestureState:recognizer.state]) {
        CGPoint translation = [recognizer translationInView:self.imageView];
        CGAffineTransform transform = CGAffineTransformTranslate( self.imageView.transform, translation.x, translation.y);
        self.imageView.transform = transform;

        [recognizer setTranslation:CGPointMake(0, 0) inView:self.frameView];
    }

}

- (void)handleRotation:(UIRotationGestureRecognizer*)recognizer {
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

        recognizer.rotation = 0;
    }

}

- (void)handlePinch:(UIPinchGestureRecognizer *)recognizer {
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
    }
}

- (void)handleTap:(UITapGestureRecognizer *)recogniser {
    [self resetImage:YES];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

# pragma mark Image Transformation


- (UIImage *)scaledImage:(UIImage *)source toSize:(CGSize)size withQuality:(CGInterpolationQuality)quality {
    CGImageRef cgImage  = [[self class] newScaledImage:source.CGImage withOrientation:source.imageOrientation toSize:size withQuality:quality];
    UIImage * result = [UIImage imageWithCGImage:cgImage scale:1.0 orientation:UIImageOrientationUp];
    CGImageRelease(cgImage);
    return result;
}


+ (CGImageRef)newScaledImage:(CGImageRef)source withOrientation:(UIImageOrientation)orientation toSize:(CGSize)size withQuality:(CGInterpolationQuality)quality {
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
                                                 CGImageGetBitsPerComponent(source), //8,
                                                 0,
                                                 CGImageGetColorSpace(source),
                                                 CGImageGetBitmapInfo(source) //kCGImageAlphaNoneSkipFirst
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

+ (CGImageRef)newTransformedImage:(CGAffineTransform)transform
                     sourceImage:(CGImageRef)sourceImage
                    sourceSize:(CGSize)sourceSize
           sourceOrientation:(UIImageOrientation)sourceOrientation
                 outputWidth:(CGFloat)outputWidth
                    cropSize:(CGSize)cropSize
               imageViewSize:(CGSize)imageViewSize
{
    CGImageRef source = [self newScaledImage:sourceImage
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
    CGImageRelease(source);
    return resultRef;
}

- (CGRect)cropBoundsInSourceImage {
    CGAffineTransform uiCoords = CGAffineTransformMakeScale(self.sourceImage.size.width/self.imageView.bounds.size.width,
                                                            self.sourceImage.size.height/self.imageView.bounds.size.height);
    uiCoords = CGAffineTransformTranslate(uiCoords, self.imageView.bounds.size.width/2.0, self.imageView.bounds.size.height/2.0);
    uiCoords = CGAffineTransformScale(uiCoords, 1.0, -1.0);

    CGRect crop =  CGRectMake(-self.cropSize.width/2.0, -self.cropSize.height/2.0, self.cropSize.width, self.cropSize.height);
    return CGRectApplyAffineTransform(crop, CGAffineTransformConcat(CGAffineTransformInvert(self.imageView.transform),uiCoords));
}


#pragma mark Subclass Hooks

- (void)startTransformHook {}

- (void)endTransformHook {}

@end
