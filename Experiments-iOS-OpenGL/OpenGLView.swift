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


struct Vertex {
    var Position: (CFloat, CFloat, CFloat)
    var Color: (CFloat, CFloat, CFloat, CFloat)
}

let Vertices = [
    Vertex(Position: (1, -1, 0) , Color: (1, 0, 0, 1)),
    Vertex(Position: (1, 1, 0)  , Color: (0, 1, 0, 1)),
    Vertex(Position: (-1, 1, 0) , Color: (0, 0, 1, 1)),
    Vertex(Position: (-1, -1, 0), Color: (0, 0, 0, 1))
]

let Indices: [GLubyte] = [//triangles
    0, 1, 2,
    2, 3, 0
]

class OpenGLView:UIView{
    var
    eaglLayer:CAEAGLLayer!,
    context:EAGLContext!,
    colorRenderBuffer:GLuint = 1,
    glViewIsOpaque = true
    
    
    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }
    
    
    func config(shaderName: String,textureName:String?,isOpaque:Bool = true) {
        self.textureName = textureName
        self.glViewIsOpaque = isOpaque
        backgroundColor = UIColor.clear
        setupLayer()
        setupContext()
        setupRenderBuffer()
        setupFrameBuffer()
        compileShaders(shaderName: shaderName)
        setuptextures()
        setupVBOs()
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
        link = CADisplayLink(target: self, selector: #selector(renderFrame))
        link?.add(to: RunLoop.current, forMode: .defaultRunLoopMode)
    }
    
    private func render() {
        
        renderShaders()
        
        let success = context.presentRenderbuffer(Int(GL_RENDERBUFFER))
        if !success{
            preconditionFailure("failed to presentRenderbuffer")
        }
    }
    @objc func renderFrame(){
        if resolutionDidNotSet {return}
        render()
    }
    
    deinit {
        handleDeinit()
    }
    func handleDeinit(){
        link?.invalidate()
        link = nil
    }
    
    //Shaders
    private var
    positionSlot: GLuint = 0,
    iTimeSlot: GLint = 0,
    iResolution: GLint = 0
    private func compileShader(type: GLenum ,shaderName: String!) -> GLuint{
        
        var shader : GLuint!
        var status : GLint = 0
        var source : UnsafePointer<GLchar>?
        
        let shaderFolder = "shaders/"
        let shaderPath = Bundle.main.path(forResource: shaderFolder + shaderName, ofType: "glsl")!
        let shaderStringTmp = try! String(contentsOfFile: shaderPath, encoding: .utf8)
        
        let shaderString:String
        if type == GLenum(GL_FRAGMENT_SHADER){
            shaderString = shaderStringTmp
                .replacingOccurrences(of: "vec2 ",          with: "highp vec2 ")
                .replacingOccurrences(of: "vec3 ",          with: "highp vec3 ")
                .replacingOccurrences(of: "vec4 ",          with: "highp vec4 ")
                .replacingOccurrences(of: "mat2 ",          with: "highp mat2 ")
                .replacingOccurrences(of: "mat3 ",          with: "highp mat3 ")
                .replacingOccurrences(of: "mat4 ",          with: "highp mat4 ")
                .replacingOccurrences(of: "float ",         with: "highp float ")
                .replacingOccurrences(of: "ihighp ",        with: "highp i")
                .replacingOccurrences(of: "highp highp ",   with: "highp ")
        } else {
            shaderString = shaderStringTmp
        }
        
        source = UnsafePointer<GLchar>(shaderString)
        var sourceLength = GLint(shaderString.lengthOfBytes(using: String.Encoding.utf8))
        if source == nil {
            preconditionFailure("failed to compileShader: source == nil")
        }
        
        shader  = glCreateShader(type)
        let cString = shaderString.cString(using: String.Encoding.utf8)
        var tempString : UnsafePointer<GLchar>? =  UnsafePointer<GLchar>(cString)
        glShaderSource(shader, 1,&tempString, &sourceLength)
        glCompileShader(shader)
        
        glGetShaderiv(shader, GLenum(GL_COMPILE_STATUS), &status)
        
        prinGlErrors(status,shader,#function)
        
        return shader
    }
    
    private func compileShaders(shaderName:String) {
        
        // Compile our vertex and fragment shaders.
        let
        vertexShader = compileShader(type: GLenum(GL_VERTEX_SHADER), shaderName: "SimpleVertex"),
        fragmentShader = compileShader(type: GLenum(GL_FRAGMENT_SHADER), shaderName: shaderName)
        
        // Call glCreateProgram, glAttachShader, and glLinkProgram to link the vertex and fragment shaders into a complete program.
        let programHandle: GLuint = glCreateProgram()
        glAttachShader(programHandle, vertexShader)
        glAttachShader(programHandle, fragmentShader)
        glLinkProgram(programHandle)
        
        // Check for any errors.
        var linkSuccess: GLint = GLint()
        glGetProgramiv(programHandle, GLenum(GL_LINK_STATUS), &linkSuccess)
        
        prinGlErrors(linkSuccess,programHandle,#function)
        
        // Call glUseProgram to tell OpenGL to actually use this program when given vertex info.
        glUseProgram(programHandle)
        
        // Finally, call glGetAttribLocation to get a pointer to the input values for the vertex shader, so we
        //  can set them in code. Also call glEnableVertexAttribArray to enable use of these arrays (they are disabled by default).
        self.positionSlot = GLuint(glGetAttribLocation(programHandle, "Position"))
        glEnableVertexAttribArray(self.positionSlot)
        
        
        iTimeSlot = GLint(glGetUniformLocation(programHandle, "iTime"))
        iResolution = GLint(glGetUniformLocation(programHandle, "iResolution"))
        addTextureToShader(programHandle)
    }
    private func setupVBOs() {
        var vertexBuffer: GLuint = 0
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), (Vertices.count * MemoryLayout<Vertex>.size), Vertices, GLenum(GL_STATIC_DRAW))
        
        var indexBuffer: GLuint = 0
        glGenBuffers(1, &indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), (Indices.count * MemoryLayout<GLubyte>.size), Indices, GLenum(GL_STATIC_DRAW))
    }
    
    private var isShadersNotRendered = true
    private func renderShaders(){
        //shaders
        setVariablesToShaders()
        
        if isShadersNotRendered{
            isShadersNotRendered = false
            glVertexAttribPointer(positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), nil)
        }
        
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(Indices.count/MemoryLayout.size(ofValue: Indices[0])), GLenum(GL_UNSIGNED_BYTE), nil)
    }
    private var resolutionDidNotSet = true
    
    
    var startTime = CACurrentMediaTime()
    private func setVariablesToShaders(){
        let currentTime = CACurrentMediaTime()
        let mediaTime = Float((currentTime - startTime))
        if mediaTime > 10000 {startTime = currentTime}
        glUniform1f(iTimeSlot, mediaTime)
        if resolutionDidNotSet{
            glUniform3f(iResolution, GLfloat(frame.size.width), GLfloat(frame.size.height), 0)
            resolutionDidNotSet = false
        }
    }
    
    //textures
    var
    textureName:String?,
    textureSlot:GLint = 0
    private func addTextureToShader(_ programHandle:GLuint){
        if textureName == nil {return}
        textureSlot = GLint(glGetUniformLocation(programHandle, "iChannel0"))
    }
    private func setuptextures(){
        if let textureName = textureName{
            setupTexture(textureName)
        }
    }
    
    private func setupTexture(_ fileName: String){
        do {
            let _ = try GLKTextureLoader.texture(with: UIImage(named:fileName)!.cgImage!, options: nil)
        } catch {
            print((error as NSError).localizedDescription)
        }
        
        let spriteTexture = try! GLKTextureLoader.texture(with: UIImage(named:fileName)!.cgImage!, options: nil)
        
        glActiveTexture(GLenum(GL_TEXTURE0));
        glBindTexture(GLenum(GL_TEXTURE_2D), spriteTexture.name);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_REPEAT);
        glUniform1i(textureSlot, 0);
        
    }
}

extension OpenGLView{
    fileprivate func prinGlErrors(_ status:Int32,_ shader:GLuint,_ funcName:String){
        if status == GL_FALSE {
            var length: GLint = 0;
            glGetShaderiv(shader, GLenum(GL_INFO_LOG_LENGTH), &length);
            let errorLog = unsafeBitCast(malloc(Int(length) * MemoryLayout<GLchar>.size), to:UnsafeMutablePointer<GLchar>.self)
            glGetShaderInfoLog(shader, length, &length, errorLog)
            let err = String(cString: errorLog)
            free(errorLog)
            glDeleteShader(shader)
            preconditionFailure("failed to \(funcName):\n\(err)")
        }
    }
}
