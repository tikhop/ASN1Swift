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
		
		let opt = EncodingOptions()
		let decoder = _ASN1Decoder(referencing: _ASN1Decoder.State(data: data, template: t), options: opt)
		
		
		guard let value = try decoder.unbox(data, as: type) else
		{
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "The given data did not contain a top-level value."))
		}
		
		return value
	}
}

private struct ASN1DecodingStorage
{
	// MARK: Properties
	
	/// The container stack.
	/// Elements may be any one of the ASN1 types (NSNull, NSNumber, String, Array, [String : Any]).
	private(set) var containers: [_ASN1Decoder.State] = []
	
	// MARK: - Initialization
	
	/// Initializes `self` with no containers.
	init() {}
	
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

private struct ASN1Key: CodingKey
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

//private TODO
public class _ASN1Decoder: Decoder
{
	class State
	{
		var data: Data
		var template: ASN1Template
		
		init(data: Data, template: ASN1Template)
		{
			self.data = data
			self.template = template
		}
		
		var contentsLength: UInt = 0
		var pending: UInt = 0
		var consumed: UInt = 0
		
		var depth: Int = 0
	}
	
	public var codingPath: [CodingKey] = []
	
	public var userInfo: [CodingUserInfoKey: Any] { return options.userInfo }
	
	var options: ASN1Decoder.EncodingOptions!
	private var storage: ASN1DecodingStorage = ASN1DecodingStorage()
	
	fileprivate init(referencing state: _ASN1Decoder.State, at codingPath: [CodingKey] = [], options: ASN1Decoder.EncodingOptions)
	{
		self.storage = ASN1DecodingStorage()
		self.storage.push(container: state)
		self.codingPath = codingPath
		self.options = options
	}
	
	public init() {}
	
	/// Returns the data stored in this decoder as represented in a container
	/// keyed by the given key type.
	///
	/// - parameter type: The key type to use for the container.
	/// - returns: A keyed decoding container view into this decoder.
	/// - throws: `DecodingError.typeMismatch` if the encountered stored value is
	///   not a keyed container.
	public func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key>
	{
		let container = try ASN1KeyedDecodingContainer<Key>(referencing: self, wrapping: self.storage.current)
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
		return try ASN1UnkeyedDecodingContainer(referencing: self, wrapping: self.storage.current)
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

// MARK: Decoding

extension _ASN1Decoder
{
	func extractValue(from data: Data, with expectedTags: [ASN1Tag], consumed: inout Int) throws -> Data
	{
//		return data.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
//			let pp = p.baseAddress!
//			print(p)
//
//		return Data()
//		}
		var len: Int = 0
		let cons = try checkTags(from: data, with: expectedTags, lastTlvLength: &len)
		consumed = cons + len
		let d = data.advanced(by: cons).prefix(len)
		return d
		
	}
	
	func checkTags(from data: Data, with expectedTags: [ASN1Tag], lastTlvLength: inout Int) throws -> ASN1DecoderConsumedValue
	{
		var consumedMyself: Int = 0
		var tagLen: Int = 0
		var lenOfLen: Int = 0
		var tlvTag: ASN1Tag = 0
		var tlvConstr: Bool = false
		var tlvLen: Int = 0
		var limitLen: Int = -1
		var expectEOCTerminators: Int = 0
		
		var data: Data = data
		var step: Int = 0
		
		for _tag in expectedTags
		{
			//expectEOCTerminators = 0
			
			var t = _tag
			let tag = withUnsafePointer(to: &t) { (p) -> UInt8 in
				return p.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<UInt8>.size) { p in
					return p.pointee
				}
			}
			
			tagLen = fetchTag(from: data, to: &tlvTag)
			
			if tagLen == -1
			{
				throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Data corrupted"))
			}
			
			tlvConstr = tlvConstructed(tag: data.first!)
			
			if tlvTag != tag
			{
				throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Unexpected tag. Inappropriate."))
			}
			
			lenOfLen = fetchLength(from: data.advanced(by: tagLen), isConstructed: tlvConstr, rLen: &tlvLen)
			
			if tlvLen == -1 // Indefinite length.
			{
				let calculatedLen = calculateLength(from: data.advanced(by: tagLen), isConstructed: tlvConstr) - lenOfLen
				
				if calculatedLen > 0
				{
					tlvLen = calculatedLen// - 2 // remove two EOC bytes
					expectEOCTerminators = 1
				}else{
					assertionFailure("Unexpected indefinite length in a chain of definite lengths") // TODO: throw
				}
			}
			
			if limitLen == -1
			{
				limitLen  = tlvLen + tagLen + lenOfLen + expectEOCTerminators
				
				if limitLen < 0
				{
					assertionFailure("Too great tlv_len value?") // TODO: throw
					return -1
				}

			}
			
			// Better to keep this but the problem that we can't get outter expectEOCTerminators, pass state maybe
//			else if limitLen != tlvLen + tagLen + lenOfLen + expectEOCTerminators
//			{
//				/*
//				* Inner TLV specifies length which is inconsistent
//				* with the outer TLV's length value.
//				*/
//				assertionFailure("Outer TLV is \(limitLen) and inner is \(tlvLen)") // TODO: throw
//				return -1
//			}
			
			data = data.advanced(by: tagLen + lenOfLen).prefix(tlvLen)
			consumedMyself += (tagLen + lenOfLen)
			
			limitLen -= (tagLen + lenOfLen + expectEOCTerminators)

			step += 1
		}
				
		lastTlvLength = tlvLen + (expectEOCTerminators << 1)
		return consumedMyself
	}
	
	func fetchTag(from data: Data, to rTag: inout ASN1Tag) -> ASN1DecoderConsumedValue
	{
		guard let firstByte = data.first else
		{
			return 0
		}
		
		var rawTag: UInt8 = firstByte
		let rawTagClass: UInt8 = rawTag >> 6
		
		rawTag &= ASN1Identifier.Tag.highTag
		
		if rawTag != ASN1Identifier.Tag.highTag
		{
			rTag = firstByte
			return 1;
		}
		
		var val: UInt = 0
		var skipped: Int = 2
		
		//TODO: do not allocate new data, use slice instead
		let d = data.advanced(by: 1)
		for b in d.enumerated()
		{
			if skipped > d.count { break }
			
			if b.element & ASN1Identifier.Modifiers.contextSpecific != 0
			{
				val = (val << 7) | UInt(b.element & ASN1Identifier.Tag.highTag)
				
				if val >> ((8 * MemoryLayout.size(ofValue: val)) - 9) != 0
				{
					// No more space
					skipped = -1
					break
				}
			}else{
				val = (val << 7) | UInt(b.element)
				rTag = UInt8(val << 2) | rawTagClass;
				break
			}
			
			skipped += 1
		}
		
		return skipped
	}
	
	func fetchLength(from data: Data, isConstructed: Bool, rLen: inout Int) -> ASN1DecoderConsumedValue
	{
		guard var oct = data.first else
		{
			assertionFailure("Empty data")
			return -1
		}
		
		if (oct & 0x80) == 0
		{
			rLen = Int(oct)
			return 1
		}else{
			var len: Int = 0
			
			
			if isConstructed && oct == 0x80 // Indefinite length
			{
				
				rLen = Int(-1)
				return 1
			}
			
			if oct == 0xff
			{
				/* Reserved in standard for future use. */
				return -1;
			}
			
			oct &= ASN1Identifier.Tag.tagNumMask
			
			let d = data.advanced(by: 1)
			var skipped: Int = 1
			for b in d
			{
				if oct == 0 { break }
				
				skipped += 1
				
				if skipped > data.count
				{
					break
				}
				
				len = (len << 8) | Int(b)
				oct -= 1
			}
			
			if oct == 0
			{
				if len < 0
				{
					return -1
				}
				
				rLen = len
				return skipped
			}
			
			assertionFailure("Not enought data")
			return -1
		}
	}
	
	func calculateLength(from data: Data, isConstructed: Bool) -> Int
	{
		let rawData: Data = data
		var data: Data = data
		var vlen: Int = 0 /* Length of V in TLV */
		var tl: Int = 0 /* Length of L in TLV */
		var ll: Int = 0 /* Length of L in TLV */
		var skip: Int = 0
		var size: Int = data.count
		
		ll = fetchLength(from: data, isConstructed: isConstructed, rLen: &vlen)
		
		if ll <= 0
		{
			return ll
		}
		
		if(vlen >= 0)
		{
			skip = ll + vlen
			
			if skip > data.count
			{
				assertionFailure("Not enought data")
				return 0
			}
			
			return skip
		}
		
		skip = ll
		data = data.advanced(by: ll)
		size -= 11
		
		while true {
			var tag: ASN1Tag = 0
			
			tl = fetchTag(from: data, to: &tag)
			if tl <= 0 { return tl }
			
			ll = calculateLength(from: data.advanced(by: tl), isConstructed: tlvConstructed(tag: tag))
			if ll <= 0 { return ll }
			
			skip += tl + ll
			
			if(data[0] == 0 && data[1] == 0) { return skip }
				
			if skip == rawData.count { return skip }
			
			data = data.advanced(by: tl + ll)
			size -= tl + ll
			
		}
	
		assertionFailure("Not supposed to be here")
		return 0
	}
}

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
		try expectNonNull(type)
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

extension CodingKey
{
	var template: ASN1Template {
		//throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: ""))
		return .universal(0)
	}
}

// MARK: ASN1KeyedDecodingContainer

private struct ASN1KeyedDecodingContainer<K : CodingKey> : KeyedDecodingContainerProtocol
{
	typealias Key = K
	
	// MARK: Properties
	
	/// A reference to the decoder we're reading from.
	private let decoder: _ASN1Decoder
	
	/// A reference to the container we're reading from.
	private let container: _ASN1Decoder.State
	
	
	
	/// The path of coding keys taken to get to this point in decoding.
	private(set) public var codingPath: [CodingKey]
	
	// MARK: - Initialization
	
	/// Initializes `self` by referencing the given decoder and container.
	init(referencing decoder: _ASN1Decoder, wrapping container: _ASN1Decoder.State) throws
	{
		self.decoder = decoder
		self.codingPath = decoder.codingPath
		
		let ct = container
		var c: Int = 0
		ct.data = try self.decoder.extractValue(from: container.data, with: container.template.expectedTags, consumed: &c)
		self.container = ct
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
		let data = Data() //self.decoder.extractValue(from: entry, with: k.template.expectedTags)
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
		let data = try self.decoder.extractValue(from: entry, with: k.template.expectedTags, consumed: &c)
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
		let data = try self.decoder.extractValue(from: entry, with: stringEncoding.template.expectedTags, consumed: &c)
		
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
		return try decode(String.self, forKey: key, stringEncoding: .utf8)
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
		let _ = try dataToUnbox(forKey: key, consumed: &c) // just consume and obtain `c`
		
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
		let data = try self.decoder.extractValue(from: entry, with: k.template.expectedTags, consumed: &consumed)
		
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
		assertionFailure("Hasn't implemented yet")
		return try ASN1UnkeyedDecodingContainer(referencing: self.decoder, wrapping: self.container)
	}
	
	private func _superDecoder(forKey key: __owned CodingKey) throws -> Decoder
	{
		assertionFailure("Hasn't implemented yet")
		return _ASN1Decoder(referencing: self.container, at: self.decoder.codingPath, options: self.decoder.options)
	}
	
	public func superDecoder() throws -> Decoder
	{
		assertionFailure("Hasn't implemented yet")
		return try _superDecoder(forKey: ASN1Key.super)
	}
	
	public func superDecoder(forKey key: Key) throws -> Decoder
	{
		assertionFailure("Hasn't implemented yet")
		return try _superDecoder(forKey: key)
	}
}

// MARK: ASN1UnkeyedDecodingContainer

private struct ASN1UnkeyedDecodingContainer: UnkeyedDecodingContainer
{
	private let decoder: _ASN1Decoder
	private let container: _ASN1Decoder.State
	
	/// The path of coding keys taken to get to this point in decoding.
	public var codingPath: [CodingKey]
	
	/// The index of the element we're about to decode.
	public var currentIndex: Int
	
	var count: Int?
	
	var isAtEnd: Bool
	{
		return container.data.isEmpty || (container.data[0] == 0 && container.data[1] == 0)
	}
	
	init(referencing decoder: _ASN1Decoder, wrapping container: _ASN1Decoder.State) throws
	{
		self.decoder = decoder
		
		self.codingPath = decoder.codingPath
		self.currentIndex = 0
		
		let ct = container
		var c: Int = 0
		ct.data = try self.decoder.extractValue(from: container.data, with: container.template.expectedTags, consumed: &c)
		self.container = ct
	}
	
	mutating func decodeNil() throws -> Bool
	{
		assertionFailure("Hasn't implemented yet")
		return true
	}
	
	mutating func decode(_ type: Bool.Type) throws -> Bool
	{
		guard !self.isAtEnd else
		{
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Unkeyed container is at end."))
		}
		
		self.decoder.codingPath.append(ASN1Key(index: self.currentIndex))
		defer { self.decoder.codingPath.removeLast() }
		
		assertionFailure("Hasn't implemented yet")
		return false
	}
	
	mutating func decode(_ type: String.Type) throws -> String
	{
		guard !self.isAtEnd else
		{
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Unkeyed container is at end."))
		}
		
		self.decoder.codingPath.append(ASN1Key(index: self.currentIndex))
		defer { self.decoder.codingPath.removeLast() }
		
		return ""
	}
	
	mutating func decode(_ type: Double.Type) throws -> Double
	{
		guard !self.isAtEnd else
		{
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Unkeyed container is at end."))
		}
		
		self.decoder.codingPath.append(ASN1Key(index: self.currentIndex))
		defer { self.decoder.codingPath.removeLast() }
		
		assertionFailure("Hasn't implemented yet")
		return 0
	}
	
	mutating func decode(_ type: Float.Type) throws -> Float
	{
		guard !self.isAtEnd else
		{
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Unkeyed container is at end."))
		}
		
		self.decoder.codingPath.append(ASN1Key(index: self.currentIndex))
		defer { self.decoder.codingPath.removeLast() }
		
		assertionFailure("Hasn't implemented yet")
		return 0
	}
	
	mutating func decode(_ type: Int.Type) throws -> Int
	{
		guard !self.isAtEnd else
		{
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Unkeyed container is at end."))
		}
		
		self.decoder.codingPath.append(ASN1Key(index: self.currentIndex))
		defer { self.decoder.codingPath.removeLast() }
		
		return 0
	}
	
	mutating func decode(_ type: Int8.Type) throws -> Int8
	{
		return try Int8(decode(Int.self))
	}
	
	mutating func decode(_ type: Int16.Type) throws -> Int16
	{
		return try Int16(decode(Int.self))
	}
	
	mutating func decode(_ type: Int32.Type) throws -> Int32
	{
		return try Int32(decode(Int.self))
	}
	
	mutating func decode(_ type: Int64.Type) throws -> Int64
	{
		return try Int64(decode(Int.self))
	}
	
	mutating func decode(_ type: UInt.Type) throws -> UInt
	{
		return try UInt(decode(Int.self))
	}
	
	mutating func decode(_ type: UInt8.Type) throws -> UInt8
	{
		return try UInt8(decode(Int.self))
	}
	
	mutating func decode(_ type: UInt16.Type) throws -> UInt16
	{
		return try UInt16(decode(Int.self))
	}
	
	mutating func decode(_ type: UInt32.Type) throws -> UInt32
	{
		return try UInt32(decode(Int.self))
	}
	
	mutating func decode(_ type: UInt64.Type) throws -> UInt64
	{
		return try UInt64(decode(Int.self))
	}
	
	fileprivate func dataToUnbox<T: Decodable>(_ type: T.Type) throws -> Data
	{
		guard let t = type as? ASN1Decodable.Type else
		{
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: ""))
		}
		
		let entry = self.container.data
		var c: Int = 0
		let data = try self.decoder.extractValue(from: entry, with: t.template.expectedTags, consumed: &c)
		
		// Shift data (position)
		self.container.data = c >= entry.count ? Data() : entry.advanced(by: c)
		
		return data
	}
	
	mutating func decode<T>(_ type: T.Type) throws -> T where T: Decodable
	{
		guard !self.isAtEnd else
		{
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Unkeyed container is at end."))
		}
		
		self.decoder.codingPath.append(ASN1Key(index: self.currentIndex))
		defer { self.decoder.codingPath.removeLast() }
		
		
		guard let t = type as? ASN1Decodable.Type else
		{
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: ""))
		}
		
		let entry = self.container.data
		var c: Int = 0
		let data = try self.decoder.extractValue(from: entry, with: t.template.expectedTags, consumed: &c)
		self.container.data = c >= entry.count ? Data() : entry.advanced(by: c)
		
		guard let value = try self.decoder.unbox(entry.prefix(c), as: type) else {
			throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: self.decoder.codingPath, debugDescription: "Expected \(type) value but found null instead."))
		}
		
		
		self.currentIndex += 1
		return value
	}
	
	
	mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey
	{
		//TODO
		assertionFailure("Hasn't implemented yet")
		let container = try ASN1KeyedDecodingContainer<NestedKey>(referencing: self.decoder, wrapping: self.container)
		return KeyedDecodingContainer(container)
	}
	
	mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer
	{
		assertionFailure("Hasn't implemented yet")
		return try ASN1UnkeyedDecodingContainer(referencing: self.decoder, wrapping: self.container)
	}
	
	mutating func superDecoder() throws -> Decoder
	{
		assertionFailure("Hasn't implemented yet")
		return _ASN1Decoder()
	}
}

extension _ASN1Decoder
{
	/// Returns the given value unboxed from a container.
	func unbox(_ value: Data, as type: Bool.Type) throws -> Bool? {
		
		
		if let number = value as? NSNumber {
			// TODO: Add a flag to coerce non-boolean numbers into Bools?
			if number === kCFBooleanTrue as NSNumber {
				return true
			} else if number === kCFBooleanFalse as NSNumber {
				return false
			}
			
			/* FIXME: If swift-corelibs-foundation doesn't change to use NSNumber, this code path will need to be included and tested:
			} else if let bool = value as? Bool {
			return bool
			*/
			
		}
		
		throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
	}
	
	func unbox(_ value: Data, as type: Int.Type) throws -> Int?
	{
		return ASN1Serialization.readInt(from: value, l: value.count) //TODO throw
	}
	
	func unbox(_ value: Data, as type: Int8.Type) throws -> Int8? {
		
		
		guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
			throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
		}
		
		let int8 = number.int8Value
		guard NSNumber(value: int8) == number else {
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed ASN1 number <\(number)> does not fit in \(type)."))
		}
		
		return int8
	}
	
	func unbox(_ value: Data, as type: Int16.Type) throws -> Int16? {
		
		
		guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
			throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
		}
		
		let int16 = number.int16Value
		guard NSNumber(value: int16) == number else {
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed ASN1 number <\(number)> does not fit in \(type)."))
		}
		
		return int16
	}
	
	func unbox(_ value: Data, as type: Int32.Type) throws -> Int32? {
		
		
		guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
			throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
		}
		
		let int32 = number.int32Value
		guard NSNumber(value: int32) == number else {
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed ASN1 number <\(number)> does not fit in \(type)."))
		}
		
		return int32
	}
	
	func unbox(_ value: Data, as type: Int64.Type) throws -> Int64? {
		
		
		guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
			throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
		}
		
		let int64 = number.int64Value
		guard NSNumber(value: int64) == number else {
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed ASN1 number <\(number)> does not fit in \(type)."))
		}
		
		return int64
	}
	
	func unbox(_ value: Data, as type: UInt.Type) throws -> UInt? {
		
		
		guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
			throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
		}
		
		let uint = number.uintValue
		guard NSNumber(value: uint) == number else {
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed ASN1 number <\(number)> does not fit in \(type)."))
		}
		
		return uint
	}
	
	func unbox(_ value: Data, as type: UInt8.Type) throws -> UInt8? {
		
		
		guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
			throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
		}
		
		let uint8 = number.uint8Value
		guard NSNumber(value: uint8) == number else {
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed ASN1 number <\(number)> does not fit in \(type)."))
		}
		
		return uint8
	}
	
	func unbox(_ value: Data, as type: UInt16.Type) throws -> UInt16? {
		
		
		guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
			throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
		}
		
		let uint16 = number.uint16Value
		guard NSNumber(value: uint16) == number else {
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed ASN1 number <\(number)> does not fit in \(type)."))
		}
		
		return uint16
	}
	
	func unbox(_ value: Data, as type: UInt32.Type) throws -> UInt32? {
		
		
		guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
			throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
		}
		
		let uint32 = number.uint32Value
		guard NSNumber(value: uint32) == number else {
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed ASN1 number <\(number)> does not fit in \(type)."))
		}
		
		return uint32
	}
	
	func unbox(_ value: Data, as type: UInt64.Type) throws -> UInt64? {
		
		
		guard let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse else {
			throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
		}
		
		let uint64 = number.uint64Value
		guard NSNumber(value: uint64) == number else {
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed ASN1 number <\(number)> does not fit in \(type)."))
		}
		
		return uint64
	}
	
	func unbox(_ value: Data, as type: Float.Type) throws -> Float? {
		
		
		if let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse {
			// We are willing to return a Float by losing precision:
			// * If the original value was integral,
			//   * and the integral value was > Float.greatestFiniteMagnitude, we will fail
			//   * and the integral value was <= Float.greatestFiniteMagnitude, we are willing to lose precision past 2^24
			// * If it was a Float, you will get back the precise value
			// * If it was a Double or Decimal, you will get back the nearest approximation if it will fit
			let double = number.doubleValue
			guard abs(double) <= Double(Float.greatestFiniteMagnitude) else {
				throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath, debugDescription: "Parsed ASN1 number \(number) does not fit in \(type)."))
			}
			
			return Float(double)
			
			/* FIXME: If swift-corelibs-foundation doesn't change to use NSNumber, this code path will need to be included and tested:
			} else if let double = value as? Double {
			if abs(double) <= Double(Float.max) {
			return Float(double)
			}
			
			overflow = true
			} else if let int = value as? Int {
			if let float = Float(exactly: int) {
			return float
			}
			
			overflow = true
			*/
			
		} else if let string = value as? String
		{
			return Float.nan
		}
		
		throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
	}
	
	func unbox(_ value: Data, as type: Double.Type) throws -> Double? {
		
		
		if let number = value as? NSNumber, number !== kCFBooleanTrue, number !== kCFBooleanFalse {
			// We are always willing to return the number as a Double:
			// * If the original value was integral, it is guaranteed to fit in a Double; we are willing to lose precision past 2^53 if you encoded a UInt64 but requested a Double
			// * If it was a Float or Double, you will get back the precise value
			// * If it was Decimal, you will get back the nearest approximation
			return number.doubleValue
			
			/* FIXME: If swift-corelibs-foundation doesn't change to use NSNumber, this code path will need to be included and tested:
			} else if let double = value as? Double {
			return double
			} else if let int = value as? Int {
			if let double = Double(exactly: int) {
			return double
			}
			
			overflow = true
			*/
			
		} else if let string = value as? String {
			return Double.nan
		}
		
		throw DecodingError._typeMismatch(at: self.codingPath, expectation: type, reality: value)
	}
	
	func unbox(_ value: Data, as type: String.Type, encoding: String.Encoding) throws -> String?
	{
		return String(bytes: value, encoding: encoding)
	}
	
	func unbox(_ value: Data, as type: String.Type) throws -> String?
	{
		return try unbox(value, as: type, encoding: .utf8)
	}
	
	func unbox(_ value: Data, as type: Date.Type) throws -> Date? {
		
		
//		self.storage.push(container: _ASN1Decoder.State(data: value, template: ASN1Template()))
//		defer { self.storage.popContainer() }
		
		//		let double = try self.unbox(value, as: Double.self)!
		//		return Date(timeIntervalSince1970: double)
		
		return try Date(from: self)
	}
	
	func unbox(_ value: Data, as type: Data.Type) throws -> Data? {
		
		
//		self.storage.push(container: _ASN1Decoder.State(data: value, template: ASN1Template()))
//		defer { self.storage.popContainer() }
		return Data(value)
		
		
	}
	
	func unbox(_ value: Data, as type: Decimal.Type) throws -> Decimal?
	{
		if let decimal = value as? Decimal {
			return decimal
		} else {
			let doubleValue = try self.unbox(value, as: Double.self)!
			return Decimal(doubleValue)
		}
	}
	
	func unbox<T : Decodable>(_ value: Data, as type: T.Type) throws -> T?
	{
		return try unbox_(value, as: type) as? T
	}
	
	func unbox_(_ value: Data, as type: Decodable.Type) throws -> Any?
	{
		if type == Date.self || type == NSDate.self {
			return try self.unbox(value, as: Date.self)
		} else if type == Data.self || type == NSData.self {
			return try self.unbox(value, as: Data.self)
		} else if type == URL.self || type == NSURL.self {
			guard let urlString = try self.unbox(value, as: String.self) else {
				return nil
			}
			
			guard let url = URL(string: urlString) else {
				throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: self.codingPath,
																		debugDescription: "Invalid URL string."))
			}
			return url
		} else if type == Decimal.self || type == NSDecimalNumber.self {
			return try self.unbox(value, as: Decimal.self)
		} else {
			if storage.isTop
			{
				let s = _ASN1Decoder.State(data: value, template: storage.current.template)
				self.storage.push(container: s)
				defer { self.storage.popContainer() }
				
				return try type.init(from: self)
			}else if let t = type as? ASN1Decodable.Type
			{
				let s = _ASN1Decoder.State(data: value, template: t.template)
				self.storage.push(container: s)
				defer { self.storage.popContainer() }
				
				return try type.init(from: self)
			}else{
				throw DecodingError.valueNotFound(type, DecodingError.Context(codingPath: [], debugDescription: "The given type isn't ASN1Decodable."))
			}
		}
		
		
		
	}
}


//extension UInt32
//{
//	var expectedTags: [UInt8]
//	{
//		var arr: [UInt8] = []
//
//		if self & UInt32(ASN1Identifier.Modifiers.contextSpecific) != 0
//		{
//			arr.append(UInt8(self) & ASN1Identifier.Tag.tagNumMask)
//		}
//
//		return arr
//	}
//}
