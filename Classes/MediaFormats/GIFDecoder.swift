//
// This Source Code Form is subject to the terms of the Mozilla Public
// License, v. 2.0. If a copy of the MPL was not distributed with this
// file, You can obtain one at https://mozilla.org/MPL/2.0/.
//

import Foundation

typealias GIFDecodeFrame = (image: CGImage, interval: TimeInterval)

typealias GIFDecodeFrames = [GIFDecodeFrame]

class GIFDecoder {

    func decodeWithSDWebImage() {

    }

    func decodeWithImageIO(imageURL: URL, completion: @escaping (GIFDecodeFrames) -> Void) {
        let frames = animatedImage(withAnimatedGIFURL: imageURL)
        completion(frames)
    }

    func numberOfFrames(imageURL: URL) -> Int {
        return CGImageSourceGetCount(CGImageSourceCreateWithURL(imageURL as CFURL, nil)!)
    }

    private func delayForImageAtIndex(source: CGImageSource, i: Int) -> Int {
        var delay = 100
        guard let properties: CFDictionary = CGImageSourceCopyPropertiesAtIndex(source, i, nil) else {
            return delay
        }
        guard let gifProperties: NSDictionary = (properties as NSDictionary)[kCGImagePropertyGIFDictionary] as? NSDictionary else {
            return delay
        }
        var number = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? NSNumber
        if number == nil || number == 0 {
            number = gifProperties[kCGImagePropertyGIFDelayTime] as? NSNumber
        }
        if let number = number {
            delay = Int(number.doubleValue * 1000)
        }
        return delay
    }

    private func createImagesAndDelays(source: CGImageSource, count: Int) -> ([CGImage], [Int]) {
        let images = (0..<count).map{ CGImageSourceCreateImageAtIndex(source, $0, nil)! }
        let delays = (0..<count).map{ delayForImageAtIndex(source: source, i: $0) }
        return (images, delays)
    }

    private func sum(_ count: Int, _ values: [Int]) -> Int {
        var theSum = 0;
        for i in 0..<count {
            theSum += values[i]
        }
        return theSum
    }

    private func pairGCD(_ a: Int, _ b: Int) -> Int {
        var aa = a;
        var bb = b;
        if (aa < bb) {
            return pairGCD(bb, aa)
        }
        while (true) {
            let r = aa % bb
            if r == 0 {
                return bb
            }
            aa = b
            bb = r
        }
    }

    private func vectorGCD(_ count: Int, _ values: [Int]) -> Int {
        var gcd = values[0]
        for i in 1..<count {
            gcd = pairGCD(values[i], gcd);
        }
        return gcd
    }

    private func frameArray(_ count: Int, _ images: [CGImage], _ delays: [Int], _ totalDuration: Int) -> [CGImage] {
        let gcd = vectorGCD(count, delays)
        let frameCount = totalDuration / gcd
        var i = 0
        var frames: [CGImage] = []
        while i < count {
            let frame = images[i]
            var j = delays[i] / gcd
            while j > 0 {
                frames.append(frame)
                j -= 1
            }
            i += 1
        }
        return Array(frames[0..<frameCount])
    }

    private func animatedImage(withAnimatedGIFImageSource source: CGImageSource) -> GIFDecodeFrames {
        let count = CGImageSourceGetCount(source)
        guard count > 1 else {
            return []
        }
        let (images, delays) = createImagesAndDelays(source: source, count: count)
        
        var decodedFrames: [GIFDecodeFrame] = []
        for i in 0..<images.count {
            decodedFrames.append((image: images[i], interval: TimeInterval(Double(delays[i]) / 1000.0)))
        }
        return decodedFrames
    }

    private func animatedImage(withAnimatedGIFData data: Data) -> GIFDecodeFrames {
        return animatedImage(withAnimatedGIFImageSource: CGImageSourceCreateWithData(data as CFData, nil)!)
    }

    private func animatedImage(withAnimatedGIFURL url: URL) -> GIFDecodeFrames {
        return animatedImage(withAnimatedGIFImageSource: CGImageSourceCreateWithURL(url as CFURL, nil)!)
    }

}
