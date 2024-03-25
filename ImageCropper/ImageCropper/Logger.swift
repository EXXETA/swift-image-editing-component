//
//  Logger.swift
//  ImageCropper
//
//  Created by Kocaatli, Alper on 01.03.24.
//

import OSLog
import SwiftyBeaver

/// A Wrapper for our logger to do additional calls while logging
enum Log {

	// MARK: - Public Functions

	/// Verbose log
	static func verbose(
		_ message: @autoclosure () -> Any,
		file: String = #file,
		function: String = #function,
		line: Int = #line,
		context: Any? = nil
	) {
		SwiftyBeaver.verbose(message(), file: file, function: function, line: line, context: context)
	}

	/// Debug Log
	static func debug(
		_ message: @autoclosure () -> Any,
		file: String = #file,
		function: String = #function,
		line: Int = #line,
		context: Any? = nil
	) {
		SwiftyBeaver.debug(message(), file: file, function: function, line: line, context: context)
	}

	/// Info Log
	static func info(
		_ message: @autoclosure () -> Any,
		file: String = #file,
		function: String = #function,
		line: Int = #line,
		context: Any? = nil
	) {
		SwiftyBeaver.info(message(), file: file, function: function, line: line, context: context)
	}

	/// Warning Log
	static func warning(
		_ message: @autoclosure () -> Any,
		file: String = #file,
		function: String = #function,
		line: Int = #line,
		context: Any? = nil,
		error: Error
	) {
		let warningMessage = "\(message()) \(error.localizedDescription)"
		SwiftyBeaver.warning(warningMessage, file: file, function: function, line: line, context: context)
	}

	/// Error Log
	static func error(
		_ message: @autoclosure () -> Any,
		file: String = #file,
		function: String = #function,
		line: Int = #line,
		context: Any? = nil,
		error: Error
	) {
		let errorMessage = "\(message()) \(error.localizedDescription)"
		SwiftyBeaver.error(errorMessage, file: file, function: function, line: line, context: context)
	}

}
