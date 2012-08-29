#import <UIKit/UIKit.h>

@class ViewController;

@interface DemoAppDelegate : UIResponder <UIApplicationDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) ViewController *viewController;

@end
