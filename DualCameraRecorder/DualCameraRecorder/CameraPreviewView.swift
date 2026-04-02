import AVFoundation
import SwiftUI

/// A SwiftUI-compatible view that hosts an AVCaptureVideoPreviewLayer.
///
/// The preview layer is attached in `updateUIView` (which runs after the view
/// has been laid out and has non-zero bounds) and is resized on every
/// `layoutSubviews` call to stay in sync with SwiftUI geometry changes.
struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> PreviewContainerView {
        // Return an empty container — layer is attached in updateUIView
        // once the view has its real bounds.
        PreviewContainerView()
    }

    func updateUIView(_ uiView: PreviewContainerView, context: Context) {
        uiView.attach(previewLayer)
    }
}

final class PreviewContainerView: UIView {
    private var attachedLayer: AVCaptureVideoPreviewLayer?

    /// Attaches the preview layer and sizes it to the current bounds.
    /// Safe to call multiple times with the same layer — just refreshes the frame.
    func attach(_ layer: AVCaptureVideoPreviewLayer) {
        if layer !== attachedLayer {
            attachedLayer?.removeFromSuperlayer()
            attachedLayer = layer
            self.layer.insertSublayer(layer, at: 0)
        }
        syncFrame()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        syncFrame()
    }

    private func syncFrame() {
        guard let layer = attachedLayer, !bounds.isEmpty else { return }
        // Disable implicit CALayer animations so the preview snaps to its
        // frame immediately instead of animating from CGRect.zero.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.frame = bounds
        CATransaction.commit()
    }
}
