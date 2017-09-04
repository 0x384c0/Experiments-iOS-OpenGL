//
//  ShaderGLKitViewController.swift
//  Experiments-iOS-OpenGL
//
//  Created by 0x384c0 on 8/26/17.
//  Copyright © 2017 0x384c0. All rights reserved.
//

import GLKit

class ShaderGLKitViewController: GLKViewController, ShaderToyRenderer {


    var glView:GLKView{return view as! GLKView}
    var
    playBtn:UIBarButtonItem!,
    pauseleBtn:UIBarButtonItem!
    func playPauseToggle(_ sender: UIBarButtonItem) {
        var toggleBtn = playBtn
        if isPlaying {
            isPlaying = false
        } else {
            toggleBtn = pauseleBtn
            isPlaying = true
        }
        navigationItem.rightBarButtonItem = toggleBtn
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        playBtn = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(playPauseToggle(_:)))
        pauseleBtn = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(playPauseToggle(_:)))
        navigationItem.rightBarButtonItem = pauseleBtn
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        glView.context = EAGLContext(api: .openGLES2)
        EAGLContext.setCurrent(glView.context)
        let program = glCreateProgram()
        compileShaders(shaderName: settings!.shaderName,program: program)
        if let texture = UIImage(named: settings?.textureName ?? "")?.cgImage{
            setupTextures(texture: texture, program: program)
        }
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        render()
    }
    
    
    private var
    settings:ShaderSettings?
    func setup(_ settings:ShaderSettings){
        navigationItem.title = settings.shaderName
        self.settings = settings
    }
    
    //ShaderToyRenderer
    var
    positionSlot: GLuint = 0,
    colorSlot: GLuint = 0,
    iTimeSlot: GLint = 0,
    iResolution: GLint = 0,
    iMouse: GLint = 0,
    iMousePoint = CGPoint(x: 1, y: 1),
    textureSlot: GLint = 0,
    startTime:CFTimeInterval = CACurrentMediaTime(),
    isPlaying = true
    var renderFrame: CGRect {return view.frame}
    
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        iMousePoint = touches.first!.location(in: view)
    }
    
}






