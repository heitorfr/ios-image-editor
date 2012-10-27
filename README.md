iOS Image Editor
================

An alternative to croping images with UIImagePickerController.

#### Features

* Full image resolution
* Unlimited zoom and rotation
* Zoom and rotation centered on touch area
* Handles EXIF orientations [supported by iPhone](http://www.gotow.net/creative/wordpress/?p=64)

#### Usage

<pre><code>ImageEditorViewController *imageEditor = [[ImageEditorViewController alloc] initWithNibName:@"DemoImageEditor" bundle:nil];

imageEditor.sourceImage = image;
imageEditor.cropWidth = 320; // default 320
imageEditor.cropHeight = 190; // default 320
imageEditor.outputWidth = 640; // default: source width
imageEditor.doneCallback = ^(UIImage *editedImage, BOOL canceled){
    ...
}
</pre></code>

#### Interface

You can create your own xib for the user interface. Set ImageEditorViewController as the file owner. Set the frameView outlet (where cropping takes place) and the done, reset and cancel actions.