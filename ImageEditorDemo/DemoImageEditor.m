#import "HFImageEditorViewController+SubclassingHooks.h"
#import "DemoImageEditor.h"

@interface DemoImageEditor ()

@end

@implementation DemoImageEditor

@synthesize  saveButton = _saveButton;

-(id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self) {
        self.cropSize = CGSizeMake(320,320);
        self.minimumScale = 0.2;
        self.maximumScale = 10;
    }
    return self;
}

- (void)dealloc
{
    [_saveButton release];
    [super dealloc];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.saveButton = nil;
}

- (IBAction)setSquareAction:(id)sender
{
    self.cropSize = CGSizeMake(320, 320);
}

- (IBAction)setLandscapeAction:(id)sender
{
    self.cropSize = CGSizeMake(320, 240);
}


- (IBAction)setLPortraitAction:(id)sender
{
    self.cropSize = CGSizeMake(240, 320);
}

#pragma mark Hooks
- (void)startTransformHook
{
    self.saveButton.tintColor = [UIColor colorWithRed:0 green:49/255.0f blue:98/255.0f alpha:1];
}

- (void)endTransformHook
{
    self.saveButton.tintColor = [UIColor colorWithRed:0 green:128/255.0f blue:1 alpha:1];
}


@end
