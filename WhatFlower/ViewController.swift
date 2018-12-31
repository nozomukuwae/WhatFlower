//
//  ViewController.swift
//  WhatFlower
//
//  Created by Nozomu Kuwae on 2018/12/30.
//  Copyright © 2018 NKCompany. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var cameraButton: UIBarButtonItem!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    var imagePicker = UIImagePickerController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        imagePicker.delegate = self
    }

    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        
        present(imagePicker, animated: true, completion: nil)
    }
        
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        guard let image = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else { fatalError("Error getting image from image picker") }
        imagePicker.dismiss(animated: true, completion: nil)
        
        guard let ciimage = CIImage(image: image) else {
            fatalError("Error loading image")
        }
        
        detect(ciImage: ciimage)
    }
    
    private func detect(ciImage: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("Error loading CoreML Model")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Error getting result")
            }
            
            if let firstResult = results.first {
                DispatchQueue.main.async {
                    self.navigationItem.title = firstResult.identifier.capitalized
                }
                
                self.getFlowerInfo(name: firstResult.identifier)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: ciImage)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    private func getFlowerInfo(name: String) {
        
        let params: [String:String] = [
            "format":"json",
            "action":"query",
            "prop":"extracts|pageimages",
            "exintro":"",
            "explaintext":"",
            "titles":name,
            "indexpageids":"",
            "redirects":"1",
            "pithumbsize":"500"
        ]
        
        let url = "https://en.wikipedia.org/w/api.php"
        Alamofire.request(url, method: .get, parameters: params).responseJSON { (response) in
            if response.result.isSuccess {
                
                let infoJSON : JSON = JSON(response.result.value!)
                print(infoJSON)
                if let pageid : String = infoJSON["query"]["pageids"][0].string {
                    let info = infoJSON["query"]["pages"][pageid]["extract"].stringValue
                    let imageURL = infoJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                    
                    DispatchQueue.main.async {
                        self.label.text = info
                        if let url = URL(string: imageURL) {
                            self.imageView.sd_setAnimationImages(with: [url])
                        }
                    }
                }
            } else {
                print("Error getting flower info")
            }
        }
    }
}
