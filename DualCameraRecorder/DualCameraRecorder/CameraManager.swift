import AVFoundation
import Photos

enum CameraError: LocalizedError {
    case multiCamNotSupported
    case cameraUnavailable(String)
    case configurationFailed(String)

    var errorDescription: String? {
        switch self {
        case .multiCamNotSupported:
            return "Multi-camera capture is not supported on this device (requires iPhone XS or later)."
        case .cameraUnavailable(let detail):
            return "Camera unavailable: \(detail)"
        case .configurationFailed(let detail):
            return "Configuration failed: \(detail)"
        }
    }
}

class CameraManager: NSObject, ObservableObject {

    // MARK: - Session

    let session = AVCaptureMultiCamSession()
    private let sessionQueue = DispatchQueue(label: "com.dualcamera.session", qos: .userInitiated)

    // MARK: - Inputs

    private var backCameraInput: AVCaptureDeviceInput?
    private var frontCameraInput: AVCaptureDeviceInput?

    // MARK: - Outputs

    // Back camera → horizontal (landscape) recording
    private let backMovieOutput = AVCaptureMovieFileOutput()
    // Front camera → vertical (portrait) recording
    private let frontMovieOutput = AVCaptureMovieFileOutput()

    // MARK: - Preview Layers

    private(set) var backPreviewLayer: AVCaptureVideoPreviewLayer?
    private(set) var frontPreviewLayer: AVCaptureVideoPreviewLayer?

    // MARK: - Published State

    @Published var isRecording = false
    @Published var isConfigured = false
    @Published var permissionDenied = false
    @Published var errorMessage: String?
    @Published var statusMessage: String = ""

    // MARK: - Recording Tracking

    private let saveLock = NSLock()
    private var backOutputURL: URL?
    private var frontOutputURL: URL?
    private var backFinished = false
    private var frontFinished = false
    private var recordingError: Error?

    // MARK: - Setup

    func configure() {
        guard AVCaptureMultiCamSession.isMultiCamSupported else {
            DispatchQueue.main.async {
                self.errorMessage = CameraError.multiCamNotSupported.localizedDescription
            }
            return
        }

        requestPermissions { [weak self] granted in
            guard let self else { return }
            if granted {
                self.sessionQueue.async { self.setupSession() }
            } else {
                DispatchQueue.main.async { self.permissionDenied = true }
            }
        }
    }

    private func requestPermissions(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { videoGranted in
            guard videoGranted else { completion(false); return }
            AVCaptureDevice.requestAccess(for: .audio) { audioGranted in
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { _ in
                    completion(audioGranted)
                }
            }
        }
    }

    private func setupSession() {
        session.beginConfiguration()
        defer { session.commitConfiguration() }

        do {
            // ── Back Camera ────────────────────────────────────────────────
            guard let backDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .back
            ) else {
                throw CameraError.cameraUnavailable("No back wide-angle camera found")
            }

            try configure4K60fps(on: backDevice)

            let backInput = try AVCaptureDeviceInput(device: backDevice)
            guard session.canAddInput(backInput) else {
                throw CameraError.configurationFailed("Cannot add back camera input")
            }
            session.addInputWithNoConnections(backInput)
            backCameraInput = backInput

            // ── Front Camera ───────────────────────────────────────────────
            guard let frontDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .front
            ) else {
                throw CameraError.cameraUnavailable("No front wide-angle camera found")
            }

            configureBestAvailable60fps(on: frontDevice)

            let frontInput = try AVCaptureDeviceInput(device: frontDevice)
            guard session.canAddInput(frontInput) else {
                throw CameraError.configurationFailed("Cannot add front camera input")
            }
            session.addInputWithNoConnections(frontInput)
            frontCameraInput = frontInput

            // ── Outputs ────────────────────────────────────────────────────
            guard session.canAddOutput(backMovieOutput) else {
                throw CameraError.configurationFailed("Cannot add back movie output")
            }
            session.addOutputWithNoConnections(backMovieOutput)

            guard session.canAddOutput(frontMovieOutput) else {
                throw CameraError.configurationFailed("Cannot add front movie output")
            }
            session.addOutputWithNoConnections(frontMovieOutput)

            // ── Video Ports ───────────────────────────────────────────────
            guard let backVideoPort = backInput.ports(
                for: .video,
                sourceDeviceType: backDevice.deviceType,
                sourceDevicePosition: .back
            ).first else {
                throw CameraError.configurationFailed("Cannot get back camera video port")
            }

            guard let frontVideoPort = frontInput.ports(
                for: .video,
                sourceDeviceType: frontDevice.deviceType,
                sourceDevicePosition: .front
            ).first else {
                throw CameraError.configurationFailed("Cannot get front camera video port")
            }

            // ── Back → Horizontal (landscape) output ──────────────────────
            let backConnection = AVCaptureConnection(
                inputPorts: [backVideoPort],
                output: backMovieOutput
            )
            if backConnection.isVideoRotationAngleSupported(0) {
                backConnection.videoRotationAngle = 0   // landscape
            }
            guard session.canAddConnection(backConnection) else {
                throw CameraError.configurationFailed("Cannot add back video connection")
            }
            session.addConnection(backConnection)

            // ── Front → Vertical (portrait) output ────────────────────────
            let frontConnection = AVCaptureConnection(
                inputPorts: [frontVideoPort],
                output: frontMovieOutput
            )
            if frontConnection.isVideoRotationAngleSupported(90) {
                frontConnection.videoRotationAngle = 90  // portrait
            }
            if frontConnection.isVideoMirroringSupported {
                frontConnection.isVideoMirrored = true   // selfie-style
            }
            guard session.canAddConnection(frontConnection) else {
                throw CameraError.configurationFailed("Cannot add front video connection")
            }
            session.addConnection(frontConnection)

            // ── Audio → Back output only ───────────────────────────────────
            if let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               session.canAddInput(audioInput) {
                session.addInputWithNoConnections(audioInput)
                if let audioPort = audioInput.ports(
                    for: .audio,
                    sourceDeviceType: audioDevice.deviceType,
                    sourceDevicePosition: .unspecified
                ).first {
                    let audioConnection = AVCaptureConnection(
                        inputPorts: [audioPort],
                        output: backMovieOutput
                    )
                    if session.canAddConnection(audioConnection) {
                        session.addConnection(audioConnection)
                    }
                }
            }

            // ── Preview Layers ─────────────────────────────────────────────
            let backPreview = AVCaptureVideoPreviewLayer(sessionWithNoConnection: session)
            backPreview.videoGravity = .resizeAspect
            let backPreviewConn = AVCaptureConnection(
                inputPort: backVideoPort,
                videoPreviewLayer: backPreview
            )
            if backPreviewConn.isVideoRotationAngleSupported(0) {
                backPreviewConn.videoRotationAngle = 0
            }
            if session.canAddConnection(backPreviewConn) {
                session.addConnection(backPreviewConn)
            }

            let frontPreview = AVCaptureVideoPreviewLayer(sessionWithNoConnection: session)
            frontPreview.videoGravity = .resizeAspect
            let frontPreviewConn = AVCaptureConnection(
                inputPort: frontVideoPort,
                videoPreviewLayer: frontPreview
            )
            if frontPreviewConn.isVideoRotationAngleSupported(90) {
                frontPreviewConn.videoRotationAngle = 90
            }
            if frontPreviewConn.isVideoMirroringSupported {
                frontPreviewConn.isVideoMirrored = true
            }
            if session.canAddConnection(frontPreviewConn) {
                session.addConnection(frontPreviewConn)
            }

            DispatchQueue.main.async {
                self.backPreviewLayer = backPreview
                self.frontPreviewLayer = frontPreview
            }

        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
            return
        }

        session.startRunning()
        DispatchQueue.main.async { self.isConfigured = true }
    }

    // MARK: - Format Configuration

    /// Sets the device to the best 4K (3840×2160) 60 fps format available.
    /// Falls back to best 1080p 60 fps if 4K 60 fps is unavailable.
    private func configure4K60fps(on device: AVCaptureDevice) throws {
        let format = find4K60(device: device) ?? findBest60fps(device: device)
        guard let format else { return }
        try device.lockForConfiguration()
        device.activeFormat = format
        device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 60)
        device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 60)
        device.unlockForConfiguration()
    }

    /// Configures the best available high-frame-rate format (no throw).
    private func configureBestAvailable60fps(on device: AVCaptureDevice) {
        let format = find4K60(device: device) ?? findBest60fps(device: device)
        guard let format else { return }
        try? device.lockForConfiguration()
        device.activeFormat = format
        device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: 60)
        device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: 60)
        device.unlockForConfiguration()
    }

    private func find4K60(device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        device.formats.last { format in
            let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            let has60 = format.videoSupportedFrameRateRanges.contains { $0.maxFrameRate >= 60 }
            return dims.width == 3840 && dims.height == 2160 && has60
        }
    }

    private func findBest60fps(device: AVCaptureDevice) -> AVCaptureDevice.Format? {
        device.formats
            .filter { format in
                let dims = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                let has60 = format.videoSupportedFrameRateRanges.contains { $0.maxFrameRate >= 60 }
                return dims.width >= 1920 && has60
            }
            .max { a, b in
                let da = CMVideoFormatDescriptionGetDimensions(a.formatDescription)
                let db = CMVideoFormatDescriptionGetDimensions(b.formatDescription)
                return da.width < db.width
            }
    }

    // MARK: - Recording

    func startRecording() {
        guard !isRecording else { return }

        saveLock.lock()
        backFinished = false
        frontFinished = false
        recordingError = nil
        let backURL = makeURL(prefix: "horizontal")
        let frontURL = makeURL(prefix: "vertical")
        backOutputURL = backURL
        frontOutputURL = frontURL
        saveLock.unlock()

        sessionQueue.async {
            self.backMovieOutput.startRecording(to: backURL, recordingDelegate: self)
            self.frontMovieOutput.startRecording(to: frontURL, recordingDelegate: self)
        }

        DispatchQueue.main.async {
            self.isRecording = true
            self.statusMessage = "Recording…"
        }
    }

    func stopRecording() {
        guard isRecording else { return }
        sessionQueue.async {
            self.backMovieOutput.stopRecording()
            self.frontMovieOutput.stopRecording()
        }
        DispatchQueue.main.async {
            self.isRecording = false
            self.statusMessage = "Saving to Camera Roll…"
        }
    }

    private func makeURL(prefix: String) -> URL {
        let name = "\(prefix)_\(Int(Date().timeIntervalSince1970)).mov"
        return FileManager.default.temporaryDirectory.appendingPathComponent(name)
    }

    // MARK: - Save

    private func checkAndSaveBothIfDone() {
        saveLock.lock()
        let done = backFinished && frontFinished
        let err = recordingError
        let bURL = backOutputURL
        let fURL = frontOutputURL
        saveLock.unlock()

        guard done else { return }

        if let err {
            DispatchQueue.main.async {
                self.errorMessage = "Recording error: \(err.localizedDescription)"
                self.statusMessage = ""
            }
            return
        }

        saveToPhotoLibrary(backURL: bURL, frontURL: fURL)
    }

    private func saveToPhotoLibrary(backURL: URL?, frontURL: URL?) {
        PHPhotoLibrary.shared().performChanges({
            if let url = backURL {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }
            if let url = frontURL {
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            }
        }, completionHandler: { success, error in
            DispatchQueue.main.async {
                if success {
                    self.statusMessage = "Saved! Check your Camera Roll."
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                        self.statusMessage = ""
                    }
                } else {
                    self.errorMessage = "Save failed: \(error?.localizedDescription ?? "Unknown error")"
                    self.statusMessage = ""
                }
            }

            // Clean up temp files
            [backURL, frontURL].compactMap { $0 }.forEach {
                try? FileManager.default.removeItem(at: $0)
            }
        })
    }
}

// MARK: - AVCaptureFileOutputRecordingDelegate

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(
        _ output: AVCaptureFileOutput,
        didFinishRecordingTo outputFileURL: URL,
        from connections: [AVCaptureConnection],
        error: Error?
    ) {
        saveLock.lock()
        if let error {
            // Ignore the "recording stopped" error code which is not a real failure
            let nsError = error as NSError
            if nsError.domain != AVFoundationErrorDomain ||
               nsError.code != AVError.Code.sessionWasInterrupted.rawValue {
                recordingError = error
            }
        }
        if output === backMovieOutput { backFinished = true }
        if output === frontMovieOutput { frontFinished = true }
        saveLock.unlock()

        checkAndSaveBothIfDone()
    }
}
