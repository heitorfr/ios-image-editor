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

#### Interface

You can create your own xib for a custom user interface.
 
* Set ImageEditorViewController (or subclass) as the file owner
* Set the frameView outlet. This view must implement the ImageEditorFrameView protocol. It must be transparent in the crop area, the image will show behind
* Set the done, reset and cancel actions.

The demo app also shows how extended controlls can be implemented: three buttons are used for square, portrait and landscape crop.
