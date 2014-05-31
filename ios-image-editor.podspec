Pod::Spec.new do |s|
  s.name         = "ios-image-editor"
  s.version      = "1.1.4"
  s.summary      = "iOS View Controller for image cropping. An alternative to the UIImagePickerController editor with extended features and flexibility."

  s.description  = <<-DESC
                   iOS View Controller for image cropping. An alternative to the UIImagePickerController editor with extended features and flexibility:
                   -  Full image resolution
                   -  Unlimited pan, zoom and rotation
                   -  Zoom and rotation centered on touch area
                   -  Double tap to reset
                   -  Handles EXIF orientations
                   -  Plug-in your own interface
                   DESC

  s.homepage     = "https://github.com/heitorfr/ios-image-editor"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "Heitor Ferreira" => "me@heitor.fr" }
  s.platform     = :ios, "5.0"
  s.requires_arc = true 
  s.source       = { :git => "https://github.com/heitorfr/ios-image-editor.git", :tag => "1.1.4" }
  s.source_files = "ImageEditor/*.{h,m}"
end
