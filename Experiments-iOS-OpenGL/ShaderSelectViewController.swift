//
//  ShaderSelectViewController.swift
//  Experiments-iOS-OpenGL
//
//  Created by 0x384c0 on 8/24/17.
//  Copyright © 2017 0x384c0. All rights reserved.
//
import UIKit

class ShaderSelectViewController: UITableViewController {
    var isFullScreen = true
    @IBAction func fullScreenSwitch(_ sender: UISwitch) {
        isFullScreen = sender.isOn
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let shaderName:String! = tableView.cellForRow(at: indexPath)?.textLabel?.text
        
        var settings = ShaderSettings(shaderName: shaderName, textureName: nil, isOpaque: true)
        
        switch shaderName {
        case "Clouds","TextureFragment","SunSurface":
            settings.textureName = "RGBA_noize_med"
        case "SimpleFragment":
            settings.isOpaque = false
        default: break
        }
        
        if isFullScreen{
            performSegue(withIdentifier: ShaderGLKitViewController.segueID, sender: settings)
        } else {
            performSegue(withIdentifier: ShaderViewController.segueID, sender: settings)
        }
        
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier ?? "" {
        case ShaderViewController.segueID:
            let
            vc = segue.destination as! ShaderViewController,
            settings = sender as! ShaderSettings
            vc.setup(settings)
        case ShaderGLKitViewController.segueID:
            let
            vc = segue.destination as! ShaderGLKitViewController,
            settings = sender as! ShaderSettings
            vc.setup(settings)
        default: break
            
        }
    }
}

struct ShaderSettings {
    var
    shaderName:String,
    textureName:String?,
    isOpaque:Bool
}

extension UIViewController{
    class var segueID:String {return String(describing:self)}
}
