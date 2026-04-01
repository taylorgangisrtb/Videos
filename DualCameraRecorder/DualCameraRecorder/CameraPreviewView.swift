import AVFoundation
import SwiftUI

/// A SwiftUI-compatible view that hosts an AVCaptureVideoPreviewLayer.
struct CameraPreviewView: UIViewRepresentable {
    let previewLayer: AVCaptureVideoPreviewLayer

    func makeUIView(context: Context) -> PreviewUIView {
        let view = PreviewUIView()
        view.backgroundColor = .black
        view.layer.addSublayer(previewLayer)
        return view
    }

    func updateUIView(_ uiView: PreviewUIView, context: Context) {
        previewLayer.frame = uiView.bounds
    }
}

final class PreviewUIView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        // Keep any sublayer (the preview layer) sized to the view
        layer.sublayers?.forEach { $0.frame = bounds }
    }
}
