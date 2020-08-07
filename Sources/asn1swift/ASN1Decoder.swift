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
		return try self.extractValue(from: entry, with: tags, consumed: &c)
	}
}
//TODO: private
public class _ASN1Decoder: ASN1DecoderProtocol
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
//		let state = _ASN1Decoder.State(data: self.storage.current.data, template: self.storage.current.template)
//		self.storage.push(container: state)
		return self
	}
}

// MARK: Decoding

extension _ASN1Decoder
{
	func extractTLSize(from data: Data, with expectedTags: [ASN1Tag]) -> Int
	{
		return data.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
			
			var ptr = p.baseAddress!.assumingMemoryBound(to: UInt8.self)
			let size = data.count
			var tlvTag: ASN1Tag  = 0
			let tlvConstr: Bool = tlvConstructed(tag: ptr[0])
			var tlvLen: Int = 0 // Lenght of inner value
			var r: Int = 0

			for tag in expectedTags
			{
				let tagLen = fetchTag(from: ptr, size: size, to: &tlvTag)
				let lenOfLen = fetchLength(from: ptr + 1, size: size - 1, isConstructed: tlvConstr, rLen: &tlvLen)
				ptr += tagLen + lenOfLen
				r += tagLen + lenOfLen
			}

			return r
		}
	}
	
	func extractValue(from data: Data, with expectedTags: [ASN1Tag], consumed: inout Int) throws -> Data
	{
		return try data.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
			
			let pp = p.baseAddress!.assumingMemoryBound(to: UInt8.self)
			

			var len: Int = 0
			let cons = try checkTags(from: pp, size: data.count, with: expectedTags, lastTlvLength: &len)
			consumed = cons + len
			
			var innerData: Data = data
			
			if len == 0 || cons == data.count
			{
				innerData = Data()
			}else{
				innerData = innerData.advanced(by: cons)
				
				if len != 0
				{
					innerData = innerData.prefix(len)
				}
			}
			
			return innerData
		}
		
		
	}
	
	func checkTags(from ptr: UnsafePointer<UInt8>, size: Int, with expectedTags: [ASN1Tag], lastTlvLength: inout Int) throws -> ASN1DecoderConsumedValue
	{
		var ptr = ptr
		var consumedMyself: Int = 0
		var tagLen: Int = 0 // Length of tag
		var lenOfLen: Int = 0 // Lenght of L
		var tlvTag: ASN1Tag = 0 // Tag
		var tlvConstr: Bool = false
		var tlvLen: Int = 0 // Lenght of inner value
		var limitLen: Int = -1
		var expectEOCTerminators: Int = 0
		

		var step: Int = 0
		
		for tag in expectedTags
		{
			//expectEOCTerminators = 0
			
			tagLen = fetchTag(from: ptr, size: size, to: &tlvTag)
			
			if tagLen == -1
			{
				throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Data corrupted"))
			}
			
			tlvConstr = tlvConstructed(tag: ptr[0])
			
			if tlvTag != tag
			{
				throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Unexpected tag. Inappropriate."))
			}
			
			lenOfLen = fetchLength(from: ptr + 1, size: size - 1, isConstructed: tlvConstr, rLen: &tlvLen)
			
			if tlvLen == -1 // Indefinite length.
			{
				let calculatedLen = calculateLength(from: ptr + tagLen, size: size - tagLen, isConstructed: tlvConstr) - lenOfLen
				
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
						
			ptr += (tagLen + lenOfLen)
			consumedMyself += (tagLen + lenOfLen)
			
			limitLen -= (tagLen + lenOfLen + expectEOCTerminators)

			step += 1
		}
				
		lastTlvLength = tlvLen
		return consumedMyself
	}
	
	func fetchTag(from ptr: UnsafePointer<UInt8>, size: Int, to rTag: inout ASN1Tag) -> ASN1DecoderConsumedValue
	{
		let firstByte = ptr.pointee
		
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
		
		for i in 1..<size
		{
			if skipped > size { break }
		
			let b = ptr[i]
			
			if b & ASN1Identifier.Modifiers.contextSpecific != 0
			{
				val = (val << 7) | UInt(b & ASN1Identifier.Tag.highTag)
				
				if val >> ((8 * MemoryLayout.size(ofValue: val)) - 9) != 0
				{
					// No more space
					skipped = -1
					break
				}
			}else{
				val = (val << 7) | UInt(b)
				rTag = UInt8(val << 2) | rawTagClass;
				break
			}
			
			skipped += 1
		}
		
		return skipped
	}
	
	func fetchLength(from ptr: UnsafePointer<UInt8>, size: Int, isConstructed: Bool, rLen: inout Int) -> ASN1DecoderConsumedValue
	{
		var oct = ptr.pointee
		
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
			
			var skipped: Int = 1
			for i in 1..<size
			{
				if oct == 0 { break }
				
				skipped += 1
				
				if skipped > size
				{
					break
				}
				
				let b = ptr[i]
				
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
	
	func calculateLength(from ptr: UnsafePointer<UInt8>, size: Int, isConstructed: Bool) -> Int
	{
		var ptr = ptr
		let rawSize = size
		var size = size
		
		var vlen: Int = 0 /* Length of V in TLV */
		var tl: Int = 0 /* Length of L in TLV */
		var ll: Int = 0 /* Length of L in TLV */
		var skip: Int = 0
		
		ll = fetchLength(from: ptr, size: size, isConstructed: isConstructed, rLen: &vlen)
		
		if ll <= 0
		{
			return ll
		}
		
		if(vlen >= 0)
		{
			skip = ll + vlen
			
			if skip > size
			{
				assertionFailure("Not enought data")
				return 0
			}
			
			return skip
		}
		
		skip = ll
		ptr = ptr + ll
		size -= ll
		
		while true {
			var tag: ASN1Tag = 0
			
			tl = fetchTag(from: ptr, size: size, to: &tag)
			if tl <= 0 { return tl }
			
			ll = calculateLength(from: ptr + tl, size: size - tl, isConstructed: tlvConstructed(tag: tag))
			if ll <= 0 { return ll }
			
			skip += tl + ll
			
			if(ptr.pointee == 0 && (ptr+1).pointee == 0) { return skip }
				
			if skip == rawSize { return skip }
			
			ptr += (tl + ll)
			size -= (tl + ll)
		}
	
		assertionFailure("This assertion must not happen")
		return 0
	}
}


