import SwiftUI
import UIKit

// MARK: - Gesture Overlay (UIKit)
/// Composant UIKit transparent qui capture TOUS les gestes de manière fiable.
/// Résout les conflits entre SwiftUI .simultaneousGesture et RealityKit hit-testing.

struct GestureOverlay: UIViewRepresentable {
    
    // MARK: - Callbacks
    var onPan: (CGPoint) -> Void
    var onPanEnded: () -> Void
    var onPinch: (CGFloat) -> Void
    var onPinchEnded: () -> Void
    var onTap: (CGPoint) -> Void
    var onDoubleTap: (CGPoint) -> Void
    
    func makeUIView(context: Context) -> GestureOverlayView {
        let view = GestureOverlayView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        
        // Pan Gesture
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        pan.maximumNumberOfTouches = 1
        view.addGestureRecognizer(pan)
        
        // Pinch Gesture
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        view.addGestureRecognizer(pinch)
        
        // Double Tap (must be added BEFORE single tap)
        let doubleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
        
        // Single Tap
        let singleTap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        singleTap.numberOfTapsRequired = 1
        singleTap.require(toFail: doubleTap) // Wait to confirm it's not a double tap
        view.addGestureRecognizer(singleTap)
        
        // Allow simultaneous gestures
        pan.delegate = context.coordinator
        pinch.delegate = context.coordinator
        
        return view
    }
    
    func updateUIView(_ uiView: GestureOverlayView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            onPan: onPan,
            onPanEnded: onPanEnded,
            onPinch: onPinch,
            onPinchEnded: onPinchEnded,
            onTap: onTap,
            onDoubleTap: onDoubleTap
        )
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var onPan: (CGPoint) -> Void
        var onPanEnded: () -> Void
        var onPinch: (CGFloat) -> Void
        var onPinchEnded: () -> Void
        var onTap: (CGPoint) -> Void
        var onDoubleTap: (CGPoint) -> Void
        
        private var lastPanLocation: CGPoint = .zero
        
        init(onPan: @escaping (CGPoint) -> Void,
             onPanEnded: @escaping () -> Void,
             onPinch: @escaping (CGFloat) -> Void,
             onPinchEnded: @escaping () -> Void,
             onTap: @escaping (CGPoint) -> Void,
             onDoubleTap: @escaping (CGPoint) -> Void) {
            self.onPan = onPan
            self.onPanEnded = onPanEnded
            self.onPinch = onPinch
            self.onPinchEnded = onPinchEnded
            self.onTap = onTap
            self.onDoubleTap = onDoubleTap
        }
        
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            switch gesture.state {
            case .began:
                lastPanLocation = gesture.location(in: gesture.view)
            case .changed:
                let currentLocation = gesture.location(in: gesture.view)
                let delta = CGPoint(
                    x: currentLocation.x - lastPanLocation.x,
                    y: currentLocation.y - lastPanLocation.y
                )
                lastPanLocation = currentLocation
                onPan(delta)
            case .ended, .cancelled:
                onPanEnded()
            default:
                break
            }
        }
        
        @objc func handlePinch(_ gesture: UIPinchGestureRecognizer) {
            switch gesture.state {
            case .changed:
                onPinch(gesture.scale)
                gesture.scale = 1.0 // Reset for delta-based updates
            case .ended, .cancelled:
                onPinchEnded()
            default:
                break
            }
        }
        
        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            onTap(location)
        }
        
        @objc func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: gesture.view)
            onDoubleTap(location)
        }
        
        // Allow simultaneous recognition
        func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                               shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
    }
}

// MARK: - Overlay View
class GestureOverlayView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Always intercept touches
        return self
    }
}
