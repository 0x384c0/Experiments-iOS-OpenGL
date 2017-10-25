//
//  ModelViewController.swift
//  Experiments-iOS-OpenGL
//
//  Created by 0x384c0 on 10/25/17.
//  Copyright © 2017 0x384c0. All rights reserved.
//

import UIKit
import GLView

class ModelViewController: UIViewController {
    @IBOutlet weak var modelView: GLModelView!
    
    let modelName = "models_3d/cube.obj"
    
    override func viewDidLoad() {
        //set title
        navigationItem.title = modelName
        
        //set model
        modelView.texture = nil
        modelView.blendColor = UIColor.gray
        modelView.model = GLModel(contentsOfFile: modelName)
        
        //set default transform
        var transform = CATransform3DMakeTranslation(0.0, 0.0, -1.0);
        transform = CATransform3DRotate(transform, CGFloat(Double.pi/4), 1.0, 1.0, 0.0);
        self.modelView.modelTransform = transform;
    }
}
