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

class OpenGLView:UIView{
    var
    eaglLayer:CAEAGLLayer!,
    context:EAGLContext!,
    colorRenderBuffer:GLuint = 1
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.config()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)!
        self.config()
    }
    
    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }
    
    
    private func config() {
        backgroundColor = UIColor.clear
        self.setupLayer()
        self.setupContext()
        self.setupRenderBuffer()
        self.setupFrameBuffer()
        self.render()
    }
    
    private func setupLayer(){
        eaglLayer = layer as! CAEAGLLayer
        eaglLayer.isOpaque = true
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
    
    private func render() {
        glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        let success = context?.presentRenderbuffer(Int(GL_RENDERBUFFER))
        if !success!{
            preconditionFailure("failed to presentRenderbuffer")
        }
    }
    
}
