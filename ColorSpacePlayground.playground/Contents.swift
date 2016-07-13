// Swift 2.2, Xcode 7.3.1
// 8 July, 2016
// jbagley@artandlogic.com

import Cocoa
import XCPlayground

/*: ## Cocoa and Color Spaces; a Quick Tour */

/*: Here's an `NSImage`. It happens to be an image depicting some color space gamuts. */
let image = [#Image(imageLiteral: "CIE1931xy_gamut_comparison.svg.png")#]

// The representation in image.representation isn't guaranteed to be an `NSBitmapImageRep`. This is a risk but it works on my system. There are safe ways to do this, but the easiest isn't available in a playground.
let imageRep: NSBitmapImageRep = image.representations.first as! NSBitmapImageRep

/*: The color space name reported by `NSBitmapImageRep` isn't exactly accurate. There are only a few allowed names and if your image uses something else, it will be mapped to the name which describes it most closely. It can't be used to apply the original image's color space to a derivative image unless that level of accuracy is not required, or the original uses the same color space provided by the system for that name. */
imageRep.colorSpaceName

/*: Here are the specifics on this image's colorSpace. (This playground renders the color space name as a summary.)*/
imageRep.colorSpace

/*: ### Image IO can help, a little.
 
The Core Graphics Image IO API will tell you what the stored colorspace is, maybe. Create an image source and ask it for the image properties. Some images however do not include one.

Here's an example of querying the color space information for two file types without necessarily  loading an image.

This JPEG does have a color space and provides the name as a property. */
var path = NSBundle.mainBundle().pathForImageResource("fireworks")!
var jpgURL = NSURL(fileURLWithPath: path, isDirectory: false);
var cgImageSrc = CGImageSourceCreateWithURL(jpgURL, nil)!
var properties = CGImageSourceCopyPropertiesAtIndex(cgImageSrc, 0, nil)! as NSDictionary
let jpgColorSpaceName = properties["ProfileName"] as? NSString

/*: ### You think you know, but you don't know.
There's not always a round trip from color space name back to a space the system can provide for you. If we want the output in the original's color space, we will need to hang on to the color space object, not just the name.
*/
var newSpace: CGColorSpace? = CGColorSpaceCreateWithName(jpgColorSpaceName)

/*: The color space can be grabbed from the loaded image. Hang onto this for later. */
let jpgColorSpace = CGImageGetColorSpace(CGImageSourceCreateImageAtIndex(cgImageSrc, 0, nil)!)

/*: Some formats, like PNG, don't always store a color space. */
path = NSBundle.mainBundle().pathForImageResource("CIE1931xy_gamut_comparison.svg")!
let pngURL = NSURL(fileURLWithPath: path, isDirectory: false)
cgImageSrc = CGImageSourceCreateWithURL(pngURL, nil)!
properties = CGImageSourceCopyPropertiesAtIndex(cgImageSrc, 0, nil)! as NSDictionary


/*: The `NSImage` might only have a representation of the image cached on the GPU, but your image processor might run on the CPU and require `NSBitmapImageRep`. The more direct route to the bits is to load one with Quartz. We'll just get it from the bitmap image rep obtained above. */

let cgImage = imageRep.CGImage
newSpace = CGImageGetColorSpace(cgImage)

/*: With the space cached, we are ready to produce an output image. I'll shortcut that by just making a copy. Quartz will provide a version of any function that creates an image which takes a color space, and it also lets you remap any CGImage to a new color space.

The original's color space can be preserved when copying, but `CGImageCreateCopyWithColorSpace` will remap an existing image for you. */
var cgImageCopy = CGImageCreateCopy(cgImage)
var cgImageCopyColorSpaceName = CGColorSpaceCopyName(newSpace)

/*: Map to another color space. */
cgImageCopy = CGImageCreateCopyWithColorSpace(cgImage, CGColorSpaceCreateWithName(kCGColorSpaceAdobeRGB1998))
/*: Verify the new space is used. */
CGColorSpaceCopyName(CGImageGetColorSpace(cgImageCopy))

/*: Passing kCGColorSpaceGenericGray will fail. Quartz won't try to change the color model because it would have to make assumptions about the mapping between the two. */
let failedImageCopy = CGImageCreateCopyWithColorSpace(cgImage, CGColorSpaceCreateWithName(kCGColorSpaceGenericGray))

/*: ###Core Image
Core Image is less friendly to color spaces. The color space can only be set when creating a CIImage from raw data or a texture. */
var ciImage = CIImage(contentsOfURL: jpgURL)!
CGColorSpaceCopyName(ciImage.colorSpace)

// This form of init with options is deprecated in 10.11.
let newCiImage = CIImage(CGImage: cgImage!, options: [ kCIImageColorSpace: newSpace! ])
// The new color space is ignored anyway
CGColorSpaceCopyName(newCiImage.colorSpace)
