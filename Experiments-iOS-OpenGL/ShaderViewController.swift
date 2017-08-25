//
//  ViewController.swift
//  Experiments-iOS-OpenGL
//
//  Created by 0x384c0 on 8/23/17.
//  Copyright © 2017 0x384c0. All rights reserved.
//

import UIKit

class ShaderViewController: UIViewController {
    class var segueID:String {return String(describing:self)}
    @IBOutlet weak var glView: OpenGLView!
    @IBOutlet weak var textField: UITextView!
    
    private var
    shaderName = "",
    textureName:String?,
    skipFrames = 0
    func setup(shaderName:String){
        navigationItem.title = shaderName
        self.shaderName = shaderName
        switch shaderName {
        case "Clouds","TextureFragment":
            textureName = "RGBA_noize_med"
            skipFrames = Int(30.0 * 0.3)
        case "MengerSponge","Seascape","TheDriveHome":
            skipFrames = Int(30.0 * 0.3)
        default: break
        }
    }
    
    private var animationLaunched = false
    override func viewDidAppear(_ animated: Bool) {
        if animationLaunched {return}
        animationLaunched = true
        
        let shaderFolder = "shaders/"
        let shaderPath = Bundle.main.path(forResource: shaderFolder + shaderName, ofType: "glsl")!
        let ShaderString = try! String(contentsOfFile: shaderPath, encoding: .utf8)
        textField.text = ShaderString
        glView.config(shaderName:shaderName,textureName:textureName, skipFrames: skipFrames)
    }
    
    
    deinit {
        glView.handleDeinit()
    }
}
