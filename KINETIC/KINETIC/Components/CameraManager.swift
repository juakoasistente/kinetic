import AVFoundation
import UIKit

@Observable
final class CameraManager: NSObject {
    private let session = AVCaptureSession()
    private var movieOutput = AVCaptureMovieFileOutput()
    private var recordingDelegate: RecordingDelegate?

    private(set) var isRecording = false
    private(set) var recordedVideoURL: URL?
    private(set) var isConfigured = false
    var isLandscape = false

    var captureSession: AVCaptureSession { session }

    // MARK: - Setup (runs heavy work off main thread internally)

    func configure(landscape: Bool = false) {
        print("[CameraManager] configure() called, landscape: \(landscape)")
        isLandscape = landscape

        guard !isConfigured else {
            print("[CameraManager] Already configured, skipping")
            return
        }

        configureSession()
    }

    /// Async version that runs AVCaptureSession setup off the main thread
    func configureAsync(landscape: Bool = false) async {
        print("[CameraManager] configureAsync() called, landscape: \(landscape)")
        isLandscape = landscape

        guard !isConfigured else {
            print("[CameraManager] Already configured, skipping")
            return
        }

        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async { [self] in
                configureSession()
                continuation.resume()
            }
        }
    }

    private func configureSession() {
        session.beginConfiguration()
        session.sessionPreset = .hd1920x1080

        // Video input
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("[CameraManager] ERROR: No back camera found")
            session.commitConfiguration()
            return
        }

        do {
            let videoInput = try AVCaptureDeviceInput(device: camera)
            guard session.canAddInput(videoInput) else {
                print("[CameraManager] ERROR: Cannot add video input")
                session.commitConfiguration()
                return
            }
            session.addInput(videoInput)
            print("[CameraManager] Video input added")
        } catch {
            print("[CameraManager] ERROR: Video input failed: \(error.localizedDescription)")
            session.commitConfiguration()
            return
        }

        // Audio input
        if let mic = AVCaptureDevice.default(for: .audio) {
            do {
                let audioInput = try AVCaptureDeviceInput(device: mic)
                if session.canAddInput(audioInput) {
                    session.addInput(audioInput)
                    print("[CameraManager] Audio input added")
                }
            } catch {
                print("[CameraManager] WARNING: Audio input failed: \(error.localizedDescription)")
            }
        }

        // Movie output
        if session.canAddOutput(movieOutput) {
            session.addOutput(movieOutput)
            if let connection = movieOutput.connection(with: .video) {
                connection.videoRotationAngle = isLandscape ? 0 : 90
                print("[CameraManager] Movie output added, rotation set to \(isLandscape ? 0 : 90)")
            }
        } else {
            print("[CameraManager] ERROR: Cannot add movie output")
        }

        session.commitConfiguration()
        DispatchQueue.main.async { [self] in
            isConfigured = true
        }
        print("[CameraManager] Configuration complete")
    }

    func start() {
        guard !session.isRunning else {
            print("[CameraManager] Session already running")
            return
        }
        print("[CameraManager] Starting capture session...")
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.startRunning()
            DispatchQueue.main.async {
                print("[CameraManager] Capture session started: \(session.isRunning)")
            }
        }
    }

    func stop() {
        guard session.isRunning else { return }
        print("[CameraManager] Stopping capture session")
        DispatchQueue.global(qos: .userInitiated).async { [session] in
            session.stopRunning()
        }
    }

    // MARK: - Recording

    func startRecording() {
        guard !isRecording else {
            print("[CameraManager] Already recording")
            return
        }
        guard session.isRunning else {
            print("[CameraManager] ERROR: Cannot start recording — session not running")
            return
        }

        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "kinetic_\(UUID().uuidString).mov"
        let fileURL = tempDir.appendingPathComponent(fileName)

        recordingDelegate = RecordingDelegate { [weak self] url in
            self?.recordedVideoURL = url
            self?.isRecording = false
            print("[CameraManager] Recording saved to: \(url.lastPathComponent)")
        }

        print("[CameraManager] Starting recording to: \(fileURL.lastPathComponent)")
        movieOutput.startRecording(to: fileURL, recordingDelegate: recordingDelegate!)
        isRecording = true
    }

    func stopRecording() {
        guard isRecording else { return }
        print("[CameraManager] Stopping recording")
        movieOutput.stopRecording()
    }

    /// Stop recording and wait for the file to be written
    func stopRecordingAsync() async -> URL? {
        guard isRecording else { return recordedVideoURL }
        print("[CameraManager] Stopping recording (async)")
        movieOutput.stopRecording()

        // Wait until delegate sets recordedVideoURL (max ~10s)
        for _ in 0..<100 {
            try? await Task.sleep(for: .milliseconds(100))
            if !isRecording, let url = recordedVideoURL { return url }
        }
        print("[CameraManager] WARNING: Timed out waiting for recording to finish")
        return recordedVideoURL
    }
}

// MARK: - Recording Delegate

private class RecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    let onFinished: (URL) -> Void

    init(onFinished: @escaping (URL) -> Void) {
        self.onFinished = onFinished
    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error {
            print("[CameraManager] Recording finished with error: \(error.localizedDescription)")
            return
        }
        DispatchQueue.main.async { [onFinished] in
            onFinished(outputFileURL)
        }
    }
}
