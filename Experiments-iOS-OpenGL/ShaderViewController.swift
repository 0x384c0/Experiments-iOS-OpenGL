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
        self.shaderName = shaderName
        switch shaderName {
        case "Clouds":
            textureName = "RGBA_noize_med"
            skipFrames = 30 * 5
        case "MengerSponge":
            skipFrames = 30 * 3
        default: break
        }
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        view.layoutSubviews()
        let shaderFolder = "shaders/"
        let shaderPath = Bundle.main.path(forResource: shaderFolder + shaderName, ofType: "glsl")!
        let ShaderString = try! String(contentsOfFile: shaderPath, encoding: .utf8)
        textField.text = ShaderString
        glView.config(shaderName:shaderName,textureName:textureName, skipFrames: skipFrames)
    }
}
