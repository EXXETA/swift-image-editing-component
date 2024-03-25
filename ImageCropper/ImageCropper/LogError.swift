//
//  LogError.swift
//  ImageCropper
//
//  Created by Kocaatli, Alper on 01.03.24.
//

import Foundation

/// An Error which can be used for logging with types warning and error
enum LogError: Error {

	/// Warning
	case warning
	/// Error
	case error

	/// Description
	public var description: String {
		switch self {
			case .warning:
				return "Loglevel warning"
			case .error:
				return "Loglevel error"
		}
	}

}
