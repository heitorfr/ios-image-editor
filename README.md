iOS Image Editor
================

A iOS View Controller to crop images. An alternative to the UIImagePickerController editor with extended features.

#### Features

* Full image resolution
* Unlimited zoom and rotation
* Zoom and rotation centered on touch area
* Handles EXIF orientations [supported by iPhone](http://www.gotow.net/creative/wordpress/?p=64)

#### Usage

<pre><code>ImageEditorViewController *imageEditor = [[ImageEditorViewController alloc] initWithNibName:@"DemoImageEditor" bundle:nil];

imageEditor.sourceImage = image;
imageEditor.cropSize = CGSizeMake(320,320); // default 320
imageEditor.outputWidth = 640; // default: source width
imageEditor.doneCallback = ^(UIImage *editedImage, BOOL canceled){
    ...
}
</pre></code>

For images larger than 1024 wide or 1024 height, the image editor will create a preview image before the view is shown. If a preview is already available you can get a faster transition by setting the preview propety. For instance, if the image was fetched using the UIImagePickerController:

<pre><code>
UIImage *image =  [info objectForKey:UIImagePickerControllerOriginalImage];
NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];

[self.library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
    UIImage *preview = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
ImageEditorViewController *imageEditor = [[ImageEditorViewController alloc] 
	initWithNibName:@"DemoImageEditor" bundle:nil];
    self.imageEditor.sourceImage = image;
    self.imageEditor.previewImage = preview;        
...
} failureBlock:^(NSError *error) {
    NSLog(@"Failed to get asset from library");
}];
</pre></code>

#### Interface

You can create your own xib for a custom user interface.
 
* Set ImageEditorViewController (or subclass) as the file owner
* Set the frameView outlet. This view must implement the ImageEditorFrame protocol. It must be transparent in the crop area, the image will show behind. A default implementation ImageEditorFrameView is provided
* Set the done, reset and cancel actions.

The demo app also shows how extended controlls can be implemented: three buttons are used for square, portrait and landscape crop.
