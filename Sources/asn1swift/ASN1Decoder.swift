//
//  ASN1Decoder.swift
//  asn1swift
//
//  Created by Pavel Tikhonenko on 29.07.2020.
//

import Foundation

typealias ASN1DecoderConsumedValue = Int

open class ASN1Decoder
{
	//fileprivate //TODO
	struct EncodingOptions
	{
		/// Contextual user-provided information for use during encoding/decoding.
		let userInfo: [CodingUserInfoKey : Any] = [:]
	}
	
	public init() {}
	
	// MARK: - Decoding Values
	
	/// Decodes a top-level value of the given type from the given ASN1 representation.
	///
	/// - parameter type: The type of the value to decode.
	/// - parameter data: The data to decode from.
	/// - parameter template: // TODO
	/// - returns: A value of the requested type.
	/// - throws: `DecodingError.dataCorrupted` if values requested from the payload are corrupted, or if the given data is not valid ASN1.
	/// - throws: An error if any value throws an error during decoding.
	open func decode<T : ASN1Decodable>(_ type: T.Type, from data: Data, template: ASN1Template? = nil) throws -> T
	{
		let t: ASN1Template = template ?? type.template
		
//		let buffer: UnsafeMutableBufferPointer<UInt8> = UnsafeMutableBufferPointer.allocate(capacity: data.count)
//		let r: Int = data.copyBytes(to: buffer)
//		
//		let ptr: UnsafePointer<UInt8> = UnsafePointer(buffer.baseAddress!)
//		let size: Int = extractTLLength(from: ptr, length: r, expectedTags: t.expectedTags)
//		let top = ASN1Object(buffer: UnsafeBufferPointer(buffer), length: r, valuePosition: size, template: t)
		
		let opt = EncodingOptions()
		let decoder = _ASN1Decoder(referencing: data, with: t, options: opt)
		
		guard let value = try decoder.unbox(data, as: type) else
		{
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
		}
		
		return value
	}
}

extension _ASN1Decoder.Context
{
	// MARK: - Modifying the Stack
	
	var count: Int
	{
		return self.containers.count
	}
	
	var isTop: Bool
	{
		return count == 1
	}
	var current: _ASN1Decoder.State
	{
		precondition(!self.containers.isEmpty, "Empty container stack.")
		return self.containers.last!
	}
	
	mutating func push(container: __owned _ASN1Decoder.State)
	{
		self.containers.append(container)
	}
	
	mutating func popContainer()
	{
		precondition(!self.containers.isEmpty, "Empty container stack.")
		self.containers.removeLast()
	}
}

internal struct ASN1Key: CodingKey
{
	public var stringValue: String
	public var intValue: Int?
	
	public init?(stringValue: String) {
		self.stringValue = stringValue
		self.intValue = nil
	}
	
	public init?(intValue: Int) {
		self.stringValue = "\(intValue)"
		self.intValue = intValue
	}
	
	public init(stringValue: String, intValue: Int?) {
		self.stringValue = stringValue
		self.intValue = intValue
	}
	
	init(index: Int) {
		self.stringValue = "Index \(index)"
		self.intValue = index
	}
	
	static let `super` = ASN1Key(stringValue: "super")!
}

// MARK: _ASN1Decoder

public protocol ASN1DecoderProtocol: Decoder
{
	var dataToDecode: Data { get }
	func extractValueData() throws -> Data
}

extension _ASN1Decoder
{
	public var dataToDecode: Data
	{
		return self.storage.current.rawData
	}
	
	public func extractValueData() throws -> Data
	{
		var c: Int = 0
		let entry: Data = self.storage.current.rawData
		let tags: [ASN1Tag] = self.storage.current.template.expectedTags
		return try extractValue(from: entry, with: tags, consumed: &c)
	}
}
//TODO: private
class _ASN1Decoder: ASN1DecoderProtocol
{
	internal struct Context
	{
		// MARK: Properties
		
		/// Data we are decoding
		private var data: Data
		
		/// The container stack.
		/// Elements may be any one of the ASN1 types (NSNull, NSNumber, String, Array, [String : Any]).
		private(set) var containers: [_ASN1Decoder.State] = []
		
		// MARK: - Initialization
		
		/// Initializes `self` with no containers.
		init(data: Data)
		{
			self.data = data
		}
	}
	
	class State
	{
		var data: Data
		var rawData: Data
		var template: ASN1Template
		
		init(data: Data, template: ASN1Template)
		{
			self.data = data
			self.rawData  = data
			self.template = template
		}
	}
	
	public var codingPath: [CodingKey] = []
	
	public var userInfo: [CodingUserInfoKey: Any] { return options.userInfo }
	
	var options: ASN1Decoder.EncodingOptions!
	
	internal var storage: Context
	
	internal init(referencing data: Data, with template: ASN1Template, at codingPath: [CodingKey] = [], options: ASN1Decoder.EncodingOptions)
	{
		
		self.storage = Context(data: data)
		
		let state = _ASN1Decoder.State(data: data, template: template)
		self.storage.push(container: state)
		
		
		self.codingPath = codingPath
		self.options = options
	}
	
	public init()
	{
		self.storage = Context(data: Data())
	}
	
	/// Returns the data stored in this decoder as represented in a container
	/// keyed by the given key type.
	///
	/// - parameter type: The key type to use for the container.
	/// - returns: A keyed decoding container view into this decoder.
	/// - throws: `DecodingError.typeMismatch` if the encountered stored value is
	///   not a keyed container.
	public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key>
	{
		let state = _ASN1Decoder.State(data: self.storage.current.data, template: self.storage.current.template)
		let container = try ASN1KeyedDecodingContainer<Key>(referencing: self, wrapping: state)
		return KeyedDecodingContainer(container)
	}
	
	/// Returns the data stored in this decoder as represented in a container
	/// appropriate for holding values with no keys.
	///
	/// - returns: An unkeyed container view into this decoder.
	/// - throws: `DecodingError.typeMismatch` if the encountered stored value is
	///   not an unkeyed container.
	public func unkeyedContainer() throws -> UnkeyedDecodingContainer
	{
		let state = _ASN1Decoder.State(data: self.storage.current.data, template: self.storage.current.template)
		return try ASN1UnkeyedDecodingContainer(referencing: self, wrapping: state)
	}
	
	/// Returns the data stored in this decoder as represented in a container
	/// appropriate for holding a single primitive value.
	///
	/// - returns: A single value container view into this decoder.
	/// - throws: `DecodingError.typeMismatch` if the encountered stored value is
	///   not a single value container.
	public func singleValueContainer() throws -> SingleValueDecodingContainer
	{
		return self
	}
}



