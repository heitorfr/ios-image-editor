#import "ImageEditorViewController.h"

@interface ImageEditorViewController ()
@property (nonatomic,retain) UIImageView *imageView;
@property (nonatomic,retain) UIImage *uiImage;
@property (nonatomic,assign) CGRect cropRect;
@property (retain, nonatomic) IBOutlet UIPanGestureRecognizer *panRecognizer;
@property (retain, nonatomic) IBOutlet UIRotationGestureRecognizer *rotationRecognizer;
@property (retain, nonatomic) IBOutlet UIPinchGestureRecognizer *pinchRecognizer;

@property(nonatomic,assign) CGPoint touchCenter;
@property(nonatomic,assign) CGPoint rotationCenter;
@property(nonatomic,assign) CGPoint scaleCenter;
@end

static const CGFloat kMaxUIImageSize = 1024;
static const CGFloat kPreviewImageSize = 120;
static const CGFloat kDefaultCropWidth = 320;
static const CGFloat kDefaultCropHeight = 320;

@implementation ImageEditorViewController

@synthesize doneCallback = _doneCallback;
@synthesize sourceImage = _sourceImage;
@synthesize previewImage = _previewImage;
@synthesize uiImage = _uiImage;
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


- (void) dealloc
{

    [_imageView release];
    [_frameView release];
    [_uiImage release];
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
            _previewImage = [self scaleImage:self.sourceImage  toSize:size withQuality:kCGInterpolationLow];
        } else {
            _previewImage = _sourceImage;
        }
    }
    return  _previewImage;
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
    self.uiImage = self.previewImage;
    self.imageView.image = self.uiImage;
    
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
                NSLog(@"Done");
                self.uiImage = [UIImage imageWithCGImage:hiresCGImage scale:1.0 orientation:UIImageOrientationUp];
                self.imageView.image = self.uiImage;
                CGImageRelease(hiresCGImage);
            });
        });
    }
}

#pragma mark Action
- (IBAction)reset:(id)sender
{
    self.imageView.transform = CGAffineTransformIdentity;
    self.imageView.image  = self.uiImage;
    self.imageView.frame = self.cropRect;
    
    CGFloat aspect = self.sourceImage.size.height/self.sourceImage.size.width;
    CGFloat w = self.imageView.frame.size.width;
    CGFloat h = aspect * w;
    self.imageView.frame = CGRectMake(self.imageView.center.x - w/2, self.imageView.center.y - h/2,w,h);
    NSLog(@"Image view frame: %@", NSStringFromCGRect(self.imageView.frame));

}


- (IBAction)done:(id)sender
{
    if(self.doneCallback) {
        self.doneCallback([self transformSourceImage], NO);
    }
}

- (IBAction)cancel:(id)sender
{
    if(self.doneCallback) {
        self.doneCallback(nil, YES);
    }
}

#pragma  mark Touch & Gestures

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



- (IBAction)handlePan:(UIPanGestureRecognizer*)recognizer
{
    CGPoint translation = [recognizer translationInView:self.imageView];
    self.imageView.transform = CGAffineTransformTranslate(self.imageView.transform, translation.x, translation.y);
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.frameView];
}

- (IBAction)handleRotation:(UIRotationGestureRecognizer*)recognizer
{

    if(recognizer.state == UIGestureRecognizerStateBegan){
        self.rotationCenter = self.touchCenter;
    }
    CGFloat deltaX = self.rotationCenter.x-self.imageView.bounds.size.width/2;
    CGFloat deltaY = self.rotationCenter.y-self.imageView.bounds.size.height/2;

    self.imageView.transform = CGAffineTransformTranslate(self.imageView.transform,deltaX,deltaY);
    self.imageView.transform = CGAffineTransformRotate(self.imageView.transform, recognizer.rotation);
    self.imageView.transform = CGAffineTransformTranslate(self.imageView.transform, -deltaX, -deltaY);
                                                          
     recognizer.rotation = 0;

}

- (IBAction)handlePinch:(UIPinchGestureRecognizer *)recognizer
{
    
    if(recognizer.state == UIGestureRecognizerStateBegan){
        self.scaleCenter = self.touchCenter;
    }

    CGFloat deltaX = self.scaleCenter.x-self.imageView.bounds.size.width/2.0;
    CGFloat deltaY = self.scaleCenter.y-self.imageView.bounds.size.height/2.0;

    self.imageView.transform =  CGAffineTransformTranslate(self.imageView.transform, deltaX, deltaY);
    self.imageView.transform = CGAffineTransformScale(self.imageView.transform , recognizer.scale, recognizer.scale);
    self.imageView.transform = CGAffineTransformTranslate(self.imageView.transform, -deltaX, -deltaY);

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


- (UIImage *)transformSourceImage
{
    // Tranform image to up orientation
    UIImage* source  = [self scaleImage:self.sourceImage toSize:self.sourceImage.size withQuality:kCGInterpolationNone];
    
    CGAffineTransform transform = self.imageView.transform;
    CGFloat aspect = self.cropRect.size.height/self.cropRect.size.width;
    CGFloat outputWidth = self.outputWidth ? self.outputWidth : self.sourceImage.size.width;
    CGSize outputSize = CGSizeMake(outputWidth, outputWidth*aspect);
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 outputSize.width,
                                                 outputSize.height,
                                                 CGImageGetBitsPerComponent(source.CGImage),
                                                 0,
                                                 CGImageGetColorSpace(source.CGImage),
                                                 CGImageGetBitmapInfo(source.CGImage));
    CGContextSetFillColorWithColor(context,  [[UIColor clearColor] CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, outputSize.width, outputSize.height));
    
    CGSize imageViewSize = self.imageView.bounds.size;
    CGSize cropRectSize  = self.cropRect.size;

    CGAffineTransform uiCoords = CGAffineTransformMakeScale(outputSize.width/cropRectSize.width,
                                                            outputSize.height/cropRectSize.height);
    uiCoords = CGAffineTransformTranslate(uiCoords, cropRectSize.width/2.0, cropRectSize.height/2.0);
    uiCoords = CGAffineTransformScale(uiCoords, 1.0, -1.0);
    CGContextConcatCTM(context, uiCoords);
    
    CGContextConcatCTM(context, transform);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(-imageViewSize.width/2.0,
                                           -imageViewSize.height/2.0,
                                           imageViewSize.width,
                                           imageViewSize.height)
                       ,source.CGImage);
    
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    UIImage *result = [UIImage imageWithCGImage:resultRef scale:1.0 orientation:UIImageOrientationUp];
    
    CGContextRelease(context);
    CGImageRelease(resultRef);

    return result;
}


@end
