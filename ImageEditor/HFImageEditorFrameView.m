#import "HFImageEditorFrameView.h"
#import "QuartzCore/QuartzCore.h"


@interface HFImageEditorFrameView ()
@property (nonatomic,strong) UIImageView *imageView;
@end

@implementation HFImageEditorFrameView

@synthesize cropRect = _cropRect;
@synthesize imageView  = _imageView;
@synthesize useCircularImage = _useCircularImage;

- (void) initialize
{
    self.opaque = NO;
    self.layer.opacity = 0.7;
    self.backgroundColor = [UIColor clearColor];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
    imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:imageView];
    self.imageView = imageView;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame useCircularImage:(BOOL)useCircularImage {
    self = [super initWithFrame:frame];
    if (self) {
        _useCircularImage = useCircularImage;
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if(self) {
        [self initialize];
    }
    return self;
}



- (void)setCropRect:(CGRect)cropRect
{
    if(!CGRectEqualToRect(_cropRect,cropRect)){
        _cropRect = CGRectOffset(cropRect, self.frame.origin.x, self.frame.origin.y);
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.f);
        CGContextRef context = UIGraphicsGetCurrentContext();
        [[UIColor blackColor] setFill];
        UIRectFill(self.bounds);
        
        if ( _useCircularImage ) {
            CGContextAddEllipseInRect(context, _cropRect);
            CGContextClip(context);
        }
        
        CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] colorWithAlphaComponent:0.9].CGColor);
        CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
        UIRectFill(_cropRect);
        
        if ( !_useCircularImage ) CGContextStrokeRect(context, _cropRect);
        else CGContextStrokeEllipseInRect(context, CGRectInset(_cropRect, 1, 1));
        
        self.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
    }
}

/*
 - (void)drawRect:(CGRect)rect
 {
 CGContextRef context = UIGraphicsGetCurrentContext();
 
 [[UIColor blackColor] setFill];
 UIRectFill(rect);
 CGContextSetStrokeColorWithColor(context, [[UIColor whiteColor] colorWithAlphaComponent:0.5].CGColor);
 CGContextStrokeRect(context, self.cropRect);
 [[UIColor clearColor] setFill];
 UIRectFill(CGRectInset(self.cropRect, 1, 1));
 
 }
 */

@end
