//
//  CGPoint+Extensions.swift
//  ImageCropper
//
//  Created by Kocaatli, Alper on 01.03.24.
//

import CoreGraphics

extension CGPoint {

	/// Calculates the percentage value in relation to the given size
	func calculatePercentageInRelation(to size: CGSize) -> CGPoint {
		let xPosition = x / size.width
		let yPosition = y / size.height
		return CGPoint(x: xPosition, y: yPosition)
	}

	/// Scales the CGPoint in relation to given size
	func scaled(to size: CGSize) -> CGPoint {
		CGPoint(x: self.x * size.width, y: self.y * size.height)
	}

}
