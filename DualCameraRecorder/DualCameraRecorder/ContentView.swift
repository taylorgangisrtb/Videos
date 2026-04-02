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
                cameraView
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

    // MARK: - Main Camera View

    private var cameraView: some View {
        ZStack(alignment: .top) {
            // ── Full-screen back camera (portrait/vertical) ────────────────
            if let backLayer = camera.backPreviewLayer {
                CameraPreviewView(previewLayer: backLayer)
                    .ignoresSafeArea()
            }

            // ── Overlaid controls ──────────────────────────────────────────
            VStack(spacing: 0) {
                // Front camera thumbnail (horizontal) at the top
                frontThumbnail
                    .padding(.top, 56)

                Spacer()

                // Status message
                if !camera.statusMessage.isEmpty {
                    Text(camera.statusMessage)
                        .font(.subheadline.bold())
                        .foregroundStyle(camera.isRecording ? .red : .green)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial, in: Capsule())
                        .transition(.opacity)
                        .animation(.easeInOut, value: camera.statusMessage)
                        .padding(.bottom, 16)
                }

                // Record button
                recordButton
                    .padding(.bottom, 48)
            }
        }
    }

    // MARK: - Front Camera Thumbnail

    private var frontThumbnail: some View {
        HStack {
            Spacer()

            ZStack(alignment: .topTrailing) {
                if let frontLayer = camera.frontPreviewLayer {
                    CameraPreviewView(previewLayer: frontLayer)
                        .aspectRatio(16 / 9, contentMode: .fit)
                        .frame(width: 160)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .strokeBorder(
                                    camera.isRecording ? Color.red : Color.white.opacity(0.6),
                                    lineWidth: camera.isRecording ? 2 : 1
                                )
                        )
                        .shadow(color: .black.opacity(0.4), radius: 6, x: 0, y: 2)
                }

                // "REC" badge when recording
                if camera.isRecording {
                    Text("REC")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.red, in: Capsule())
                        .padding(5)
                }
            }
            .padding(.trailing, 16)
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
