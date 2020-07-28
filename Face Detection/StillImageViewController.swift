//
//  StillImages.swift
//  Face Detection
//
//  Created by Tomasz Baranowicz on 15/07/2020.
//  Copyright © 2020 Tomasz Baranowicz. All rights reserved.
//

import UIKit
import Vision

class StillImageViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    var scaledImageRect: CGRect?
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if let image = UIImage(named: "profile") {
            imageView.image = image
            
            guard let cgImage = image.cgImage else {
                return
            }
    
            calculateScaledImageRect()
            performVisionRequest(image: cgImage)
        }
    }
    
    private func calculateScaledImageRect() {
        guard let image = imageView.image else {
            return
        }

        guard let cgImage = image.cgImage else {
            return
        }

        let originalWidth = CGFloat(cgImage.width)
        let originalHeight = CGFloat(cgImage.height)

        let imageFrame = imageView.frame
        let widthRatio = originalWidth / imageFrame.width
        let heightRatio = originalHeight / imageFrame.height

        // ScaleAspectFit
        let scaleRatio = max(widthRatio, heightRatio)

        let scaledImageWidth = originalWidth / scaleRatio
        let scaledImageHeight = originalHeight / scaleRatio

        let scaledImageX = (imageFrame.width - scaledImageWidth) / 2
        let scaledImageY = (imageFrame.height - scaledImageHeight) / 2
        
        self.scaledImageRect = CGRect(x: scaledImageX, y: scaledImageY, width: scaledImageWidth, height: scaledImageHeight)
    }
    
    private func performVisionRequest(image: CGImage) {
         
         let faceDetectionRequest = VNDetectFaceRectanglesRequest(completionHandler: self.handleFaceDetectionRequest)

         let requests = [faceDetectionRequest]
         let imageRequestHandler = VNImageRequestHandler(cgImage: image,
                                                         orientation: .up,
                                                         options: [:])
         
         DispatchQueue.global(qos: .userInitiated).async {
             do {
                 try imageRequestHandler.perform(requests)
             } catch let error as NSError {
                 print(error)
                 return
             }
         }
     }
    
    private func handleFaceDetectionRequest(request: VNRequest?, error: Error?) {
        if let requestError = error as NSError? {
            print(requestError)
            return
        }
        
        guard let imageRect = self.scaledImageRect else {
            return
        }
            
        let imageWidth = imageRect.size.width
        let imageHeight = imageRect.size.height
        
        DispatchQueue.main.async {
            
            self.imageView.layer.sublayers = nil
            if let results = request?.results as? [VNFaceObservation] {
                
                for observation in results {
                    
                    print(observation.boundingBox)
                    
                    var scaledObservationRect = observation.boundingBox
                    scaledObservationRect.origin.x = imageRect.origin.x + (observation.boundingBox.origin.x * imageWidth)
                    scaledObservationRect.origin.y = imageRect.origin.y + (1 - observation.boundingBox.origin.y - observation.boundingBox.height) * imageHeight
                    scaledObservationRect.size.width *= imageWidth
                    scaledObservationRect.size.height *= imageHeight
                    
                    let faceRectanglePath = CGPath(rect: scaledObservationRect, transform: nil)
                    
                    let faceLayer = CAShapeLayer()
                    faceLayer.path = faceRectanglePath
                    faceLayer.fillColor = UIColor.clear.cgColor
                    faceLayer.strokeColor = UIColor.yellow.cgColor
                    self.imageView.layer.addSublayer(faceLayer)
                }
            }
        }
    }
}
