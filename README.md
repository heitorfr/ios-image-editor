iOS Image Editor
================

A iOS View Controller for image cropping. An alternative to the UIImagePickerController editor with extended features and flexibility. Drop me a line if your're using this on your apps, I would like to know.

Features
--------

* Full image resolution
* Unlimited pan, zoom and rotation
* Zoom and rotation centered on touch area
* Double tap to reset
* Handles EXIF orientations
* Plug-in your own interface


Usage
-----

<pre><code class="objc">
HFImageEditorViewController *imageEditor = [[HFImageEditorViewController alloc] initWithNibName:@"DemoImageEditor" bundle:nil];

imageEditor.sourceImage = image;
imageEditor.doneCallback = ^(UIImage *editedImage, BOOL canceled){
    ...
}
</pre></code>


Configuration Properties
----------

#### sourceImage
The full resolution UIImage to crop

#### previewImage

For images larger than 1024 wide or 1024 height, the image editor will create a preview image before the view is shown. If a preview is already available you can get a faster transition by setting the preview propety. For instance, if the image was fetched using the <code>UIImagePickerController</code>:

<pre><code class="objc">
UIImage *image =  [info objectForKey:UIImagePickerControllerOriginalImage];
NSURL *assetURL = [info objectForKey:UIImagePickerControllerReferenceURL];

[self.library assetForURL:assetURL resultBlock:^(ALAsset *asset) {
    UIImage *preview = [UIImage imageWithCGImage:[asset aspectRatioThumbnail]];
HFImageEditorViewController *imageEditor = [[HFImageEditorViewController alloc] 
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
A CGSize specifying the width and height of the crop area in screen coordinates. NOTE: Currently <code>HFImageEditorViewController</code> is expecting <code>cropSize</code> to be set only after its view and the <code>frameView</code> outlet have been set. If you subclass <code>HFImageEditorViewController</code> you can do it in viewDidLoad; if not, you should set it after adding <code>HFImageEditorViewController</code> to the view controller hierarchy.
 
#### cropRect
A CGRect specifying the crop area in screen coordinates. Use instead of `cropSize` if the crop area is not centered. NOTE: Currently <code>HFImageEditorViewController</code> is expecting <code>cropRect</code> to be set only after its view and the <code>frameView</code> outlet have been set. If you subclass <code>HFImageEditorViewController</code> you can do it in viewDidLoad; if not, you should set it after adding <code>HFImageEditorViewController</code> to the view controller hierarchy.

#### outputWidth
The width of the cropped image. If not defined, the width of the source image is assumed.

#### minimumScale, maximumScale
The bounds for image scaling. If not defined, image zoom is unlimited.

#### checkBounds
Set to true to bound the image transform so that you dont' get a black backround on the resulting image.

#### panEnabled, rotateEnabled, scaleEnabled, tapToResetEnabled
BOOL property to enable/disable specific gestures

Output Properties
----------

####cropBoundsInSourceImage
Returns a CGRect representing the current crop rectangle in the source image coordinates. Source image coordinates have the origin at the bottom left of the image. Note that, if rotation has been applyed, then cropBoundsInSourceImage represents the bounding box of the rotated crop rectangle.


Interface
---------
Create your own xib for a custom user interface.
 
* Set <code>HFImageEditorViewController</code> (or subclass) as the file owner
* Set the <code>frameView</code> outlet. This view must implement the <code>HFImageEditorFrame</code> protocol. It must be transparent in the crop area, the image will show behind. A default implementation ImageEditorFrameView is provided
* Connect interface elements to the available actions: <code>done</code>, <code>reset</code>, <code>resetAnimated</code> and <code>cancel</code>.

The demo app also shows how extended controlls can be implemented: three buttons are used for square, portrait and landscape crop.

Use the subclassing hooks (<code>startTransformHook</code>, <code>endTransformHook</code>) if you need to update the interface during image processing (to diable UI controls, for instance).


ChangeLog
---------

#### 1.1
##### Features:

* New <code>checkBounds</code> setting to bound the image scale and pan to avoid clear space.

#### 1.1.1
##### Features:

* Crop rectangle does not have to be centered - use cropRect to specify the crop area instead of cropSize
* One step transform - orientation fix and cropping on the same operation for improved memory footprint and speed

##### Bug fixes:

* Support all EXIF orientation 

#### 1.1.2

##### Bug fixes:

Bound check now works correctly with any transform including rotation.

#### 1.1.3

ios-image-editor is now using ARC

#### 1.1.4

##### Bug fixes:
<code>rotationEnabled</code>, <code>panEnabled</code>, <code>scaleEnabled</code>, <code>tapToResetEnabled</code> where being ignored if set before the editor view was loaded.

#### 

License
---------
MIT License

Copyright (c) 2012 Heitor Ferreira

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
