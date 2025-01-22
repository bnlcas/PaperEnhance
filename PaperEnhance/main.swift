//
//  main.swift
//  PaperEnhance
//
//  Created by Benjamin Lucas on 1/18/25.
//

import Foundation
import CoreImage
import AppKit

// Helper function to print usage instructions
func printUsage() {
    print("""
    Usage: PaperEnhance <input_file> <output_file> [filter_parameters]
    Example: PaperEnhance input.jpg output.jpg amount=10 invert=false mask=false grayscale=false
    If mask=true, output will be a png with alpha//
    """)
}

// Handle The JPG vs PNG vs Transparency:
func isPNG_Out(outFilename : String, isMasked : Bool) -> Bool
{
    if isMasked{
        return true
    }
    let fileExtension = outFilename.split(separator: ".").last?.lowercased()
    return fileExtension == "png"
}

func reformatToPNG(outFilename : String) -> String{
    var fileParts = outFilename.split(separator: ".")
    fileParts.removeLast()
    fileParts.append("png")
    return fileParts.joined(separator: ".")
}



// Ensure correct number of arguments
guard CommandLine.arguments.count >= 3 else {
    printUsage()
    exit(1)
}

// Parse arguments
let inputPath = CommandLine.arguments[1]
var outputPath = CommandLine.arguments[2]

let filterParams = CommandLine.arguments.dropFirst(3).reduce(into: [String: String]()) { result, param in
    let parts = param.split(separator: "=")
    if (parts.count >= 2) {
        let value = parts[1]
        if(value != nil){
            result[String(parts[0])] = String(value)
        }
    }
}

let enhanceAmount = Double(filterParams["amount"] ?? "10.0") ?? 10.0
let maskImage = Bool(filterParams["mask"] ?? "false") ?? false
let invertImage = Bool(filterParams["invert"] ?? "false") ?? false
let grayScaleImage = Bool(filterParams["grayscale"] ?? "false") ?? false


// Load the & filter input image
guard let inputImage = CIImage(contentsOf: URL(fileURLWithPath: inputPath)) else {
    print("Error: Unable to load image at \(inputPath)")
    exit(1)
}

//Stock CoreImage Filter for improving documents
guard let enhanceFilter = CIFilter(name: "CIDocumentEnhancer") else {
    print("Error: No Document Enhance Filter")
    exit(1)
}
enhanceFilter.setValue(inputImage, forKey: kCIInputImageKey)
enhanceFilter.setValue(enhanceAmount, forKey: "inputAmount")


guard let enhancedImage = enhanceFilter.outputImage else {
    print("Error: Unable to generate filtered image")
    exit(1)
}

//Grayscale (and maybe contrast/brightness in the future if needed?)
guard let colorFilter = CIFilter(name: "CIColorControls") else {
    print("Error: No Color Filter")
    exit(1)
}
colorFilter.setValue(enhancedImage, forKey: kCIInputImageKey)
colorFilter.setValue(inputImage, forKey: kCIInputImageKey)
colorFilter.setValue( grayScaleImage ? 0.0 : 1.0, forKey: "inputSaturation")

guard let colorEnhancedImage = colorFilter.outputImage else {
    print("Error: Unable to generate color filtered image")
    exit(1)
}



let outputImage : CIImage
if(invertImage || maskImage){
    //Invert for chalkboard effect
    guard let invertFilter = CIFilter(name: "CIColorInvert")else {
        print("Error: Invalid invert filter name")
        exit(1)
    }

    invertFilter.setValue(colorEnhancedImage, forKey: kCIInputImageKey)
    guard let invertedImage = invertFilter.outputImage else {
        print("Error: Invert Error")
        exit(1)
    }
    
    if !maskImage{
        outputImage = invertedImage
    } else {
        //Useful for presentations
        guard let maskFilter = CIFilter(name: "CIBlendWithRedMask") else {
            print("Error: Invalid Mask Filter")
            exit(1)
        }
        maskFilter.setValue(colorEnhancedImage, forKey: kCIInputMaskImageKey)
        if(invertImage){
            maskFilter.setValue(invertedImage, forKey: kCIInputBackgroundImageKey)
        } else{
            maskFilter.setValue(colorEnhancedImage, forKey: kCIInputBackgroundImageKey)
        }
        guard let maskedImage = maskFilter.outputImage else {
            print("Error: Mask Error")
            exit(1)
        }
        outputImage = maskedImage
    }

} else{
    outputImage = colorEnhancedImage
}

// Create a Core Image context
let context = CIContext()

// Render the output image to a file
do {
    let is_png = isPNG_Out(outFilename: outputPath, isMasked: maskImage)
    if is_png {
        outputPath = reformatToPNG(outFilename: outputPath)
    }
    
    let outputURL = URL(fileURLWithPath: outputPath)
    if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
        let bitmapRep = NSBitmapImageRep(cgImage: cgImage)
        
        guard let data = bitmapRep.representation(using: is_png ? .png : .jpeg, properties: [:]) else {
            print("Error: Unable to create JPEG representation")
            exit(1)
        }
        try data.write(to: outputURL)
        print("Filtered image saved to \(outputPath)")
    } else {
        print("Error: Unable to create output CGImage")
        exit(1)
    }
} catch {
    print("Error: \(error.localizedDescription)")
    exit(1)
}
