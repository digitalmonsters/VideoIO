import XCTest
@testable import VideoIO
import AVFoundation

extension CMSampleTimingInfo: Equatable {
    public static func == (lhs: CMSampleTimingInfo, rhs: CMSampleTimingInfo) -> Bool {
        lhs.decodeTimeStamp == rhs.decodeTimeStamp && lhs.duration == rhs.duration && lhs.presentationTimeStamp == rhs.presentationTimeStamp
    }
}

@available(iOS 10.0, macOS 10.13, *)
final class VideoIOTests: XCTestCase {
    
    let testMovieURL = URL(fileURLWithPath: "\(#file)").deletingLastPathComponent().appendingPathComponent("test.mov")
    
    func testAudioVideoSettings() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        var audioSettings = AudioSettings(formatID: kAudioFormatMPEG4AAC, channels: 2, sampleRate: 44100)
        audioSettings.bitRate = 96000
        XCTAssert(audioSettings.toDictionary() as NSDictionary == [AVFormatIDKey: kAudioFormatMPEG4AAC,
                                                   AVNumberOfChannelsKey: 2,
                                                   AVSampleRateKey: 44100,
                                                   AVEncoderBitRateKey: 96000] as NSDictionary)
        
        let videoSettings: VideoSettings = .h264(videoSize: CGSize(width: 1280, height: 720), averageBitRate: 3000000)
        XCTAssert(videoSettings.toDictionary() as NSDictionary == [AVVideoWidthKey: 1280,
                                                                   AVVideoHeightKey: 720,
                                                                   AVVideoCodecKey: "avc1",
                                                                   AVVideoCompressionPropertiesKey: [AVVideoAverageBitRateKey: 3000000, AVVideoProfileLevelKey: AVVideoProfileLevelH264HighAutoLevel]] as NSDictionary)
    }
    
    func testVideoExport() {
        let fileManager = FileManager()
        let tempURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("mp4")
        let asset = AVURLAsset(url: testMovieURL)
        let expectation = XCTestExpectation()
        let exporter = try! AssetExportSession(asset: asset, outputURL: tempURL, configuration: AssetExportSession.Configuration(fileType: .fileType(for: tempURL)!, videoSettings: .h264(videoSize: asset.presentationVideoSize!), audioSettings: .aac(channels: 2, sampleRate: 44100, bitRate: 96 * 1024)))
        exporter.export(progress: nil) { error in
            XCTAssert(error == nil)
            XCTAssert(try! tempURL.resourceValues(forKeys: Set<URLResourceKey>([.fileSizeKey])).fileSize! > 0)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
        try? fileManager.removeItem(at: tempURL)
    }
    
    func testSampleBufferUtilities() {
        var oldPixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(nil, 1280, 720, kCVPixelFormatType_32BGRA, [:] as CFDictionary, &oldPixelBuffer)
        var oldFormatDescription: CMFormatDescription?
        CMVideoFormatDescriptionCreateForImageBuffer(allocator: nil, imageBuffer: oldPixelBuffer!, formatDescriptionOut: &oldFormatDescription)
        var timingInfo = CMSampleTimingInfo(duration: CMTime(seconds: 1.0/30.0, preferredTimescale: 44100), presentationTimeStamp: .zero, decodeTimeStamp: .invalid)

        var newPixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(nil, 1920, 1080, kCVPixelFormatType_32BGRA, [:] as CFDictionary, &newPixelBuffer)
        
        var oldSampleBuffer: CMSampleBuffer?
        CMSampleBufferCreateReadyWithImageBuffer(allocator: nil, imageBuffer: oldPixelBuffer!, formatDescription: oldFormatDescription!, sampleTiming: &timingInfo, sampleBufferOut: &oldSampleBuffer)
        
        let buffer = SampleBufferUtilities.makeSampleBufferByReplacingImageBuffer(of: oldSampleBuffer!, with: newPixelBuffer!)
        XCTAssert(CMSampleBufferGetImageBuffer(buffer!) === newPixelBuffer)
        
        
        var t: CMSampleTimingInfo = CMSampleTimingInfo()
        CMSampleBufferGetSampleTimingInfo(buffer!, at: 0, timingInfoOut: &t)
        XCTAssert(t == timingInfo)
        
        var sampleBufferWithNoImage: CMSampleBuffer?
        CMSampleBufferCreate(allocator: nil, dataBuffer: nil, dataReady: false, makeDataReadyCallback: nil, refcon: nil, formatDescription: nil, sampleCount: 0, sampleTimingEntryCount: 0, sampleTimingArray: nil, sampleSizeEntryCount: 0, sampleSizeArray: nil, sampleBufferOut: &sampleBufferWithNoImage)
        XCTAssert(SampleBufferUtilities.makeSampleBufferByReplacingImageBuffer(of: sampleBufferWithNoImage!, with: newPixelBuffer!) == nil)
    }

    static var allTests = [
        ("testAudioVideoSettings", testAudioVideoSettings),
        ("testVideoExport", testVideoExport),
        ("testSampleBufferUtilities", testSampleBufferUtilities),
    ]
}
