//
//  TruliooImageHelper.swift
//  SampleApp
//
//  Created by Callen Egan on 2021-02-01.
//  Copyright © 2021 com.acuant. All rights reserved.
//

import Foundation
import UIKit

let maxImageSize = 4 * 1024 * 1024 / 1.37 //dividing by 1.37 accounts for the ~1.37 image size increase when converting to base64

public class TruliooImageHelper{
    
    func convertAndCompressImageToBase64(image:UIImage?, metaData:String?) -> String?{
        if(image == nil){
            return nil
        }
        
        var quality:CGFloat = 1.0
        
        let newImage = createImageWithMetaData(image!, metaData: metaData ?? "")
        var imageData = getJpegData(newImage, compressionQuality: quality)
        
        while(Double(imageData!.count) > maxImageSize && quality > 0){
            quality -= 0.1
            imageData = getJpegData(newImage, compressionQuality: quality)
        }
        return imageData?.base64EncodedString()
    }
    
    func createImageWithMetaData(_ originalImage:UIImage, metaData: String?) -> CIImage {
           
        let imageData = originalImage.jpegData(compressionQuality: 1.0)!
        let sourceImageData = CGImageSourceCreateWithData(imageData as CFData, nil)!
        let sourceImageProperties = CGImageSourceCopyPropertiesAtIndex(sourceImageData, 0, nil)! as NSDictionary
        let mutable: NSMutableDictionary = sourceImageProperties.mutableCopy() as! NSMutableDictionary
        let tiffData: NSMutableDictionary = (mutable[kCGImagePropertyTIFFDictionary as String] as? NSMutableDictionary)!

        // tag it to tiff Software
        tiffData[kCGImagePropertyTIFFSoftware as String] = metaData

        // save original image data with updated exif data
        let typeIdentifier = CGImageSourceGetType(sourceImageData)!
        let imageDataWithExif: NSMutableData = NSMutableData(data: imageData)
        let destinationImage: CGImageDestination = CGImageDestinationCreateWithData((imageDataWithExif as CFMutableData), typeIdentifier, 1, nil)!
        
        CGImageDestinationAddImageFromSource(destinationImage, sourceImageData, 0, (mutable as CFDictionary))
        CGImageDestinationFinalize(destinationImage)

        let newImage: CIImage = CIImage(data: imageDataWithExif as Data, options: nil)!
        
        return newImage
    }
    
    func getJpegData(_ image: CIImage, compressionQuality: CGFloat) -> Data? {
        let context = CIContext()
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        return context.jpegRepresentation(of: image, colorSpace: colorSpace!, options: [kCGImageDestinationLossyCompressionQuality as CIImageRepresentationOption : compressionQuality])
    }
}
