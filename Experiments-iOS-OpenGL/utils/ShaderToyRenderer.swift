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
    var iTimeSlot:GLint {get set}
    var iResolution:GLint {get set}
    var textureSlot:GLint {get set}
    var renderFrame:CGRect {get}
    var pixelScale:CGFloat { get }
    var startTime:CFTimeInterval {get set}
}
extension ShaderToyRenderer{
    func compileShaders(shaderName:String,program:GLuint) {
        let
        vertShader = Shader(name: "SimpleVertex", type: GL_VERTEX_SHADER),
        fragShader = Shader(name: shaderName, type: GL_FRAGMENT_SHADER)
        
        //attach
        glAttachShader(program, vertShader.id)
        glAttachShader(program, fragShader.id)
        
        // Link program.
        var status: GLint = 0
        glLinkProgram(program)
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &status)
        if status == 0 { preconditionFailure("Failed to link program: \(program)") }
        glUseProgram(program)
        
        //Vertex attributes
        positionSlot = getAttribLocation( name: "Position",program:program)
        glEnableVertexAttribArray(self.positionSlot)
        
        //Fragment attributes
        iTimeSlot = getUniformLocation(name: "iTime",program:program)
        iResolution = getUniformLocation(name: "iResolution",program:program)
        
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
        let currentTime = CACurrentMediaTime()
        let mediaTime = Float((currentTime - startTime))
        if mediaTime > 10000 {startTime = currentTime}
        glUniform1f(iTimeSlot, mediaTime)
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(Indices.count/MemoryLayout.size(ofValue: Indices[0])), GLenum(GL_UNSIGNED_BYTE), nil)
    }
    
    //textures
    func setupTextures(texture:CGImage,program:GLuint){
        textureSlot = GLint(glGetUniformLocation(program, "iChannel0"))
        setupTexture(texture)
    }
    private func setupTexture(_ texture: CGImage){
        do {
            let _ = try GLKTextureLoader.texture(with: texture, options: nil)
        } catch {
            print((error as NSError).localizedDescription)
        }
        
        let spriteTexture = try! GLKTextureLoader.texture(with: texture, options: nil)
        
        glActiveTexture(GLenum(GL_TEXTURE0));
        glBindTexture(GLenum(GL_TEXTURE_2D), spriteTexture.name);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GL_REPEAT);
        glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GL_REPEAT);
        glUniform1i(textureSlot, 0);
        
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
