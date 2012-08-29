#import "ImageEditorViewController.h"

@interface ImageEditorViewController ()
@property (retain, nonatomic) IBOutlet UIPanGestureRecognizer *panRecognizer;
@property (retain, nonatomic) IBOutlet UIRotationGestureRecognizer *rotationRecognizer;
@property (retain, nonatomic) IBOutlet UIPinchGestureRecognizer *pinchRecognizer;

@property(nonatomic,assign) CGPoint touchCenter;
@property(nonatomic,assign) CGPoint rotationCenter;
@property(nonatomic,assign) CGPoint scaleCenter;
@end

@implementation ImageEditorViewController

@synthesize doneCallback = _doneCallback;
@synthesize sourceImage = _sourceImage;

@synthesize imageView = _imageView;
@synthesize cropView = _frameView;
@synthesize panRecognizer = _panRecognizer;
@synthesize rotationRecognizer = _rotationRecognizer;
@synthesize pinchRecognizer = _pinchRecognizer;
@synthesize touchCenter = _touchCenter;
@synthesize rotationCenter = _rotationCenter;
@synthesize scaleCenter = _scaleCenter;


#define CROP_RECT CGRectMake(0, 50, 320, 320)

- (void) dealloc
{
    [_imageView release];
    [_frameView release];
    [_doneCallback release];
    
    [_sourceImage release];
    [_panRecognizer release];
    [_rotationRecognizer release];
    [_pinchRecognizer release];
    [super dealloc];
}

- (void)setSourceImage:(UIImage *)sourceImage
{
    if(_sourceImage) {
        [_sourceImage release];
    }
    _sourceImage = [[self transformImageToUpOrientation:sourceImage] retain];
}


#pragma mark View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.sourceImage = [self transformImageToUpOrientation:self.sourceImage];
    
    self.cropView.cropRect = CROP_RECT;
    
    [self reset:nil];
    [self.view setMultipleTouchEnabled:YES];
    
    _panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    _rotationRecognizer = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
    _pinchRecognizer = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];

    self.panRecognizer.cancelsTouchesInView = NO;
    self.panRecognizer.delegate = self;
    [self.cropView addGestureRecognizer:self.panRecognizer];
    self.rotationRecognizer.cancelsTouchesInView = NO;
    self.rotationRecognizer.delegate = self;
    [self.cropView addGestureRecognizer:self.rotationRecognizer];
    self.pinchRecognizer.cancelsTouchesInView = NO;
    self.pinchRecognizer.delegate = self;
    [self.cropView addGestureRecognizer:self.pinchRecognizer];
}


- (void)viewDidUnload
{
    [self setPanRecognizer:nil];
    [self setRotationRecognizer:nil];
    [self setPinchRecognizer:nil];
    [self setImageView:nil];
    [self setCropView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark Action
- (IBAction)reset:(id)sender
{
    self.imageView.transform = CGAffineTransformIdentity;
    self.imageView.image  = self.sourceImage;
    self.imageView.frame = CROP_RECT;
    
    CGFloat aspect = self.sourceImage.size.height/self.sourceImage.size.width;
    CGFloat w = self.imageView.frame.size.width;
    CGFloat h = aspect * w;
    self.imageView.frame = CGRectMake(self.imageView.center.x - w/2, self.imageView.center.y - h/2,w,h);
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
    [recognizer setTranslation:CGPointMake(0, 0) inView:self.cropView];
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

- (UIImage *)transformImageToUpOrientation:(UIImage *)source;
{
    CGSize sourceSize =CGSizeZero;
    CGFloat rotation = 0.0;
    
    switch(source.imageOrientation)
    {
        case UIImageOrientationUp: {
            rotation = 0;
            sourceSize = source.size;
            
        } break;
        case UIImageOrientationDown: {
            rotation = M_PI;
            sourceSize = source.size;
        } break;
        case UIImageOrientationLeft:{
            rotation = M_PI_2;
            sourceSize = CGSizeMake(source.size.height, source.size.width);
        } break;
        case UIImageOrientationRight: {
            rotation = -M_PI_2;
            sourceSize = CGSizeMake(source.size.height, source.size.width);
        } break;
        default:
            break;
    }
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 source.size.width,
                                                 source.size.height,
                                                 CGImageGetBitsPerComponent(source.CGImage),
                                                 0,
                                                 CGImageGetColorSpace(source.CGImage),
                                                 CGImageGetBitmapInfo(source.CGImage));
    
    CGContextTranslateCTM(context,  source.size.width/2,  source.size.height/2);
    CGContextRotateCTM(context,rotation);
    
    CGContextDrawImage(context, CGRectMake(-sourceSize.width/2 ,
                                           -sourceSize.height/2,
                                           sourceSize.width,
                                           sourceSize.height),
                       source.CGImage);
    
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    UIImage *result = [UIImage imageWithCGImage:resultRef];
    
    CGContextRelease(context);
    CGImageRelease(resultRef);
    
    return result;
}

- (UIImage *)transformSourceImage
{
    CGSize sourceSize = self.sourceImage.size;
    UIImage* source = self.sourceImage;
    CGAffineTransform transform = self.imageView.transform;
    
    CGSize cropSize = CGSizeMake(source.size.width, source.size.width);
    
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 cropSize.width,
                                                 cropSize.height,
                                                 CGImageGetBitsPerComponent(source.CGImage),
                                                 0,
                                                 CGImageGetColorSpace(source.CGImage),
                                                 CGImageGetBitmapInfo(source.CGImage));
    CGContextSetFillColorWithColor(context,  [[UIColor clearColor] CGColor]);
    CGContextFillRect(context, CGRectMake(0, 0, cropSize.width, cropSize.height));
    CGSize uiSize = self.imageView.bounds.size;
    CGAffineTransform uiCoords = CGAffineTransformMakeScale(sourceSize.width/uiSize.width, sourceSize.height/uiSize.height);
    uiCoords = CGAffineTransformTranslate(uiCoords, uiSize.width/2.0, uiSize.width/2.0);
    uiCoords = CGAffineTransformScale(uiCoords, 1.0, -1.0);
    CGContextConcatCTM(context, uiCoords);
    
    CGContextConcatCTM(context, transform);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGContextDrawImage(context, CGRectMake(-uiSize.width/2.0,
                                           -uiSize.height/2.0,
                                           uiSize.width,
                                           uiSize.height)
                       ,source.CGImage);
    
    CGImageRef resultRef = CGBitmapContextCreateImage(context);
    UIImage *result = [UIImage imageWithCGImage:resultRef];
    
    CGContextRelease(context);
    CGImageRelease(resultRef);
    
    return result;
}


@end
