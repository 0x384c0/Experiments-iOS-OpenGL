//
//  ShaderGLKitViewController.swift
//  Experiments-iOS-OpenGL
//
//  Created by 0x384c0 on 8/26/17.
//  Copyright © 2017 0x384c0. All rights reserved.
//

import GLKit

class ShaderGLKitViewController: GLKViewController {
    var glView:GLKView{return view as! GLKView}
    var program: GLuint!
    
    var vertexArray: GLuint = 0
    var vertexBuffer: GLuint = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        glView.context = EAGLContext(api: .openGLES2)
        EAGLContext.setCurrent(glView.context)
        
        loadShaders()
    }
    
    
    private var
    positionSlot: GLuint = 0,
    colorSlot: GLuint = 0,
    iTimeSlot: GLint = 0,
    iResolution: GLint = 0
    private func loadShaders(){
        program = glCreateProgram()
        let
        vertShader = Shader(name: "SimpleVertex", type: GL_VERTEX_SHADER),
        fragShader = Shader(name: "Veryfastproceduralocean", type: GL_FRAGMENT_SHADER)
        
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
        positionSlot = getAttribLocation( "Position")
        glEnableVertexAttribArray(self.positionSlot)
        
        //Fragment attributes
        iTimeSlot = getUniformLocation("iTime")
        iResolution = getUniformLocation("iResolution")
        setupShaderVars()
        
    }
    
    private func setupShaderVars() {
        var vertexBuffer: GLuint = 0
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        glBufferData(GLenum(GL_ARRAY_BUFFER), (Vertices.count * MemoryLayout<Vertex>.size), Vertices, GLenum(GL_STATIC_DRAW))
        
        var indexBuffer: GLuint = 0
        glGenBuffers(1, &indexBuffer)
        glBindBuffer(GLenum(GL_ELEMENT_ARRAY_BUFFER), indexBuffer)
        glBufferData(GLenum(GL_ELEMENT_ARRAY_BUFFER), (Indices.count * MemoryLayout<GLubyte>.size), Indices, GLenum(GL_STATIC_DRAW))
        
        
        glVertexAttribPointer(positionSlot, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(MemoryLayout<Vertex>.size), nil)
        glUniform3f(iResolution, GLfloat(view.frame.size.width * UIScreen.main.scale), GLfloat(view.frame.size.height * UIScreen.main.scale), 0)
    }
    
    
    private func getAttribLocation(_ name:String) -> GLuint{
        return GLuint(glGetAttribLocation(program, name))
    }
    private func getUniformLocation(_ name:String) -> GLint{
        return GLint(glGetUniformLocation(program, name))
    }
    
    override func glkView(_ view: GLKView, drawIn rect: CGRect) {
        glUniform1f(iTimeSlot, GLfloat(CACurrentMediaTime()))
        glDrawElements(GLenum(GL_TRIANGLES), GLsizei(Indices.count/MemoryLayout.size(ofValue: Indices[0])), GLenum(GL_UNSIGNED_BYTE), nil)
    }
    
}

class Shader{
    var
    id:GLuint!
    init(name:String,type:Int32) {
        let
        type = GLenum(type),
        shaderFolder = "shaders/",
        shaderPath = Bundle.main.path(forResource: shaderFolder + name, ofType: "glsl")!,
        shaderStringTmp = try! String(contentsOfFile: shaderPath, encoding: .utf8)
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
}


extension String{
    var utf8:String{
        return String(describing: cString(using: .utf8))
    }
}
