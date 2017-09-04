//
//  Shader.swift
//  Experiments-iOS-OpenGL
//
//  Created by 0x384c0 on 8/28/17.
//  Copyright © 2017 0x384c0. All rights reserved.
//

import UIKit

class Shader{
    var
    id:GLuint!
    init(name:String,type:Int32) {
        let
        type = GLenum(type),
        shaderFolder = "shaders/",
        shaderPath = Bundle.main.path(forResource: shaderFolder + name, ofType: "glsl")!,
        shaderStringBody = try! String(contentsOfFile: shaderPath, encoding: .utf8),
        shaderTemplatePath = Bundle.main.path(forResource: shaderFolder + "_FragmentTemplate", ofType: "glsl")!,
        shaderTemplateString = try! String(contentsOfFile: shaderTemplatePath, encoding: .utf8)
        
        let shaderString:String
        if type == GLenum(GL_FRAGMENT_SHADER){
            shaderString = shaderTemplateString.replacingOccurrences(of:"SHADER_TOY_CODE_PLACEHOLDER",with: shaderStringBody)
        } else {
            shaderString = shaderStringBody
        }
        
        
        let cString = shaderString.cString(using: String.Encoding.utf8)
        var
        sourceLength = GLint(shaderString.lengthOfBytes(using: String.Encoding.utf8)),
        tempString : UnsafePointer<GLchar>? =  UnsafePointer<GLchar>(cString),
        status: GLint = 0
        //compile
        id = glCreateShader(type)
        glShaderSource(id, 1,&tempString, &sourceLength)
        glCompileShader(id)
        glGetShaderiv(id, GLenum(GL_COMPILE_STATUS), &status)
        prinGlErrors(status,id,#function)
    }
    
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
    
    class func getOpenGlesShaderText(){
        
    }
}
