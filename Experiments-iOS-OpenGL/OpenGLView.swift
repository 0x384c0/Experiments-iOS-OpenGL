//
//  GLView.swift
//  swift-openglview-example
//
//  Created by dolphilia on 2016/01/08.
//  Copyright © 2016年 dolphilia. All rights reserved.
//
import UIKit
import QuartzCore
import OpenGLES
import GLKit



class OpenGLView:UIView,ShaderToyRenderer{
    var
    eaglLayer:CAEAGLLayer!,
    context:EAGLContext!,
    colorRenderBuffer:GLuint = 1,
    glViewIsOpaque = true
    
    
    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }
    
    
    func config(shaderName: String,textureName:String?,isOpaque:Bool = true) {
        self.glViewIsOpaque = isOpaque
        backgroundColor = UIColor.clear
        setupLayer()
        setupContext()
        setupRenderBuffer()
        setupFrameBuffer()
        let program = glCreateProgram()
        compileShaders(shaderName: shaderName, program: program)
        if let texture = UIImage(named: textureName ?? "")?.cgImage{
            setupTextures(texture: texture, program: program)
        }
        render()
        setupDisplayLink()
    }
    
    private func setupLayer(){
        eaglLayer = layer as! CAEAGLLayer
        eaglLayer.isOpaque = glViewIsOpaque
        backgroundColor = UIColor.clear
    }
    private func setupContext(){
        if let context = EAGLContext(api: .openGLES3) {
            self.context = context
            if !EAGLContext.setCurrent(context) {
                preconditionFailure("Failed to set current opengl context")
            }
        } else {
            preconditionFailure("failed to initial opengl context")
        }
        
        //background color
        glClearColor(0, 0, 0, 0.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        glViewport(0, 0, GLint(self.frame.size.width), GLint(self.frame.size.height));
    }
    private func setupRenderBuffer() {
        glGenRenderbuffers(1, &colorRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), colorRenderBuffer)
        context.renderbufferStorage(Int(GL_RENDERBUFFER), from: eaglLayer)
    }
    private func setupFrameBuffer() {
        var frameBuffer: GLuint = 0
        glGenFramebuffers(1, &frameBuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), frameBuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_RENDERBUFFER), colorRenderBuffer)
    }
    
    private var link:CADisplayLink?
    private func setupDisplayLink(){
        link = CADisplayLink(target: self, selector: #selector(renderSingleFrame))
        link?.add(to: RunLoop.current, forMode: .defaultRunLoopMode)
    }
    @objc func renderSingleFrame(){
        render()
        let success = context.presentRenderbuffer(Int(GL_RENDERBUFFER))
        if !success{ preconditionFailure("failed to presentRenderbuffer") }
    }
    
    deinit {
        handleDeinit()
    }
    func handleDeinit(){
        link?.invalidate()
        link = nil
    }
    
    //ShaderToyRenderer
    var
    positionSlot: GLuint = 0,
    iTimeSlot: GLint = 0,
    iResolution: GLint = 0,
    textureSlot: GLint = 0,
    startTime:CFTimeInterval = CACurrentMediaTime()
    var renderFrame: CGRect {return frame}
    var pixelScale:CGFloat{ return 1 }
}
