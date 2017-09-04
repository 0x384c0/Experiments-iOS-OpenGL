//
//  ShaderSelectViewController.swift
//  Experiments-iOS-OpenGL
//
//  Created by 0x384c0 on 8/24/17.
//  Copyright © 2017 0x384c0. All rights reserved.
//
import UIKit

class ShaderSelectViewController: UITableViewController {
    var isFullScreen = false
    @IBAction func fullScreenSwitch(_ sender: UISwitch) {
        isFullScreen = sender.isOn
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let shaderName:String! = tableView.cellForRow(at: indexPath)?.textLabel?.text
        
        var settings = ShaderSettings(shaderName: shaderName, texture0Name: nil, texture1Name: nil, texture2Name: nil, isOpaque: true)
        
        switch shaderName {
        case "furball":
            settings.texture0Name = "RGBA_noize_small"
            settings.texture1Name = "RGBA_noize_small"
        case "VoxelEdges":
            settings.texture0Name = "RGBA_noize_medium"
            settings.texture1Name = "abstract_1"
            settings.texture2Name = "lichen"
        case "RayMarchingExperimentN35":
            settings.texture0Name = "ufizzi_gallery_blured"
            settings.texture1Name = "Organic_2"
        case "Clouds","TextureFragment","SunSurface","CloudTen","PlasmaGlobe":
            settings.texture0Name = "RGBA_noize_medium"
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
    texture0Name:String?,
    texture1Name:String?,
    texture2Name:String?,
    isOpaque:Bool
}

extension UIViewController{
    class var segueID:String {return String(describing:self)}
}
