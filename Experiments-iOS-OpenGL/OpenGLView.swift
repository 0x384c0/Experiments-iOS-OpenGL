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


struct Vertex {
    var Position: (CFloat, CFloat, CFloat)
    var Color: (CFloat, CFloat, CFloat, CFloat)
}

var Vertices = [
    Vertex(Position: (1, -1, 0) , Color: (1, 0, 0, 1)),
    Vertex(Position: (1, 1, 0)  , Color: (0, 1, 0, 1)),
    Vertex(Position: (-1, 1, 0) , Color: (0, 0, 1, 1)),
    Vertex(Position: (-1, -1, 0), Color: (0, 0, 0, 1))
]

var Indices: [GLubyte] = [//triangles
    0, 1, 2,
    2, 3, 0
]

class OpenGLView:UIView{
    var
    eaglLayer:CAEAGLLayer!,
    context:EAGLContext!,
    colorRenderBuffer:GLuint = 1,
    skipFrames = 0
    
    
    override class var layerClass: AnyClass {
        return CAEAGLLayer.self
    }
    
    
    func config(shaderName: String,textureName:String?,skipFrames:Int) {
        self.textureName = textureName
        self.skipFrames = skipFrames
        self.skippedFrames = skipFrames
        backgroundColor = UIColor.clear
        setupLayer()
        setupContext()
        setupRenderBuffer()
        setupFrameBuffer()
        compileShaders(shaderName: shaderName)
        setupVBOs()
        render(nil)
        setupDisplayLink()
    }
    
    private func setupLayer(){
        eaglLayer = layer as! CAEAGLLayer
        eaglLayer.isOpaque = skipFrames != 0 //make transparent
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
    private func setupDisplayLink(){
        let link = CADisplayLink(target: self, selector: #selector(render(_:)))
        link.add(to: RunLoop.current, forMode: .defaultRunLoopMode)
    }
    
    private var skippedFrames = 0
    @objc private func render(_ obj:Any?) {
        if skippedFrames >= skipFrames{
            skippedFrames = 0
        } else {
            skippedFrames += 1
            return
        }
        //background color
        glClearColor(0, 0, 0, 0.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
        
        renderShaders()
        renderTextures()
        
        let success = context.presentRenderbuffer(Int(GL_RENDERBUFFER))
        if !success{
            preconditionFailure("failed to presentRenderbuffer")
        }
        
    }
    
    //Shaders
    private var
    positionSlot: GLuint = 0,
    colorSlot: GLuint = 0,
    iTimeSlot: GLint = 0,
    iResolution: GLint = 0
    private func compileShader(type: GLenum ,shaderName: String!) -> GLuint{
        
        var shader : GLuint!
        var status : GLint = 0
        var source : UnsafePointer<GLchar>?
        
        let shaderFolder = "shaders/"
        
        let shaderPath = Bundle.main.path(forResource: shaderFolder + shaderName, ofType: "glsl")!
        let ShaderString = try! String(contentsOfFile: shaderPath, encoding: .utf8)
        
        
        source = UnsafePointer<GLchar>(ShaderString)
        var sourceLength = GLint(ShaderString.lengthOfBytes(using: String.Encoding.utf8))
        if source == nil {
            preconditionFailure("failed to compileShader: source == nil")
        }
        
        shader  = glCreateShader(type)
        let cString = ShaderString.cString(using: String.Encoding.utf8)
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
        self.colorSlot = GLuint(glGetAttribLocation(programHandle, "SourceColor"))
        glEnableVertexAttribArray(self.positionSlot)
        glEnableVertexAttribArray(self.colorSlot)
        
        
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
    private func renderShaders(){
        //shaders
        setVariablesToShaders()
        glViewport(0, 0, GLint(self.frame.size.width), GLint(self.frame.size.height));
        glVertexAttribPointer(positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), nil)
        glVertexAttribPointer(colorSlot, 4, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), UnsafePointer<Float>(bitPattern: 3 * MemoryLayout<Float>.size))
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(Indices.count/MemoryLayout.size(ofValue: Indices[0])), GLenum(GL_UNSIGNED_BYTE), nil)
    }
    private func setVariablesToShaders(){
        glUniform1f(iTimeSlot, GLfloat(CACurrentMediaTime()))
        glUniform3f(iResolution, GLfloat(frame.size.width), GLfloat(frame.size.height), 0)
    }
    
    //textures
    var
    textureName:String?,
    texture:GLuint = 0,
    textureUniform:GLuint = 0
    private func addTextureToShader(_ programHandle:GLuint){
        if textureName == nil {return}
        textureUniform = GLuint(glGetUniformLocation(programHandle, "iChannel0"))
    }
    private func setuptextures(){
        if let textureName = textureName{
            texture = setupTexture(textureName)
        }
    }
    private func setupTexture(_ fileName: String) -> GLuint{
        let folder = "presets/"
        let spriteImage: CGImage? = UIImage(named: folder + fileName + ".png")?.cgImage
        if (spriteImage == nil) {
            preconditionFailure("Failed to load image!")
        }
        let width: Int = spriteImage!.width
        let height: Int = spriteImage!.height
        //let spriteData = UnsafeMutablePointer<GLubyte>(calloc(Int(UInt(CGFloat(width) * CGFloat(height) * 4)), sizeof(GLubyte)))
        //gz change
        let spriteData = UnsafeMutablePointer<GLubyte>.allocate(capacity:Int(UInt(CGFloat(width) * CGFloat(height) * 4)))
        
        
        let spriteContext: CGContext = CGContext(data: spriteData,
                                                 width: width,
                                                 height: height,
                                                 bitsPerComponent: 8,
                                                 bytesPerRow: width*4,
                                                 space: spriteImage!.colorSpace!,
                                                 bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        //spriteContext.draw(in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)), image: spriteImage!)
        //gz change
        spriteContext.draw(spriteImage!,
                           in: CGRect(x: 0,
                                      y: 0,
                                      width: CGFloat(width),
                                      height: CGFloat(height)),
                           byTiling : true
        )
        
        var texName: GLuint = GLuint()
        glGenTextures(1, &texName)
        glBindTexture(GLenum(GL_TEXTURE_2D), texName)
        
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_NEAREST)
        glTexImage2D(GLenum(GL_TEXTURE_2D), 0, GL_RGBA, GLsizei(width), GLsizei(height), 0, GLenum(GL_RGBA), UInt32(GL_UNSIGNED_BYTE), spriteData)
        
        free(spriteData)
        return texName
        
    }
    
    private func renderTextures(){
        if textureName == nil {return}
        glActiveTexture(GLenum(GL_TEXTURE0));
        glBindTexture(GLenum(GL_TEXTURE_2D), texture);
        glUniform1i(GLint(textureUniform), 0);
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
