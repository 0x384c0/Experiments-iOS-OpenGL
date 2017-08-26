//
//  ShaderSelectViewController.swift
//  Experiments-iOS-OpenGL
//
//  Created by 0x384c0 on 8/24/17.
//  Copyright © 2017 0x384c0. All rights reserved.
//
import UIKit

class ShaderSelectViewController: UITableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let shaderName = tableView.cellForRow(at: indexPath)?.textLabel?.text
        performSegue(withIdentifier: ShaderViewController.segueID, sender: shaderName!)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier ?? "" {
        case ShaderViewController.segueID:
            
            let
            vc = segue.destination as! ShaderViewController,
            shaderName = sender as! String
            
            vc.setup(shaderName: shaderName)
        default: break
            
        }
    }
}
