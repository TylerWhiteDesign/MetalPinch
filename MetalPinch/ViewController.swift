//
//  Copyright © 2020 TylerWhiteDesign. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    var renderer: Renderer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        renderer = Renderer(metalView: view as! TouchMetalView)
        renderer.scene = Scene(withRenderer: renderer)
    }
}

