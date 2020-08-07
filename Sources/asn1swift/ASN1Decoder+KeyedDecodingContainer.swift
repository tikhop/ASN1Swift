//
//  File.swift
//  
//
//  Created by Pavel Tikhonenko on 07.08.2020.
//

import Foundation

// MARK: ASN1KeyedDecodingContainer

internal struct ASN1KeyedDecodingContainer<K : CodingKey> : KeyedDecodingContainerProtocol
{
	typealias Key = K
	
	// MARK: Properties
	
	/// A reference to the decoder we're reading from.
	private let decoder: _ASN1Decoder
	
	/// A reference to the container we're reading from.
	private let container: _ASN1Decoder.State
	
	/// The path of coding keys taken to get to this point in decoding.
	private(set) public var codingPath: [CodingKey]
	
	public var rawData: Data { return container.rawData }
	
	// MARK: - Initialization
	
	/// Initializes `self` by referencing the given decoder and container.
	init(referencing decoder: _ASN1Decoder, wrapping container: _ASN1Decoder.State) throws
	{
		self.decoder = decoder
		self.codingPath = decoder.codingPath
		
		let tlLength = extractTLSize(from: container.data, with: container.template.expectedTags)
		let data = container.data.advanced(by: tlLength)
		container.data = data
		container.rawData = Data(data)
		
		self.container = container
	}
	
	// MARK: - KeyedDecodingContainerProtocol Methods
	
	public var allKeys: [Key] {
		return []
	}
	
	public func contains(_ key: Key) -> Bool
	{
		return false
	}
	
	private func _errorDescription(of key: CodingKey) -> String
	{
		return "\(key) (\"\(key.stringValue)\")"
	}
	
	public func decodeNil(forKey key: Key) throws -> Bool
	{
		assertionFailure("Not supposed to be here")
		return false
	}
	
	public func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
		
		
		self.decoder.codingPath.append(key)
		defer { self.decoder.codingPath.removeLast() }
		
		guard let k = key as? CodingKey else
		{
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: ""))
		}
		
		let entry = self.container.data
		let data = Data() //extractValue(from: entry, with: k.template.expectedTags)
		self.container.data = data
		
		guard let value = try self.decoder.unbox(data, as: Bool.self) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}
		
		return value
	}
	
	public func decode(_ type: Int.Type, forKey key: Key) throws -> Int
	{
		self.decoder.codingPath.append(key)
		defer { self.decoder.codingPath.removeLast() }
		
		guard let k = key as? ASN1CodingKey else
		{
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: ""))
		}
		
		
		let entry = self.container.data
		var c: Int = 0
		let data = try extractValue(from: entry, with: k.template.expectedTags, consumed: &c)
		self.container.data = c >= entry.count ? Data() : entry.advanced(by: c)
		
		guard let value = try self.decoder.unbox(data, as: Int.self) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}
		
		return value
	}
	
	public func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
		let entry = self.container.data
		
		self.decoder.codingPath.append(key)
		defer { self.decoder.codingPath.removeLast() }
		
		guard let value = try self.decoder.unbox(entry, as: Int8.self) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}
		
		return value
	}
	
	public func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16
	{
		self.decoder.codingPath.append(key)
		defer { self.decoder.codingPath.removeLast() }
		
		guard let value = try self.decoder.unbox(self.container.data, as: Int16.self) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}
		
		return value
	}
	
	public func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32
	{
		self.decoder.codingPath.append(key)
		defer { self.decoder.codingPath.removeLast() }
		
		guard let value = try self.decoder.unbox(self.container.data, as: Int32.self) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}
		
		return value
	}
	
	public func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
		let entry = self.container.data
		
		self.decoder.codingPath.append(key)
		defer { self.decoder.codingPath.removeLast() }
		
		guard let value = try self.decoder.unbox(entry, as: Int64.self) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}
		
		return value
	}
	
	public func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
		let entry = self.container.data
		
		self.decoder.codingPath.append(key)
		defer { self.decoder.codingPath.removeLast() }
		
		guard let value = try self.decoder.unbox(entry, as: UInt.self) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}
		
		return value
	}
	
	public func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
		let entry = self.container.data
		
		self.decoder.codingPath.append(key)
		defer { self.decoder.codingPath.removeLast() }
		
		guard let value = try self.decoder.unbox(entry, as: UInt8.self) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}
		
		return value
	}
	
	public func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
		let entry = self.container.data
		
		self.decoder.codingPath.append(key)
		defer { self.decoder.codingPath.removeLast() }
		
		guard let value = try self.decoder.unbox(entry, as: UInt16.self) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}
		
		return value
	}
	
	public func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
		let entry = self.container.data
		
		self.decoder.codingPath.append(key)
		defer { self.decoder.codingPath.removeLast() }
		
		guard let value = try self.decoder.unbox(entry, as: UInt32.self) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}
		
		return value
	}
	
	public func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
		let entry = self.container.data
		
		self.decoder.codingPath.append(key)
		defer { self.decoder.codingPath.removeLast() }
		
		guard let value = try self.decoder.unbox(entry, as: UInt64.self) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}
		
		return value
	}
	
	public func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
		let entry = self.container.data
		
		self.decoder.codingPath.append(key)
		defer { self.decoder.codingPath.removeLast() }
		
		guard let value = try self.decoder.unbox(entry, as: Float.self) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}
		
		return value
	}
	
	public func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
		let entry = self.container.data
		
		self.decoder.codingPath.append(key)
		defer { self.decoder.codingPath.removeLast() }
		
		guard let value = try self.decoder.unbox(entry, as: Double.self) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}
		
		return value
	}
	
	public func decode(_ type: String.Type, forKey key: Key, stringEncoding: String.Encoding) throws -> String
	{
		let entry = self.container.data
		
		self.decoder.codingPath.append(key)
		defer { self.decoder.codingPath.removeLast() }
		
		var c: Int = 0
		let data = try extractValue(from: entry, with: stringEncoding.template.expectedTags, consumed: &c)
		
		// Shift data (position)
		self.container.data = c >= entry.count ? Data() : entry.advanced(by: c)
		
		guard let value = try self.decoder.unbox(data, as: String.self, encoding: stringEncoding) else
		{
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}
		
		return value
	}
	
	public func decode(_ type: String.Type, forKey key: Key) throws -> String
	{
		guard let k = key as? ASN1CodingKey else
		{
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "key is not ASN1CodingKey"))
		}
		
		return try decode(String.self, forKey: key, stringEncoding: k.template.stringEncoding)
	}
	
	public func decodeData(forKey key: Key) throws -> Data
	{
		self.decoder.codingPath.append(key)
		defer { self.decoder.codingPath.removeLast() }
		
		var c = 0
		let data = try dataToUnbox(forKey: key, consumed: &c)
		guard let value = try self.decoder.unbox(data, as: Data.self) else
		{
			assertionFailure("Something wrong")
			return Data()
		}
		
		return value
	}
	
	public func decode<T : Decodable>(_ type: T.Type, forKey key: Key) throws -> T
	{
		if type == Data.self || type == NSData.self
		{
			return try decodeData(forKey: key) as! T
		}
		
		self.decoder.codingPath.append(key)
		defer { self.decoder.codingPath.removeLast() }
		
		// Save current state
		let entry = self.container.data
		
		var c: Int = 0
		let d = try dataToUnbox(forKey: key, consumed: &c) // just consume and obtain `c`
		
		guard let value = try self.decoder.unbox(entry.prefix(c), as: type) else
		{
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}
		
		return value
	}
	
	fileprivate func dataToUnbox(forKey key: Key, consumed: inout Int) throws -> Data
	{
		guard let k = key as? ASN1CodingKey else
		{
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "key is not ASN1CodingKey"))
		}
		
		let entry = self.container.data
		let data = try extractValue(from: entry, with: k.template.expectedTags, consumed: &consumed)
		
		// Shift data (position)
		self.container.data = consumed >= entry.count ? Data() : entry.advanced(by: consumed)
		
		return data
	}
	
	public func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey>
	{
		assertionFailure("Hasn't implemented yet")
		let container = try ASN1KeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: self.container)
		return KeyedDecodingContainer(container)
	}
	
	public func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer
	{
		let entry = self.container.data
		
		guard let k = key as? ASN1CodingKey else
		{
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "key is not ASN1CodingKey"))
		}
		
		var c: Int = 0
		let _ = try dataToUnbox(forKey: key, consumed: &c)
		
		let state = _ASN1Decoder.State(data: entry.prefix(c), template: k.template)
		return try ASN1UnkeyedDecodingContainer(referencing: self.decoder, wrapping: state)
	}
	
	private func _superDecoder(forKey key: __owned CodingKey) throws -> Decoder
	{
		guard let k = key as? ASN1CodingKey else
		{
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "key is not ASN1CodingKey"))
		}
		
		let entry = self.container.data
		var consumed: Int = 0
		let _ = try extractValue(from: entry, with: k.template.expectedTags, consumed: &consumed)
		
		// Shift data (position)
		self.container.data = consumed >= entry.count ? Data() : entry.advanced(by: consumed)
		
		//let state = _ASN1Decoder.State(data: entry.prefix(consumed), template: k.template)
		
		return _ASN1Decoder(referencing: entry.prefix(consumed), with: k.template, at: self.decoder.codingPath, options: self.decoder.options)
	}
	
	public func superDecoder() throws -> Decoder
	{
		assertionFailure("Hasn't implemented yet")
		return try _superDecoder(forKey: ASN1Key.super)
	}
	
	public func superDecoder(forKey key: Key) throws -> Decoder
	{
		return try _superDecoder(forKey: key)
	}
}
