## 1.1

Features:

* New <code>checkBounds</code> setting to bound the image scale and pan to avoid clear space.

## 1.1.1

Features:

* Crop rectangle does not have to be centered - use cropRect to specify the crop area instead of cropSize
* One step transform - orientation fix and cropping on the same operation for improved memory footprint and speed

Bugfixes:

* Support all EXIF orientation 

## 1.1.2

Bugfixes:

* Bound check now works correctly with any transform including rotation.

## 1.1.3

Features:

* ios-image-editor is now using ARC

## 1.1.4

Bugfixes:

* <code>rotationEnabled</code>, <code>panEnabled</code>, <code>scaleEnabled</code>, <code>tapToResetEnabled</code> where being ignored if set before the editor view was loaded.

