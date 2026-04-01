import SwiftUI

struct ContentView: View {
    @StateObject private var camera = CameraManager()

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if camera.permissionDenied {
                permissionDeniedView
            } else if !camera.isConfigured {
                loadingView
            } else {
                previewsAndControls
            }
        }
        .onAppear { camera.configure() }
        .alert("Error", isPresented: Binding(
            get: { camera.errorMessage != nil },
            set: { if !$0 { camera.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { camera.errorMessage = nil }
        } message: {
            Text(camera.errorMessage ?? "")
        }
    }

    // MARK: - Previews + Controls

    private var previewsAndControls: some View {
        VStack(spacing: 0) {
            // Labels row
            HStack {
                Label("HORIZONTAL  4K 60fps", systemImage: "arrow.left.and.right")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())

                Spacer()

                Label("VERTICAL", systemImage: "arrow.up.and.down")
                    .font(.caption.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(.horizontal)
            .padding(.top, 56)

            // Preview area: back (landscape, 16:9) on the left, front (portrait, 9:16) on the right
            GeometryReader { geo in
                HStack(spacing: 8) {
                    // Back camera - landscape
                    if let backLayer = camera.backPreviewLayer {
                        CameraPreviewView(previewLayer: backLayer)
                            .aspectRatio(16 / 9, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    // Front camera - portrait
                    if let frontLayer = camera.frontPreviewLayer {
                        CameraPreviewView(previewLayer: frontLayer)
                            .aspectRatio(9 / 16, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 8)
            }

            // Status message
            if !camera.statusMessage.isEmpty {
                Text(camera.statusMessage)
                    .font(.subheadline.bold())
                    .foregroundStyle(camera.isRecording ? .red : .green)
                    .padding(.top, 8)
                    .transition(.opacity)
                    .animation(.easeInOut, value: camera.statusMessage)
            }

            Spacer(minLength: 0)

            // Record / Stop button
            recordButton
                .padding(.bottom, 48)
        }
    }

    // MARK: - Record Button

    private var recordButton: some View {
        Button(action: toggleRecording) {
            ZStack {
                Circle()
                    .strokeBorder(.white, lineWidth: 4)
                    .frame(width: 80, height: 80)

                if camera.isRecording {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(.red)
                        .frame(width: 32, height: 32)
                } else {
                    Circle()
                        .fill(.red)
                        .frame(width: 64, height: 64)
                }
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(camera.isRecording ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: camera.isRecording)
        .accessibilityLabel(camera.isRecording ? "Stop recording" : "Start recording")
    }

    private func toggleRecording() {
        if camera.isRecording {
            camera.stopRecording()
        } else {
            camera.startRecording()
        }
    }

    // MARK: - Supporting Views

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.white)
                .scaleEffect(1.5)
            Text("Setting up cameras…")
                .foregroundStyle(.secondary)
        }
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.fill.badge.ellipsis")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            Text("Camera Access Required")
                .font(.title2.bold())
                .foregroundStyle(.white)
            Text("Go to Settings > DualCameraRecorder and enable Camera, Microphone, and Photos access.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
}

#Preview {
    ContentView()
}
