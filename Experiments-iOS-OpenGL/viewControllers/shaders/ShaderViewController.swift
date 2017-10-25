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
    
    var
    playBtn:UIBarButtonItem!,
    pauseleBtn:UIBarButtonItem!
    func playPauseToggle(_ sender: UIBarButtonItem) {
        var toggleBtn = playBtn
        if glView.isPlaying {
            glView.isPlaying = false
        } else {
            toggleBtn = pauseleBtn
            glView.isPlaying = true
        }
        navigationItem.rightBarButtonItem = toggleBtn
    }
    
    override func viewWillAppear(_ animated: Bool) {
        playBtn = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(playPauseToggle(_:)))
        pauseleBtn = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(playPauseToggle(_:)))
        navigationItem.rightBarButtonItem = pauseleBtn
    }
    
    override func viewDidAppear(_ animated: Bool) {
        if animationLaunched {return}
        animationLaunched = true
        
        let shaderFolder = "shaders/"
        let shaderPath = Bundle.main.path(forResource: shaderFolder + settings!.shaderName, ofType: "glsl")!
        textField.text = try! String(contentsOfFile: shaderPath, encoding: .utf8)
        
        glView.config(
            shaderName:settings!.shaderName,
            texture0Name: settings!.texture0Name,
            texture1Name: settings!.texture1Name,
            texture2Name: settings!.texture2Name,
            texture3Name: settings!.texture3Name,
            isOpaque: settings!.isOpaque
        )
    }
    
    
    
    private var
    animationLaunched = false,
    settings:ShaderSettings?
    func setup(_ settings:ShaderSettings){
        navigationItem.title = settings.shaderName
        self.settings = settings
    }
    
    
    deinit {
        glView.handleDeinit()
    }
}
