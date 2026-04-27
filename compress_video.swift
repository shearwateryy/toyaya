import Foundation
import AVFoundation

struct Args {
    let input: String
    let output: String
    let targetMB: Double
}

func parseArgs() -> Args? {
    let args = CommandLine.arguments
    guard args.count >= 4 else { return nil }
    return Args(input: args[1], output: args[2], targetMB: Double(args[3]) ?? 25.0)
}

func main() {
    guard let cfg = parseArgs() else {
        fputs("usage: swift compress_video.swift <input> <output> <targetMB>\n", stderr)
        exit(2)
    }

    let inputURL = URL(fileURLWithPath: cfg.input)
    let outputURL = URL(fileURLWithPath: cfg.output)
    let asset = AVURLAsset(url: inputURL)

    guard let export = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetHEVC1920x1080)
        ?? AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1920x1080)
        ?? AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1280x720)
        ?? AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
        fputs("failed to create export session\n", stderr)
        exit(1)
    }

    try? FileManager.default.removeItem(at: outputURL)
    export.outputURL = outputURL
    export.outputFileType = .mp4
    export.shouldOptimizeForNetworkUse = true
    export.fileLengthLimit = Int64(cfg.targetMB * 1024 * 1024)

    let semaphore = DispatchSemaphore(value: 0)
    export.exportAsynchronously {
        semaphore.signal()
    }
    semaphore.wait()

    switch export.status {
    case .completed:
        print("completed")
    case .failed:
        fputs("failed: \(export.error?.localizedDescription ?? "unknown error")\n", stderr)
        exit(1)
    case .cancelled:
        fputs("cancelled\n", stderr)
        exit(1)
    default:
        fputs("ended with status \(export.status.rawValue)\n", stderr)
        exit(1)
    }
}

main()
