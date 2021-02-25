import AVFoundation
import UIKit
import Photos

struct RenderSettings {

    var width: Int = 1334
    var height: Int = 750
    var fps: Int32 = 60   // 60 frames per second
    var videoDuration: Int32 = 10
    var avCodecKey = AVVideoCodecType.h264
    var videoFilename = "render"
    var videoFilenameExt = "mp4"

    var size: CGSize {
        return CGSize(width: width, height: height)
    }

    var outputURL: NSURL {
        // Use the CachesDirectory so the rendered video file sticks around as long as we need it to.
        // Using the CachesDirectory ensures the file won't be included in a backup of the app.
        let fileManager = FileManager.default
        if let tmpDirURL = try? fileManager.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true) {
            return (tmpDirURL.appendingPathComponent(videoFilename) as AnyObject).appendingPathExtension(videoFilenameExt)! as NSURL
        }
        fatalError("URLForDirectory() failed")
    }
}

/*
The ImageAnimator class knows about your images and uses the VideoWriter class to perform the rendering.
The idea is to keep the video content code separate from the low-level AVFoundation code. I also added
saveToLibrary() here as a class function which gets called at the end of the chain to save the video to the Photo Library.
*/
class ImageAnimator {

    // Apple suggests a timescale of 600 because it's a multiple of standard video rates 24, 25, 30, 60 fps etc.
    static let kTimescale: Int32 = 600

    var settings: RenderSettings
    let videoWriter: ImageVideoWriter
    var images: [UIImage]!
    var image: UIImage?

    var frameNum = 0

    class func saveToLibrary(videoURL: NSURL) {
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }

            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: videoURL as URL)
                }) { success, error in
                    if !success {
                        print("Could not save video to photo library:")
                    }
            }
        }
    }

    class func removeFileAtURL(fileURL: NSURL) {
        do {
            try FileManager.default.removeItem(atPath: fileURL.path!)
        }
        catch _ as NSError {
            // Assume file doesn't exist.
        }
    }

    init(renderSettings: RenderSettings, image: UIImage) {
        settings = renderSettings
        videoWriter = ImageVideoWriter(renderSettings: settings)
        self.image = image
        //images = loadImages()
    }

    func render(completion: @escaping ()->Void) {

        // The VideoWriter will fail if a file exists at the URL, so clear it out first.
        ImageAnimator.removeFileAtURL(fileURL: settings.outputURL)

        videoWriter.start()
        videoWriter.render(appendPixelBuffers: appendPixelBuffers) {
            
            //ImageAnimator.saveToLibrary(videoURL: self.settings.outputURL)
            completion()
        }

    }

//    // Replace this logic with your own.
//    func loadImages() -> [UIImage] {
//        var images = [UIImage]()
////        for index in 1...600 {
////            images.append(UIImage(named: "img.JPG")!)
////        }
//        images.append(UIImage(named: "img.JPG")!)
//        return images
//    }

    // This is the callback function for VideoWriter.render()
    func appendPixelBuffers(writer: ImageVideoWriter) -> Bool {

        let frameDuration = CMTimeMake(value: Int64(ImageAnimator.kTimescale / settings.fps), timescale: ImageAnimator.kTimescale)

        //while !images.isEmpty {
        for _ in 1...settings.fps*settings.videoDuration {

            if writer.isReadyForData == false {
                // Inform writer we have more buffers to write.
                return false
            }

            //let image = images.removeFirst()
            
            //let image = self.image
            let presentationTime = CMTimeMultiply(frameDuration, multiplier: Int32(frameNum))
            let success = videoWriter.addImage(image: self.image!, withPresentationTime: presentationTime)
            if success == false {
                fatalError("addImage() failed")
            }
            frameNum += 1
        }
        // Inform writer all buffers have been written.
        return true
    }
}

/*
The VideoWriter class does all AVFoundation heavy lifting. It's mostly a wrapper around
AVAssetWriter and AVAssetWriterInput. It also contains fancy code written by not me that
knows how to translate an image into a CVPixelBuffer.
*/
class ImageVideoWriter {

    let renderSettings: RenderSettings

    var videoWriter: AVAssetWriter!
    var videoWriterInput: AVAssetWriterInput!
    var pixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor!

    var isReadyForData: Bool {
        return videoWriterInput?.isReadyForMoreMediaData ?? false
    }

    class func pixelBufferFromImage(image: UIImage, pixelBufferPool: CVPixelBufferPool, size: CGSize) -> CVPixelBuffer {

        var pixelBufferOut: CVPixelBuffer?

        let status = CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, pixelBufferPool, &pixelBufferOut)
        if status != kCVReturnSuccess {
            fatalError("CVPixelBufferPoolCreatePixelBuffer() failed")
        }

        let pixelBuffer = pixelBufferOut!

        CVPixelBufferLockBaseAddress(pixelBuffer, [])

        let data = CVPixelBufferGetBaseAddress(pixelBuffer)
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: data, width: Int(size.width), height: Int(size.height),
                                bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer), space: rgbColorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
        
        context!.clear(CGRect(x: 0, y: 0, width: size.width, height: size.height))

        let horizontalRatio = size.width / image.size.width
        let verticalRatio = size.height / image.size.height
        //aspectRatio = max(horizontalRatio, verticalRatio) // ScaleAspectFill
        let aspectRatio = min(horizontalRatio, verticalRatio) // ScaleAspectFit
        let newSize = CGSize(width: image.size.width * aspectRatio, height: image.size.height * aspectRatio)

        let x = newSize.width < size.width ? (size.width - newSize.width) / 2 : 0
        let y = newSize.height < size.height ? (size.height - newSize.height) / 2 : 0
        
        context!.draw(image.cgImage!, in: CGRect(x: x,y: y,width: newSize.width,height: newSize.height))
        CVPixelBufferUnlockBaseAddress(pixelBuffer, [])

        return pixelBuffer
    }

    init(renderSettings: RenderSettings) {
        self.renderSettings = renderSettings
    }

    func start() {

        let avOutputSettings: [String: AnyObject] = [
            AVVideoCodecKey: renderSettings.avCodecKey as AnyObject,
            AVVideoWidthKey: NSNumber(value: Float(renderSettings.width)),
            AVVideoHeightKey: NSNumber(value: Float(renderSettings.height))
        ]

        func createPixelBufferAdaptor() {
            let sourcePixelBufferAttributesDictionary = [
                kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32ARGB),
                kCVPixelBufferWidthKey as String: NSNumber(value: Float(renderSettings.width)),
                kCVPixelBufferHeightKey as String: NSNumber(value: Float(renderSettings.height))
            ]
            pixelBufferAdaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: videoWriterInput,
                sourcePixelBufferAttributes: sourcePixelBufferAttributesDictionary)
        }

        func createAssetWriter(outputURL: NSURL) -> AVAssetWriter {
            guard let assetWriter = try? AVAssetWriter(outputURL: outputURL as URL, fileType: AVFileType.mp4) else {
                fatalError("AVAssetWriter() failed")
            }

            guard assetWriter.canApply(outputSettings: avOutputSettings, forMediaType: AVMediaType.video) else {
                fatalError("canApplyOutputSettings() failed")
            }

            return assetWriter
        }

        videoWriter = createAssetWriter(outputURL: renderSettings.outputURL)
        videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: avOutputSettings)

        if videoWriter.canAdd(videoWriterInput) {
            videoWriter.add(videoWriterInput)
        }
        else {
            fatalError("canAddInput() returned false")
        }

        // The pixel buffer adaptor must be created before we start writing.
        createPixelBufferAdaptor()

        if videoWriter.startWriting() == false {
            fatalError("startWriting() failed")
        }

        videoWriter.startSession(atSourceTime: CMTime.zero)

        precondition(pixelBufferAdaptor.pixelBufferPool != nil, "nil pixelBufferPool")
    }

    func render(appendPixelBuffers: @escaping (ImageVideoWriter)->Bool, completion: @escaping ()->Void) {

        precondition(videoWriter != nil, "Call start() to initialze the writer")

        let queue = DispatchQueue(__label: "mediaInputQueue", attr: nil)
        
        videoWriterInput.requestMediaDataWhenReady(on: queue) {
            let isFinished = appendPixelBuffers(self)
            if isFinished {
                self.videoWriterInput.markAsFinished()
                self.videoWriter.finishWriting() {
                    DispatchQueue.main.async() {
                        completion()
                    }
                }
            }
            else {
                // Fall through. The closure will be called again when the writer is ready.
            }
        }
    }

    func addImage(image: UIImage, withPresentationTime presentationTime: CMTime) -> Bool {

        precondition(pixelBufferAdaptor != nil, "Call start() to initialze the writer")

        let pixelBuffer = ImageVideoWriter.pixelBufferFromImage(image: image, pixelBufferPool: pixelBufferAdaptor.pixelBufferPool!, size: renderSettings.size)
        return pixelBufferAdaptor.append(pixelBuffer, withPresentationTime: presentationTime)
    }
}

