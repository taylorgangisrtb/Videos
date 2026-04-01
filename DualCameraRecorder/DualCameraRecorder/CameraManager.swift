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
    private var isSessionSetUp = false

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
                self.sessionQueue.async {
                    self.configureAudioSession()
                    self.setupSession()
                }
            } else {
                DispatchQueue.main.async { self.permissionDenied = true }
            }
        }
    }

    /// Sets the AVAudioSession category so the capture session can claim the
    /// microphone. Only the category is set here — do NOT call setActive(true)
    /// manually. AVCaptureMultiCamSession manages audio session activation
    /// itself; calling setActive(true) before it does causes the session to
    /// conflict with its own activation and produces FigAudioSession err=-19224.
    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playAndRecord, mode: .videoRecording)
            print("[CameraManager] AVAudioSession category=playAndRecord mode=videoRecording")
        } catch {
            print("[CameraManager] AVAudioSession setCategory failed: \(error)")
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
        guard !isSessionSetUp else { return }
        isSessionSetUp = true

        // Observe runtime errors so we can surface the real failure reason.
        NotificationCenter.default.addObserver(
            forName: .AVCaptureSessionRuntimeError,
            object: session,
            queue: nil
        ) { [weak self] note in
            let error = note.userInfo?[AVCaptureSessionErrorKey] as? Error
            print("[CameraManager] AVCaptureSessionRuntimeError: \(String(describing: error))")
            DispatchQueue.main.async {
                self?.errorMessage = error?.localizedDescription ?? "Unknown session error"
            }
        }

        session.beginConfiguration()

        do {
            // ── Back Camera Input ──────────────────────────────────────────
            guard let backDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .back
            ) else {
                throw CameraError.cameraUnavailable("No back wide-angle camera found")
            }

            let backInput = try AVCaptureDeviceInput(device: backDevice)
            guard session.canAddInput(backInput) else {
                throw CameraError.configurationFailed("Cannot add back camera input")
            }
            session.addInputWithNoConnections(backInput)
            backCameraInput = backInput


            // ── Front Camera Input ─────────────────────────────────────────
            guard let frontDevice = AVCaptureDevice.default(
                .builtInWideAngleCamera, for: .video, position: .front
            ) else {
                throw CameraError.cameraUnavailable("No front wide-angle camera found")
            }

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

            // ── Video Ports ────────────────────────────────────────────────
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

            // ── Back → Vertical (portrait) output — main recording ────────
            let backConnection = AVCaptureConnection(
                inputPorts: [backVideoPort],
                output: backMovieOutput
            )
            if backConnection.isVideoRotationAngleSupported(90) {
                backConnection.videoRotationAngle = 90  // portrait
            }
            guard session.canAddConnection(backConnection) else {
                throw CameraError.configurationFailed("Cannot add back video connection")
            }
            session.addConnection(backConnection)

            // ── Front → Horizontal (landscape) output — thumbnail recording
            let frontConnection = AVCaptureConnection(
                inputPorts: [frontVideoPort],
                output: frontMovieOutput
            )
            if frontConnection.isVideoRotationAngleSupported(0) {
                frontConnection.videoRotationAngle = 0   // landscape
            }
            guard session.canAddConnection(frontConnection) else {
                throw CameraError.configurationFailed("Cannot add front video connection")
            }
            session.addConnection(frontConnection)

            // ── Audio: use addInput (NOT addInputWithNoConnections) ─────────
            // AVCaptureMultiCamSession manages audio connections automatically
            // when added via the standard addInput path.
            if let audioDevice = AVCaptureDevice.default(for: .audio),
               let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
               session.canAddInput(audioInput) {
                session.addInput(audioInput)
            }

            // ── Preview Layers ─────────────────────────────────────────────
            // Back camera preview — portrait fill (matches recording orientation)
            let backPreview = AVCaptureVideoPreviewLayer(sessionWithNoConnection: session)
            backPreview.videoGravity = .resizeAspectFill
            let backPreviewConn = AVCaptureConnection(
                inputPort: backVideoPort,
                videoPreviewLayer: backPreview
            )
            if backPreviewConn.isVideoRotationAngleSupported(90) {
                backPreviewConn.videoRotationAngle = 90
            }
            if session.canAddConnection(backPreviewConn) {
                session.addConnection(backPreviewConn)
            }

            // Front camera preview — landscape thumbnail
            let frontPreview = AVCaptureVideoPreviewLayer(sessionWithNoConnection: session)
            frontPreview.videoGravity = .resizeAspectFill
            let frontPreviewConn = AVCaptureConnection(
                inputPort: frontVideoPort,
                videoPreviewLayer: frontPreview
            )
            if session.canAddConnection(frontPreviewConn) {
                session.addConnection(frontPreviewConn)
            }

            // Log hardware cost — must be ≤ 1.0 or startRunning() will silently fail.
            print("[CameraManager] session.hardwareCost = \(session.hardwareCost)")
            print("[CameraManager] session.systemPressureCost = \(session.systemPressureCost)")

            // Commit BEFORE starting — startRunning() must come after commitConfiguration()
            session.commitConfiguration()

            // Pick the first codec each output reports as available for the
            // current session configuration. This avoids ProRes at 4K 60fps
            // which requires external storage and crashes on internal storage.
            if let backVideoConn = backMovieOutput.connection(with: .video),
               let codec = backMovieOutput.availableVideoCodecTypes.first {
                backMovieOutput.setOutputSettings([AVVideoCodecKey: codec], for: backVideoConn)
            }
            if let frontVideoConn = frontMovieOutput.connection(with: .video),
               let codec = frontMovieOutput.availableVideoCodecTypes.first {
                frontMovieOutput.setOutputSettings([AVVideoCodecKey: codec], for: frontVideoConn)
            }

            session.startRunning()
            print("[CameraManager] session.isRunning = \(session.isRunning)")

            DispatchQueue.main.async {
                self.backPreviewLayer = backPreview
                self.frontPreviewLayer = frontPreview
                self.isConfigured = true
            }

        } catch {
            session.commitConfiguration()
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
            }
        }
    }


    // MARK: - Recording

    func startRecording() {
        guard !isRecording else { return }

        saveLock.lock()
        backFinished = false
        frontFinished = false
        recordingError = nil
        let backURL = makeURL(prefix: "vertical")
        let frontURL = makeURL(prefix: "horizontal")
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
            // AVFoundation sets error even on clean stop; only treat it as real
            // if the recording did NOT finish successfully.
            let nsError = error as NSError
            let finished = nsError.userInfo[AVErrorRecordingSuccessfullyFinishedKey] as? Bool ?? false
            if !finished {
                recordingError = error
            }
        }
        if output === backMovieOutput { backFinished = true }
        if output === frontMovieOutput { frontFinished = true }
        saveLock.unlock()

        checkAndSaveBothIfDone()
    }
}
