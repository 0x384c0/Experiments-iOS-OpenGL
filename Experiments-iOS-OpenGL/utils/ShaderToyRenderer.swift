//
//  ShaderToyRenderer.swift
//  Experiments-iOS-OpenGL
//
//  Created by 0x384c0 on 8/28/17.
//  Copyright © 2017 0x384c0. All rights reserved.
//

import UIKit
import GLKit

protocol ShaderToyRenderer:class{
    var positionSlot:GLuint {get set}
    var lastTouchCoordinates:CGPoint {get set}
    var renderFrame:CGRect {get}
    var pixelScale:CGFloat { get }
    var startTime:CFTimeInterval {get set}
    var isPlaying:Bool {get set}
    //Shader inputs
    var iTime:GLint {get set}
    var iResolution:GLint {get set}
    var iMouse:GLint {get set}
    var iChannel0:GLint {get set}
    var iChannel1:GLint {get set}
    var iChannel2:GLint {get set}
    var iChannel3:GLint {get set}
    var iChannelResolution0:GLint {get set}
    var iChannelResolution1:GLint {get set}
    var iChannelResolution2:GLint {get set}
    var iChannelResolution3:GLint {get set}
}
extension ShaderToyRenderer{
    func compileShaders(shaderName:String,program:GLuint) {
        let
        vertShader = Shader(name: "_SimpleVertex", type: GL_VERTEX_SHADER),
        fragShader = Shader(name: shaderName, type: GL_FRAGMENT_SHADER)
        
        //attach
        glAttachShader(program, vertShader.id)
        glAttachShader(program, fragShader.id)
        
        // Link program.
        var status: GLint = 0
        glLinkProgram(program)
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &status)
        if status == GL_FALSE { printGlErrors(program: program) }
        glUseProgram(program)
        
        //Vertex attributes
        positionSlot = getAttribLocation( name: "Position",program:program)
        glEnableVertexAttribArray(self.positionSlot)
        
        //Fragment attributes
        iTime = getUniformLocation(name: "iTime",program:program)
        iResolution = getUniformLocation(name: "iResolution",program:program)
        iMouse = getUniformLocation(name: "iMouse",program:program)
        
        //initial setupVBO
        var vertexBuffer: GLuint = 0
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), (Vertices.count * MemoryLayout<Vertex>.size), Vertices, GLenum(GL_STATIC_DRAW))
        
        var indexBuffer: GLuint = 0
        glGenBuffers(1, &indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), (Indices.count * MemoryLayout<GLubyte>.size), Indices, GLenum(GL_STATIC_DRAW))
        
        glVertexAttribPointer(positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), nil)
        glUniform3f(iResolution, GLfloat(renderFrame.size.width * pixelScale), GLfloat(renderFrame.size.height * pixelScale), 0)
    }
    
    func render(){
        if isPlaying{
            let currentTime = CACurrentMediaTime()
            let mediaTime = Float((currentTime - startTime))
            if mediaTime > 10000 {startTime = currentTime}
            glUniform1f(iTime, mediaTime)
        }
        glUniform4f(iMouse, GLfloat(lastTouchCoordinates.x), GLfloat(lastTouchCoordinates.y), GLfloat(lastTouchCoordinates.x), GLfloat(lastTouchCoordinates.y))
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(Indices.count/MemoryLayout.size(ofValue: Indices[0])), GLenum(GL_UNSIGNED_BYTE), nil)
    }
    
    //textures
    func setupTextures(texture0:CGImage?,texture1:CGImage?,texture2:CGImage?,texture3:CGImage?,program:GLuint){
        if let texture = texture0 {
            
            iChannelResolution0 = GLint(glGetUniformLocation(program, "iChannelResolution[0]"))
            iChannel0           = GLint(glGetUniformLocation(program, "iChannel0"))
            setupTexture(
                texture,
                textureUnit: GLenum(GL_TEXTURE0),
                location: iChannel0,
                resLocation: iChannelResolution0,
                x: 0
            )
        }
        if let texture = texture1 {
            iChannelResolution1 = GLint(glGetUniformLocation(program, "iChannelResolution[1]"))
            iChannel1           = GLint(glGetUniformLocation(program, "iChannel1"))
            setupTexture(
                texture,
                textureUnit: GLenum(GL_TEXTURE1),
                location: iChannel1,
                resLocation: iChannelResolution1,
                x: 1
            )
        }
        if let texture = texture2 {
            iChannelResolution2 = GLint(glGetUniformLocation(program, "iChannelResolution[2]"))
            iChannel2           = GLint(glGetUniformLocation(program, "iChannel2"))
            setupTexture(
                texture,
                textureUnit: GLenum(GL_TEXTURE2),
                location: iChannel2,
                resLocation: iChannelResolution2,
                x: 2
            )
        }
        if let texture = texture3 {
            iChannelResolution3 = GLint(glGetUniformLocation(program, "iChannelResolution[3]"))
            iChannel3           = GLint(glGetUniformLocation(program, "iChannel3"))
            setupTexture(
                texture,
                textureUnit: GLenum(GL_TEXTURE3),
                location: iChannel3,
                resLocation: iChannelResolution3,
                x: 3
            )
        }
    }
    private func setupTexture(_ texture: CGImage,textureUnit:GLenum,location:GLint,resLocation:GLint,x: GLint){
        glActiveTexture(textureUnit)
        do {
//            print(texture.alphaInfo)
//            print(texture.bitmapInfo)
//            print(texture.width)
//            print(texture.height)
            glGetError()
            let textureInfo = try GLKTextureLoader.texture(with: texture, options: nil)
            glBindTexture(textureInfo.target,   textureInfo.name)
            glTexParameteri(textureInfo.target, GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT)
            glTexParameteri(textureInfo.target, GLenum(GL_TEXTURE_WRAP_T), GL_REPEAT)
            glTexParameteri(textureInfo.target, GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
            glTexParameteri(textureInfo.target, GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR_MIPMAP_LINEAR)
            glGenerateMipmap(textureInfo.target)
            
            glUniform1i(location, x);
            glUniform3f(resLocation, GLfloat(textureInfo.width), GLfloat(textureInfo.height), 0)
        }
        catch {
            print(GLKTextureLoaderError(_nsError: (error as NSError)))
            preconditionFailure((error as NSError).localizedDescription)
        }
        
    }
    
    func getAttribLocation(name:String, program:GLuint) -> GLuint{
        return GLuint(glGetAttribLocation(program, name))
    }
    func getUniformLocation(name:String, program:GLuint) -> GLint{
        return GLint(glGetUniformLocation(program, name))
    }
    
    var pixelScale:CGFloat{
        return UIScreen.main.scale
    }
    
    func handleDeinit(){//TODO: handleDeinit
        //        glDeleteTextures(GLsizei)
    }
    
    func printGlErrors(program:GLuint){
        var messages = "GL ERRORS:\n"
        var logLength: GLint = 0
        glGetProgramiv(program, GLenum(GL_INFO_LOG_LENGTH), &logLength)
        if logLength > 0 {
            var log: [GLchar] = [GLchar](repeating: 0, count: Int(logLength))
            glGetProgramInfoLog(program, logLength, &logLength, &log)
            
            messages += "\(String(cString: log))\n"
        }
        glDeleteProgram(program)
        preconditionFailure(messages)
    }
}

fileprivate struct Vertex {
    var Position: (CFloat, CFloat, CFloat)
    var Color: (CFloat, CFloat, CFloat, CFloat)
}

fileprivate let Vertices = [
    Vertex(Position: (1, -1, 0) , Color: (1, 0, 0, 1)),
    Vertex(Position: (1, 1, 0)  , Color: (0, 1, 0, 1)),
    Vertex(Position: (-1, 1, 0) , Color: (0, 0, 1, 1)),
    Vertex(Position: (-1, -1, 0), Color: (0, 0, 0, 1))
]

fileprivate let Indices: [GLubyte] = [//triangles
    0, 1, 2,
    2, 3, 0
]
