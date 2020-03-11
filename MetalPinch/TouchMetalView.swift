//
//  Copyright © 2020 TylerWhiteDesign. All rights reserved.
//

import MetalKit

protocol TouchMetalViewDelegate: class
{
    func touchMetalView(_ touchMetalView: TouchMetalView, didPinchWithPinchGestureRecognizer pinchGestureRecognizer: UIPinchGestureRecognizer)
    func touchMetalView(_ touchMetalView: TouchMetalView, didPanWithPanGestureRecognizer panGestureRecognizer: UIPanGestureRecognizer)
}

class TouchMetalView: MTKView
{
    weak var touchDelegate: TouchMetalViewDelegate?
    
    //MARK: Init
    
    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        setup()
    }
    
    required init(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    //MARK: - Private
    
    private func setup() {
        isMultipleTouchEnabled = true
        
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinch))
        addGestureRecognizer(pinchGestureRecognizer)
        pinchGestureRecognizer.delegate = self
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(pan))
        panGestureRecognizer.maximumNumberOfTouches = 2
        panGestureRecognizer.delegate = self
        addGestureRecognizer(panGestureRecognizer)
    }
    
    //MARK: - Actions
    
    @objc private func pinch(_ pinchGestureRecognizer: UIPinchGestureRecognizer) {
        touchDelegate?.touchMetalView(self, didPinchWithPinchGestureRecognizer: pinchGestureRecognizer)
    }

    @objc private func pan(_ panGestureRecognizer: UIPanGestureRecognizer) {
        touchDelegate?.touchMetalView(self, didPanWithPanGestureRecognizer: panGestureRecognizer)
    }
}

extension TouchMetalView: UIGestureRecognizerDelegate
{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
