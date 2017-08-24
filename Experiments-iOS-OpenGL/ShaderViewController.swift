//
//  ViewController.swift
//  Experiments-iOS-OpenGL
//
//  Created by 0x384c0 on 8/23/17.
//  Copyright © 2017 Spalmalo. All rights reserved.
//

import UIKit

class ShaderViewController: UIViewController {
    class var segueID:String {return String(describing:self)}
    @IBOutlet weak var glView: OpenGLView!
    @IBOutlet weak var textField: UITextView!
    
    private var shaderName = ""
    func setup(shaderName:String){
        self.shaderName = shaderName
    }
    
    override func viewDidLoad(){
        let shaderFolder = "shaders/"
        let shaderPath = Bundle.main.path(forResource: shaderFolder + shaderName, ofType: "glsl")!
        let ShaderString = try! String(contentsOfFile: shaderPath, encoding: .utf8)
        textField.text = ShaderString
        glView.config(shaderName:shaderName)
    }
}
