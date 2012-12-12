iOS Image Editor
================

A iOS View Controller for image cropping. An alternative to the UIImagePickerController editor with extended features.

Features
--------

* Full image resolution
* Unlimited pan, zoom and rotation
* Zoom and rotation centered on touch area
* Double tap to reset
* Handles EXIF orientations [supported by iPhone](http://www.gotow.net/creative/wordpress/?p=64)
* Configurable
* Plug-in your own interface

Usage
-----

<pre><code>ImageEditorViewController *imageEditor = [[ImageEditorViewController alloc] initWithNibName:@"DemoImageEditor" bundle:nil];

imageEditor.sourceImage = image;
imageEditor.doneCallback = ^(UIImage *editedImage, BOOL canceled){
    ...
}

</pre></code>


Properties
----------

#### sourceImage
The full resolution UIImage to crop

#### previewImage

For images larger than 1024 wide or 1024 height, the image editor will create a preview image before the view is shown. If a preview is already available you can get a faster transition by setting the preview propety. For instance, if the image was fetched using the <code>UIImagePickerController</code>:

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

#### doneCallback
The callback block called when the image editor completes. Returns the cropped image and a BOOL that specifies if completion results from a <code>done</code> or <code>cancel</code> actions.

#### cropSize
A CGSize specifying the width and height of the crop area in screen coordinates.

#### outputWidth
The width of the cropped image. If not defined, the width of the source image is assumed.

#### minimumScale, maximumScale
The bounds for image scaling. If not defined, image zoom is unlimited.

#### panEnabled, rotateEnabled, scaleEnabled, tapToResetEnabled
BOOL property to enable/disable specific gestures


Interface
---------
Create your own xib for a custom user interface.
 
* Set <code>ImageEditorViewController</code> (or subclass) as the file owner
* Set the <code>frameView</code> outlet. This view must implement the <code>ImageEditorFrame</code> protocol. It must be transparent in the crop area, the image will show behind. A default implementation ImageEditorFrameView is provided
* Connect interface elements to the available actions: <code>done</code>, <code>reset</code>, <code>resetAnimated</code> and <code>cancel</code>.

The demo app also shows how extended controlls can be implemented: three buttons are used for square, portrait and landscape crop.

Use the subclassing hooks (<code>startTransformHook</code>, <code>endTransformHook</code>) if you need to update the interface during image processing (to diable UI controls, for instance).

License
---------
MIT