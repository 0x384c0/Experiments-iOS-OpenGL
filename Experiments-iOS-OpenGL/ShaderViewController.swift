//
//  ViewController.swift
//  Experiments-iOS-OpenGL
//
//  Created by 0x384c0 on 8/23/17.
//  Copyright © 2017 0x384c0. All rights reserved.
//

import UIKit

class ShaderViewController: UIViewController {
    @IBOutlet weak var glView: OpenGLView!
    @IBOutlet weak var textField: UITextView!
    
    private var
    settings:ShaderSettings?
    func setup(_ settings:ShaderSettings){
        navigationItem.title = settings.shaderName
        self.settings = settings
    }
    
    private var animationLaunched = false
    override func viewDidAppear(_ animated: Bool) {
        if animationLaunched {return}
        animationLaunched = true
        
        let shaderFolder = "shaders/"
        let shaderPath = Bundle.main.path(forResource: shaderFolder + settings!.shaderName, ofType: "glsl")!
        textField.text = try! String(contentsOfFile: shaderPath, encoding: .utf8)
        
        glView.config(shaderName:settings!.shaderName, textureName:settings!.textureName, isOpaque: settings!.isOpaque)
    }
    
    
    deinit {
        glView.handleDeinit()
    }
}
