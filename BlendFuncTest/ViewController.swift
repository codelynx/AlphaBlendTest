//
//  ViewController.swift
//  BlendFuncTest
//
//  Created by Kaz Yoshikawa on 1/20/18.
//
//
//	The MIT License
//
//  Copyright © 2018 Kaz Yoshikawa.
//
//	Permission is hereby granted, free of charge, to any person
//	obtaining a copy of this software and associated documentation
//	files (the "Software"), to deal in the Software without
//	restriction, including without limitation the rights to use,
//	copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following
//	conditions:
//
//	The above copyright notice and this permission notice shall be
//	included in all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//	OTHER DEALINGS IN THE SOFTWARE.



import Cocoa
import simd


private func clamp<T: Comparable>(_ v: T, _ lo: T, _ hi: T) -> T {
	return min(max(v, lo), hi)
}

fileprivate struct XRGBA {
	var r: UInt8
	var g: UInt8
	var b: UInt8
	var a: UInt8
	init(r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
		self.r = r
		self.g = g
		self.b = b
		self.a = a
	}
	init(_ rgba: float4) {
		self.r = UInt8(clamp(rgba.r, 0, 1) * 255)
		self.g = UInt8(clamp(rgba.g, 0, 1) * 255)
		self.b = UInt8(clamp(rgba.b, 0, 1) * 255)
		self.a = UInt8(clamp(rgba.a, 0, 1) * 255)
	}
}

fileprivate struct XRGB {
	var r: UInt8
	var g: UInt8
	var b: UInt8
	init(r: UInt8, g: UInt8, b: UInt8) {
		self.r = r
		self.g = g
		self.b = b
	}
	init(_ rgb: float3) {
		self.r = UInt8(clamp(rgb.r, 0, 1) * 255)
		self.g = UInt8(clamp(rgb.g, 0, 1) * 255)
		self.b = UInt8(clamp(rgb.b, 0, 1) * 255)
	}
}

fileprivate extension float4 {
	init(_ rgba: XRGBA) {
		self = float4(Float(rgba.r) / 255, Float(rgba.g) / 255, Float(rgba.b) / 255, Float(rgba.a) / 255)
	}
    var r: Float { return x }
    var g: Float { return y }
    var b: Float { return z }
    var a: Float { return w }
    var rgb: float3 { return float3(r, g, b) }
}

fileprivate extension float3 {
	init(_ rgb: XRGB) {
		self = float3(Float(rgb.r) / 255, Float(rgb.g) / 255, Float(rgb.b) / 255)
	}
    var r: Float { return x }
    var g: Float { return y }
    var b: Float { return z }
}

// MARK: -

class ViewController: NSViewController {

	let texture1 = #imageLiteral(resourceName: "texture1.png")
	let texture2 = #imageLiteral(resourceName: "texture2.png")
	let texture3 = #imageLiteral(resourceName: "texture3.png")
	let texture4 = #imageLiteral(resourceName: "texture4.png")

	lazy var textures: [NSImage] = {
		return [texture1, texture2, texture3, texture4]
	}()

	@IBOutlet weak var sourcePopup: NSPopUpButton!
	@IBOutlet weak var destinationPopup: NSPopUpButton!

	var sourceImage: NSImage = #imageLiteral(resourceName: "texture2.png") {
		didSet { updateImages() }
	}
	var destinationImage: NSImage = #imageLiteral(resourceName: "texture1.png") {
		didSet { updateImages() }
	}

	@IBOutlet weak var sourceImageView: NSImageView!
	@IBOutlet weak var outputImageView: NSImageView!
	@IBOutlet weak var destinationImageView: NSImageView!
	@IBOutlet weak var outputSourceImageView: NSImageView!
	@IBOutlet weak var outputDestinationImageView: NSImageView!

	override func viewDidLoad() {
		super.viewDidLoad()

		self.sourcePopup.removeAllItems()
		self.sourcePopup.addItems(withTitles: (0..<textures.count).map { "Image \($0 + 1)" })
		self.sourcePopup.selectItem(at: textures.index(of: sourceImage)!)

		self.destinationPopup.removeAllItems()
		self.destinationPopup.addItems(withTitles: (0..<textures.count).map { "Image \($0 + 1)" })
		self.destinationPopup.selectItem(at: textures.index(of: destinationImage)!)
	}

	override func viewWillAppear() {
		super.viewWillAppear()
		updateImages()
	}

	func updateImages() {
		self.sourceImageView.image = sourceImage
		self.destinationImageView.image = destinationImage
		self.outputSourceImageView.image = sourceImage
		self.outputDestinationImageView.image = destinationImage

		let image = blend(source: sourceImage.cgImage!, destionation: destinationImage.cgImage!)
		self.outputImageView.image = NSImage(cgImage: image, size: CGSize(width: 256, height: 256))
	}

	override var representedObject: Any? {
		didSet {
		}
	}
	
	@IBAction func sourceImageAction(_ sender: NSPopUpButton) {
		sourceImage = textures[sender.indexOfSelectedItem]
	}

	@IBAction func destinationImageAction(_ sender: NSPopUpButton) {
		destinationImage = textures[sender.indexOfSelectedItem]
	}
	
	// MARK: -
	
	func blend(source S: float4, destination D: float4) -> float4 {
		let Ra = S.a +  D.a * (1.0 - S.a)
		let Rrgb: float3 = Ra == 0 ? float3(0) : ((S.rgb * S.a) + (D.rgb * D.a * (1.0 - S.a) )) / Ra
		return float4(Rrgb.r, Rrgb.g, Rrgb.b, Ra)
	}

	// MARK: -

	func blend(source: CGImage, destionation: CGImage) -> CGImage {
		assert(source.bitsPerComponent == 8 && source.bitsPerPixel == 32)
		assert(source.bitsPerPixel == destionation.bitsPerPixel)
		assert(source.width == destionation.width && source.height == destionation.height)
		assert(source.bytesPerRow == destionation.bytesPerRow)
		let colorScape = CGColorSpaceCreateDeviceRGB()
		let (width, height) = (source.width, source.height)
		let bitsPerComponent = 8
		let bitsPerPixel = 32
		let bytesPerPixel = 4
 		let rowBytes = width * bytesPerPixel
 		let imageBytes = rowBytes * height
		var outputImageBuffer = [UInt8](repeating: 0, count: imageBytes)
		guard let sourceDataProvider = source.dataProvider else { fatalError() }
		guard let destinationDataProvider = destionation.dataProvider else { fatalError() }
		guard var sourceData = sourceDataProvider.data as Data? else { fatalError() }
		guard var destionationData = destinationDataProvider.data as Data? else { fatalError() }

		let (r, g, b, a) = (0, 1, 2, 3) // byte offset

		sourceData.withUnsafeMutableBytes { (sourceBuffer: UnsafeMutablePointer<UInt8>) -> Void in
			destionationData.withUnsafeMutableBytes { (destinationBuffer: UnsafeMutablePointer<UInt8>) -> Void in
				for y in 0 ..< height {
					for x in 0 ..< width {
						let index = (y * rowBytes) + (x * bytesPerPixel)
						let S = float4(XRGBA(r: sourceBuffer[index + r], g: sourceBuffer[index + g], b: sourceBuffer[index + b], a: sourceBuffer[index + a]))
						let D = float4(XRGBA(r: destinationBuffer[index + r], g: destinationBuffer[index + g], b: destinationBuffer[index + b], a: destinationBuffer[index + a]))
						let R = blend(source: D, destination: S)
						let rgba = XRGBA(R)
						outputImageBuffer[index + r] = rgba.r
						outputImageBuffer[index + g] = rgba.g
						outputImageBuffer[index + b] = rgba.b
						outputImageBuffer[index + a] = rgba.a
					}
				}
			}
		}

		let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue)
		let outputImageData = Data(bytes: &outputImageBuffer, count: imageBytes) as CFData
		guard let outputDataProvider = CGDataProvider(data: outputImageData) else { fatalError() }
		let outputImage = CGImage(width: width, height: height, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: rowBytes,
					space: colorScape, bitmapInfo: bitmapInfo, provider: outputDataProvider, decode: nil,
					shouldInterpolate: false, intent: CGColorRenderingIntent.defaultIntent)!
		return outputImage
	}

	

}

