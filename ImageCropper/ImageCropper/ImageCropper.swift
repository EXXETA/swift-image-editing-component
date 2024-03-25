//
//  ImageCropper.swift
//  ImageCropper
//
//  Created by Kocaatli, Alper on 01.03.24.
//

import SwiftUI

/// SwiftUI component to handle image cropping
struct ImageCropper: UIViewRepresentable {

	// MARK: - Public Functions

	/// Inherited from UIViewRepresentable.makeUIView(context:).
	func makeUIView(context: Context) -> UIView {
		let testImage = UIImage(named: "editing-image")!
		return ImageCropperView(editableImage: testImage)
	}

	/// Inherited from UIViewRepresentable.updateUIView(_:context:).
	func updateUIView(_ uiView: UIView, context: Context) {
		/// Currently no op
	}

}
