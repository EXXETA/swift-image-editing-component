//
//  ImageCropperView.swift
//  ImageCropper
//
//  Created by Kocaatli, Alper on 01.03.24.
//

import UIKit
import Combine

/// Shows the image and includes crop actions
class ImageCropperView: UIView {

	// MARK: - Private Properties
	/// The image we are editing
	private var editableImage: UIImage

	/// UIImageView displays our image
	private let imageView = UIImageView()

	/// Top left button
	private let topLeftButton = UIButton()

	/// Top right button
	private let topRightButton = UIButton()

	/// Bottom left button
	private let bottomLeftButton = UIButton()

	/// Bottom right button
	private let bottomRightButton = UIButton()

	/// Crop button
	private let cropButton = UIButton(configuration: .filled())

	/// Rotate button
	private let rotateButton = UIButton(configuration: .filled())

	/// Layer for showing the dashed lines of the crop area
	private let rectangleLayer = CAShapeLayer()

	/// Layer for showing the darkened background of the crop area
	private let backgroundLayer = CAShapeLayer()

	/// Mask layer to cut out the region of interest
	private let maskLayer = CAShapeLayer()

	/// Current image frame
	private var imageFrame: CGRect?

	/// Button size is twice as big as the icon we use for our button to have a bigger pan space
	private let buttonSize: CGFloat = 64

	// MARK: - Initialization
	deinit { }

	/// Initializer
	init(editableImage: UIImage) {
		self.editableImage = editableImage
		super.init(frame: .zero)

		setupViews()
		setupConstraints()
	}

	/// Required initializer
	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	// MARK: - Private Functions
	/// Setup of the views
	private func setupViews() {
		addSubview(imageView)

		imageView.image = editableImage
		imageView.contentMode = .scaleAspectFit
		imageView.backgroundColor = UIColor.white

		layer.addSublayer(backgroundLayer)
		layer.addSublayer(rectangleLayer)

		maskLayer.fillRule = .evenOdd

		backgroundLayer.mask = maskLayer
		backgroundLayer.fillColor = UIColor.black.cgColor
		backgroundLayer.opacity = Float(0.5)

		/// Stroke
		rectangleLayer.strokeColor = UIColor.white.cgColor
		rectangleLayer.fillColor = UIColor.clear.cgColor
		rectangleLayer.lineWidth = 2
		rectangleLayer.lineJoin = .round
		let dashPatternFour = NSNumber(floatLiteral: 4)
		rectangleLayer.lineDashPattern = [dashPatternFour, dashPatternFour]

		addSubview(topLeftButton)
		addSubview(topRightButton)
		addSubview(bottomLeftButton)
		addSubview(bottomRightButton)

		var configuration = UIButton.Configuration.plain()
		configuration.cornerStyle = .capsule

		[topLeftButton, topRightButton, bottomLeftButton, bottomRightButton].forEach { button in
			let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(buttonPanGestureAction))
			button.addGestureRecognizer(panGestureRecognizer)
			button.configuration = configuration
		}

		/// Here we use different images for each button to visualize the button origin.
		/// If you want to use one image for each button you can do in in the button config above.
		topLeftButton.configuration?.image = UIImage(named: "circle-arrow-up-left")?.resized(to: CGSize(width: 32, height: 32))
		topRightButton.configuration?.image = UIImage(named: "circle-arrow-up-right")?.resized(to: CGSize(width: 32, height: 32))
		bottomLeftButton.configuration?.image = UIImage(named: "circle-arrow-down-left")?.resized(to: CGSize(width: 32, height: 32))
		bottomRightButton.configuration?.image = UIImage(named: "circle-arrow-down-right")?.resized(to: CGSize(width: 32, height: 32))

		addSubview(cropButton)
		addSubview(rotateButton)

		cropButton.configuration?.attributedTitle = AttributedString("Crop", attributes: AttributeContainer([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16, weight: .heavy)]))
		cropButton.configuration?.baseBackgroundColor = UIColor(named: "brand")
		cropButton.addTarget(self, action: #selector(cropAction), for: .touchUpInside)

		rotateButton.configuration?.attributedTitle = AttributedString("Rotate", attributes: AttributeContainer([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 16, weight: .heavy)]))
		rotateButton.configuration?.baseBackgroundColor = UIColor(named: "brand")
		rotateButton.addTarget(self, action: #selector(rotateAction), for: .touchUpInside)
	}


	/// Setup of the constraining
	private func setupConstraints() {
		imageView.translatesAutoresizingMaskIntoConstraints = false
		imageView.topAnchor.constraint(equalTo: self.safeAreaLayoutGuide.topAnchor).isActive = true
		imageView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
		imageView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true

		[topLeftButton, topRightButton, bottomLeftButton, bottomRightButton].forEach { button in
			button.translatesAutoresizingMaskIntoConstraints = false
			button.widthAnchor.constraint(equalToConstant: buttonSize).isActive = true
			button.heightAnchor.constraint(equalToConstant: buttonSize).isActive = true
		}

		cropButton.translatesAutoresizingMaskIntoConstraints = false
		cropButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 40).isActive = true
		cropButton.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 16).isActive = true
		cropButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16).isActive = true
		cropButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

		rotateButton.translatesAutoresizingMaskIntoConstraints = false
		rotateButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 40).isActive = true
		rotateButton.leftAnchor.constraint(equalTo: cropButton.rightAnchor, constant: 16).isActive = true
		rotateButton.rightAnchor.constraint(equalTo: self.rightAnchor, constant: -16).isActive = true
		rotateButton.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -16).isActive = true
		rotateButton.heightAnchor.constraint(equalToConstant: 44).isActive = true
		rotateButton.widthAnchor.constraint(equalTo: cropButton.widthAnchor).isActive = true
	}

	/// Pan gesture handling for the 4 buttons that form the crop area
	@objc
	private func buttonPanGestureAction(_ gesture: UIPanGestureRecognizer) {
		/// Unwrap the button that triggered the pan gesture
		guard let button = gesture.view else {
			Log.warning("buttonPanGestureAction received no view for positioning update", error: LogError.warning)
			return
		}

		/// Custom duration of the animation
		let animationDuration: CGFloat = 0.1
		/// Custom maximum scale of the animation
		let buttonMaxScale: CGFloat = 2

		/// Handle began and ended states for button scale animation
		switch gesture.state {
			case .began:
				UIView.animate(withDuration: animationDuration, delay: 0, options: .curveLinear) {
					button.transform = CGAffineTransform(scaleX: buttonMaxScale, y: buttonMaxScale)
				}
			case .ended:
				UIView.animate(withDuration: animationDuration, delay: 0, options: .curveLinear) {
					button.transform = .identity
				}
			default:
				Log.debug("UIPanGestureRecognizer state \(gesture.state) not handled in ReceiptEditCropImageView")
		}

		guard let imageFrame else {
			Log.warning("Could not unwrap current image frame", error: LogError.warning)
			return
		}

		/// Here we calculate our min, max x and y values
		let minXSafeArea: CGFloat = imageFrame.origin.x
		let maxXSafeArea: CGFloat = imageFrame.origin.x + imageFrame.width
		let minYSafeArea: CGFloat = imageFrame.origin.y
		let maxYSafeArea: CGFloat = imageFrame.height + minYSafeArea

		/// Maximum x for the left buttons gets calculated
		let topLeftButtonMaxX = topRightButton.center.x
		let bottomLeftButtonMaxX = bottomRightButton.center.x
		let leftButtonsMaxX = min(topLeftButtonMaxX, bottomLeftButtonMaxX)

		/// Minimum x for the right buttons gets calculated
		let topRightButtonMinX = topLeftButton.center.x
		let bottomRightButtonMinX = bottomLeftButton.center.x
		let rightButtonsMinX = max(topRightButtonMinX, bottomRightButtonMinX)

		/// Maximum y for the top buttons gets calculated
		let topRightButtonMaxY = bottomRightButton.center.y
		let topLeftButtonMaxY = bottomLeftButton.center.y
		let topButtonsMaxY = min(topRightButtonMaxY, topLeftButtonMaxY)

		/// Minimum y for the bottom buttons gets calculated
		let bottomRightButtonMinY = topRightButton.center.y
		let bottomLeftButtonMinY = topLeftButton.center.y
		let bottomButtonsMinY = max(bottomRightButtonMinY, bottomLeftButtonMinY)

		/// Current point of the gesture in relation to the ImageCropperView
		let point = gesture.translation(in: self)

		/// Here we work with the previously calculated max and min x,y values
		/// to ensure that the buttons can not be panned outside of the image
		/// frame or the buttons do not overlap and invalidate our final frame.
		let xPosition: CGFloat
		let yPosition: CGFloat
		if button === topLeftButton {
			xPosition = max(minXSafeArea, min(button.center.x + point.x, leftButtonsMaxX))
			yPosition = max(minYSafeArea, min(button.center.y + point.y, topButtonsMaxY))
		} else if button === topRightButton {
			xPosition = min(maxXSafeArea, max(button.center.x + point.x, rightButtonsMinX))
			yPosition = max(minYSafeArea, min(button.center.y + point.y, topButtonsMaxY))
		} else if button === bottomLeftButton {
			xPosition = max(minXSafeArea, min(button.center.x + point.x, leftButtonsMaxX))
			yPosition = min(maxYSafeArea, max(button.center.y + point.y, bottomButtonsMinY))
		} else if button === bottomRightButton {
			xPosition = min(maxXSafeArea, max(button.center.x + point.x, rightButtonsMinX))
			yPosition = min(maxYSafeArea, max(button.center.y + point.y, bottomButtonsMinY))
		} else { return }

		/// Set the new position of the button
		button.center = CGPoint(x: xPosition, y: yPosition)
		gesture.setTranslation(CGPoint.zero, in: self)

		drawRectangle()
	}

	/// Updates the 'imageFrame' property
	private func updateImageFrame() {
		let originalImageSize = editableImage.size
		let heightAspectRatio = originalImageSize.height / originalImageSize.width
		let imageHeight = min(frame.width * heightAspectRatio, imageView.frame.height)
		let imageWidth = imageHeight / heightAspectRatio
		let imageSize = CGSize(width: imageWidth, height: imageHeight)
		let verticalInset = max(0, (imageView.frame.height - imageSize.height) / 2)
		let horizontalInset = (imageView.frame.width - imageSize.width) / 2

		self.imageFrame = CGRect(origin: CGPoint(x: horizontalInset, y: verticalInset), size: imageSize)
	}

	// MARK: - Lifecycle
	override func layoutSubviews() {
		super.layoutSubviews()

		setupDefaultCropRectangle()
	}

	/// Setup of the initial crop rectangle
	private func setupDefaultCropRectangle() {
		updateImageFrame()

		guard let imageFrame else {
			Log.warning("Could not unwrap otiginal image bounds", error: LogError.warning)
			return
		}

		let inset = frame.width / 10
		let topLeft = CGPoint(
			x: imageFrame.minX + inset,
			y: imageFrame.minY + inset
		)
		let topRight = CGPoint(
			x: imageFrame.maxX - inset,
			y: imageFrame.minY + inset
		)
		let bottomLeft = CGPoint(
			x: imageFrame.minX + inset,
			y: imageFrame.maxY - inset
		)
		let bottomRight = CGPoint(
			x: imageFrame.maxX - inset,
			y: imageFrame.maxY - inset
		)

		topLeftButton.center = topLeft
		topRightButton.center = topRight
		bottomLeftButton.center = bottomLeft
		bottomRightButton.center = bottomRight

		drawRectangle()
	}

	/// Draws the crop area
	private func drawRectangle() {
		guard let imageFrame else {
			Log.warning("Could not unwrap current image frame", error: LogError.warning)
			return
		}

		/// Rectangle layer path with dashed lines
		let rectangle = UIBezierPath.init()

		rectangle.move(to: topLeftButton.center)

		rectangle.addLine(to: topLeftButton.center)
		rectangle.addLine(to: topRightButton.center)
		rectangle.addLine(to: bottomRightButton.center)
		rectangle.addLine(to: bottomLeftButton.center)
		rectangle.addLine(to: topLeftButton.center)

		rectangle.close()

		rectangleLayer.path = rectangle.cgPath

		/// Mask for centered rectangle cut
		let mask = UIBezierPath.init(rect: imageFrame)

		mask.move(to: topLeftButton.center)

		mask.addLine(to: topLeftButton.center)
		mask.addLine(to: topRightButton.center)
		mask.addLine(to: bottomRightButton.center)
		mask.addLine(to: bottomLeftButton.center)
		mask.addLine(to: topLeftButton.center)

		mask.close()

		maskLayer.path = mask.cgPath

		/// Background layer
		let path = UIBezierPath(rect: imageFrame)
		backgroundLayer.path = path.cgPath
	}

	/// Rotates the original image and updates all layers
	@objc private func rotateAction() {
		/// Rotate original image to the right
		guard
			let previousImageSize = imageFrame?.size,
			let rotatedImage = editableImage.rotate(radians: .pi / 2) else {
			Log.warning(
				"Could not rotate image, because editableOriginalImage, originalImageBounds or rotatedImage was nil",
				error: LogError.warning
			)
			return
		}

		/// We have to nil out the image before setting to get desired visual result
		imageView.image = nil
		imageView.image = rotatedImage

		editableImage = rotatedImage

		/// After the rotated image is set, we are updating the original image bounds
		updateImageFrame()
		guard let newImageSize = imageFrame?.size else {
			return
		}

		/// Here the percentage of resize is calculated
		let resizePercentage = newImageSize.width / previousImageSize.height

		/// The following handling is needed to keep all buttons at their intented position.
		/// Meaning top, left, right, bottom. So their drag constraints align with their positions.
		let topRightButtonPoint = rotatePointAroundCenter(
			origin: imageView.center,
			target: topLeftButton.center,
			resizePercentage: resizePercentage
		)

		let bottomRightButtonPoint = rotatePointAroundCenter(
			origin: imageView.center,
			target: topRightButton.center,
			resizePercentage: resizePercentage
		)

		let topLeftButtonPoint = rotatePointAroundCenter(
			origin: imageView.center,
			target: bottomLeftButton.center,
			resizePercentage: resizePercentage
		)

		let bottomLeftButtonPoint = rotatePointAroundCenter(
			origin: imageView.center,
			target: bottomRightButton.center,
			resizePercentage: resizePercentage
		)

		/// Here we are assigning the correct point for all buttons
		topLeftButton.center = topLeftButtonPoint
		topRightButton.center = topRightButtonPoint
		bottomLeftButton.center = bottomLeftButtonPoint
		bottomRightButton.center = bottomRightButtonPoint

		/// After the points are correctly set, we are drawing the rectangle
		drawRectangle()
	}

	/// Crop image action
	@objc
	private func cropAction() {
		guard let imageFrame else {
			Log.warning("Could not unwrap otiginal image bounds or editableOriginalImage", error: LogError.warning)
			return
		}

		/// imageFrame x and y equal the half of the total vertical (y) and horizontal (x) inset.
		let verticalInset = imageFrame.origin.y
		let horizontalInset = imageFrame.origin.x

		/// Subtract the insets from the calculated rect so they do not get considered in the cropping process
		let minX = min(topLeftButton.center.x, bottomLeftButton.center.x) - horizontalInset
		let maxX = max(topRightButton.center.x, bottomRightButton.center.x) - horizontalInset
		let minY = min(topLeftButton.center.y, topRightButton.center.y) - verticalInset
		let maxY = max(bottomLeftButton.center.y, bottomRightButton.center.y) - verticalInset
		let width = maxX - minX
		let height = maxY - minY

		/// Rect to crop
		let rect = CGRect(x: minX, y: minY, width: width, height: height)

		guard let croppedImage = cropImage(
			editableImage,
			toRect: rect,
			viewWidth: imageFrame.width,
			viewHeight: imageFrame.height
		) else {
			Log.warning("Could not crop the image", error: LogError.warning)
			return
		}

		/// imageView image update
		imageView.image = nil
		imageView.image = croppedImage
		editableImage = croppedImage

		/// Reset the default crop rectangle due to rotation
		setupDefaultCropRectangle()
	}

	/// Returns the cropped image for given rect
	func cropImage(_ inputImage: UIImage, toRect cropRect: CGRect, viewWidth: CGFloat, viewHeight: CGFloat) -> UIImage? {
		let imageViewScale = max(inputImage.size.width / viewWidth, inputImage.size.height / viewHeight)

		/// Scale cropRect to handle images larger than shown-on-screen size
		let cropZone = CGRect(
			x: cropRect.origin.x * imageViewScale,
			y: cropRect.origin.y * imageViewScale,
			width: cropRect.size.width * imageViewScale,
			height: cropRect.size.height * imageViewScale
		)

		guard let cutImageRef: CGImage = inputImage.cgImage?.cropping(to: cropZone) else {
			Log.warning("Crop failed", error: LogError.warning)
			return nil
		}

		return UIImage(cgImage: cutImageRef)
	}

}

extension UIImage {
	func resized(to size: CGSize) -> UIImage {
		return UIGraphicsImageRenderer(size: size).image { _ in
			draw(in: CGRect(origin: .zero, size: size))
		}
	}
}

extension UIView {

	/// Rotates given point with mathematical formula by the center of the view and
	/// regulates view size changes by custom x and y percentage values
	func rotatePointAroundCenter(
		origin: CGPoint,
		target: CGPoint,
		resizePercentage: CGFloat
	) -> CGPoint {
		let destx = target.x - origin.x
		let desty = target.y - origin.y
		let radius = sqrt(destx * destx + desty * desty)
		let azimuth = atan2(desty, destx)
		let degree: CGFloat = 90
		let newAzimuth = azimuth + degree * .pi / 180
		let xPos = origin.x + radius * cos(newAzimuth) * resizePercentage /// x percentage in case of area size reduction or growth
		let yPos = origin.y + radius * sin(newAzimuth) * resizePercentage /// y percentage in case of area size reduction or growth
		return CGPoint(x: xPos, y: yPos)
	}

}

extension UIImage {

	/// Returns a new image that is rotated by the defined radians value
	func rotate(radians: Float) -> UIImage? {
		/// The image's new size after rotation is calculated. This is crucial because rotating an image can change its width and height
		var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size

		/// Get the next largest integer less than or equal to the size for width and height
		newSize.width = floor(newSize.width)
		newSize.height = floor(newSize.height)

		/// A new bitmap-based graphics context is created with the new image size, allowing for high-quality image manipulation
		UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)

		/// The context's origin is translated to the new image's center, ensuring the rotation occurs around the center point
		guard let context = UIGraphicsGetCurrentContext() else { return nil }
		context.translateBy(x: newSize.width/2, y: newSize.height/2)

		/// The context is rotated by the specified number of radians, setting the stage for the new image rendering
		context.rotate(by: CGFloat(radians))

		/// The original image is drawn onto the rotated context, resulting in a rotated image
		self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))

		/// The rotated image is extracted from the context and prepared for return
		let newImage = UIGraphicsGetImageFromCurrentImageContext()

		/// The graphics context is closed, ensuring that all resources are properly released
		UIGraphicsEndImageContext()

		return newImage
	}

}
