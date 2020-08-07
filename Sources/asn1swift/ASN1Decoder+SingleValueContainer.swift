//
//  File.swift
//  
//
//  Created by Pavel Tikhonenko on 07.08.2020.
//

import Foundation

// MARK: SingleValueDecodingContainer

extension _ASN1Decoder: SingleValueDecodingContainer
{
	// MARK: SingleValueDecodingContainer Methods
	
	private func expectNonNull<T>(_ type: T.Type) throws {
		guard !self.decodeNil() else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected \(type) but found null value instead."))
		}
	}
	
	public func decodeNil() -> Bool
	{
		assertionFailure("Not supposed to be here")
		return false
	}
	
	public func decode(_ type: Bool.Type) throws -> Bool {
		try expectNonNull(Bool.self)
		return try self.unbox(self.storage.current.data, as: Bool.self)!
	}
	
	public func decode(_ type: Int.Type) throws -> Int
	{
		var c: Int = 0
		let data = try extractValue(from: self.storage.current.data, with: self.storage.current.template.expectedTags, consumed: &c)
		
		return try self.unbox(data, as: Int.self)!
	}
	
	public func decode(_ type: Int8.Type) throws -> Int8 {
		try expectNonNull(Int8.self)
		return try self.unbox(self.storage.current.data, as: Int8.self)!
	}
	
	public func decode(_ type: Int16.Type) throws -> Int16 {
		try expectNonNull(Int16.self)
		return try self.unbox(self.storage.current.data, as: Int16.self)!
	}
	
	public func decode(_ type: Int32.Type) throws -> Int32 {
		try expectNonNull(Int32.self)
		return try self.unbox(self.storage.current.data, as: Int32.self)!
	}
	
	public func decode(_ type: Int64.Type) throws -> Int64 {
		try expectNonNull(Int64.self)
		return try self.unbox(self.storage.current.data, as: Int64.self)!
	}
	
	public func decode(_ type: UInt.Type) throws -> UInt {
		try expectNonNull(UInt.self)
		return try self.unbox(self.storage.current.data, as: UInt.self)!
	}
	
	public func decode(_ type: UInt8.Type) throws -> UInt8 {
		try expectNonNull(UInt8.self)
		return try self.unbox(self.storage.current.data, as: UInt8.self)!
	}
	
	public func decode(_ type: UInt16.Type) throws -> UInt16 {
		try expectNonNull(UInt16.self)
		return try self.unbox(self.storage.current.data, as: UInt16.self)!
	}
	
	public func decode(_ type: UInt32.Type) throws -> UInt32 {
		try expectNonNull(UInt32.self)
		return try self.unbox(self.storage.current.data, as: UInt32.self)!
	}
	
	public func decode(_ type: UInt64.Type) throws -> UInt64 {
		try expectNonNull(UInt64.self)
		return try self.unbox(self.storage.current.data, as: UInt64.self)!
	}
	
	public func decode(_ type: Float.Type) throws -> Float {
		try expectNonNull(Float.self)
		return try self.unbox(self.storage.current.data, as: Float.self)!
	}
	
	public func decode(_ type: Double.Type) throws -> Double {
		try expectNonNull(Double.self)
		return try self.unbox(self.storage.current.data, as: Double.self)!
	}
	
	public func decode(_ type: String.Type) throws -> String
	{
		let data = try dataToUnbox(String.self)
		
		return try self.unbox(data, as: String.self, encoding: self.storage.current.template.stringEncoding)!
	}
	
	public func decode<T : Decodable>(_ type: T.Type) throws -> T {
		return try self.unbox(self.storage.current.data, as: type)!
	}
	
	fileprivate func dataToUnbox<T: ASN1Decodable>(_ type: T.Type) throws -> Data
	{
		let entry = self.storage.current.data
		var c: Int = 0
		let data = try self.extractValue(from: entry, with: self.storage.current.template.expectedTags, consumed: &c)
		
		// Shift data (position)
		self.storage.current.data = c >= entry.count ? Data() : entry.advanced(by: c)
		
		return data
	}
}
