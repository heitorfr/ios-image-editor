#import <AssetsLibrary/AssetsLibrary.h>
#import "DemoAppDelegate.h"
#import "ImageEditorViewController.h"

@implementation DemoAppDelegate

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [super dealloc];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]] autorelease];
    [self showImagePicker];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)showImagePicker
{
    if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        
        picker.allowsEditing = NO;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        //picker.navigationBar.hidden = YES;
        self.window.rootViewController = picker;
        [picker release];
    }

}

-(void) imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    ImageEditorViewController *imageEditor = [[ImageEditorViewController alloc] initWithNibName:@"DemoImageEditor" bundle:nil];
    imageEditor.sourceImage = image;
    /*
    imageEditor.cropWidth = 320;
    imageEditor.cropHeight = 190;
    imageEditor.outputWidth = 640;
     */
    imageEditor.doneCallback = ^(UIImage *editedImage, BOOL canceled){
        if(!canceled) {
            ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
            [library writeImageToSavedPhotosAlbum:[editedImage CGImage]
                                      orientation:editedImage.imageOrientation
                                  completionBlock:^(NSURL *assetURL, NSError *error){
                                      if (error) {
                                          UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error Saving"
                                                                                          message:[error localizedDescription]
                                                                                         delegate:nil
                                                                                cancelButtonTitle:@"Ok"
                                                                                otherButtonTitles: nil];
                                          [alert show];
                                          [alert release];
                                      } 
            }];
            [library release];
        }
        [picker popToRootViewControllerAnimated:YES];
        [picker setNavigationBarHidden:NO animated:YES];
    };
    [picker setNavigationBarHidden:YES animated:NO];
    [picker pushViewController:imageEditor animated:YES];
    [imageEditor release];
}

- (void) imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Cancel"
                                                    message:@"Nowhere to go my friend. This is a demo."
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles: nil];
    [alert show];
    [alert release];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
