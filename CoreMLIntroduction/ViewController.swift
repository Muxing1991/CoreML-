//
//  ViewController.swift
//  CoreMLIntroduction
//
//  Created by 杨威 on 2017/6/28.
//  Copyright © 2017年 MuXing. All rights reserved.
//

import UIKit
import CoreML

class ViewController: UIViewController, UINavigationControllerDelegate {
  
  //MARK: - IBOutlet
  
  @IBOutlet weak var imageView: UIImageView!
  
  @IBOutlet weak var classifierLabel: UILabel!
  
  //MARK: - Property
  var model: Inceptionv3!
  
  //MARK: - IBAction
  
  //打开相机
  @IBAction func camera(_ sender: Any) {
    if !UIImagePickerController.isSourceTypeAvailable(.camera) {
      return
    }
    let cameraPicker = UIImagePickerController()
    cameraPicker.delegate = self
    cameraPicker.delegate = self
    cameraPicker.sourceType = .camera
    cameraPicker.allowsEditing = false
    
    present(cameraPicker, animated: true, completion: nil)
  }
  
  
  @IBAction func openLibrary(_ sender: Any) {
    let picker = UIImagePickerController()
    picker.allowsEditing = false
    picker.delegate = self
    picker.sourceType = .photoLibrary
    present(picker, animated: true, completion: nil)
  }
  
  //MARK: - Lifecycle
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    model = Inceptionv3()
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

extension ViewController: UIImagePickerControllerDelegate {
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    dismiss(animated: true, completion: nil)
  }
  
  //图像转换
  func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
    picker.dismiss(animated: true, completion: nil)
    classifierLabel.text = "Analyzing Image..."
    guard let image = info["UIImagePickerControllerOriginalImage"] as? UIImage else { return }
    UIGraphicsBeginImageContextWithOptions(CGSize(width: 299, height: 299), true, 2.0)
    image.draw(in: CGRect(x: 0, y: 0, width: 299, height: 299))
    let newImage = UIGraphicsGetImageFromCurrentImageContext()!
    UIGraphicsEndImageContext()
    
    let attrs = [kCVPixelBufferCGImageCompatibilityKey:     kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
    var pixelBuffer: CVPixelBuffer?
    let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                     Int(newImage.size.width),
                                     Int(newImage.size.height),
                                     kCVPixelFormatType_32ARGB,
                                     attrs,
                                     &pixelBuffer)
    guard (status == kCVReturnSuccess) else { return }
    CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer!)
    
    let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
    
    let context = CGContext.init(data: pixelData,
                                 width: Int(newImage.size.width),
                                 height: Int(newImage.size.height),
                                 bitsPerComponent: 8,
                                 bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!),
                                 space: rgbColorSpace,
                                 bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
    context?.translateBy(x: 0, y: newImage.size.height)
    context?.scaleBy(x: 1.0, y: -1.0)
    
    UIGraphicsPushContext(context!)
    newImage.draw(in: CGRect(x: 0, y: 0, width: newImage.size.width, height: newImage.size.height))
    UIGraphicsPopContext()
    CVPixelBufferUnlockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
    imageView.image = newImage
    
    guard let prediction = try? model.prediction(image: pixelBuffer!  ) else { return }
    classifierLabel.text = "I think this is a \(prediction.classLabel)"
  }
}



























