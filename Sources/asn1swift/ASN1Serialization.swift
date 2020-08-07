//
//  ASN1Serialization.swift
//  asn1swift
//
//  Created by Pavel Tikhonenko on 28.07.2020.
//

import Foundation


class ASN1Object
{
	var tag: ASN1Tag = 0
	var isConstruscted: Bool = false
	var valueData: Data { Data(pointer: valuePtr, size: valueLength) }
	
	var dataPtr: UnsafePointer<UInt8>
	private var dataLength: Int
	
	private var valuePosition: Int
	private var valuePtr: UnsafePointer<UInt8> { return dataPtr + valuePosition }
	private var valueLength: Int { return dataLength - valuePosition }
	
	private var template: ASN1Template
	private var buffer: UnsafeBufferPointer<UInt8>
	
	init(buffer: UnsafeBufferPointer<UInt8>, length: Int, valuePosition: Int, template: ASN1Template)
	{
		self.buffer = buffer
		self.dataPtr = buffer.baseAddress!
		self.dataLength = length
		self.valuePosition = valuePosition
		self.template = template
	}
	
//	init(dataPtr: UnsafePointer<UInt8>, length: Int, valuePosition: Int, template: ASN1Template)
//	{
//		self.dataPtr = dataPtr
//		self.dataLength = length
//		self.valuePosition = valuePosition
//		self.template = template
//	}
}

struct ASN1Deserializer
{
	static func parse(input: Data, using template: ASN1Template) throws -> ASN1Object
	{
		let buffer: UnsafeMutableBufferPointer<UInt8> = UnsafeMutableBufferPointer.allocate(capacity: input.count)
		let r = input.copyBytes(to: buffer)
		
		let ptr = buffer.baseAddress!
		var v: UnsafePointer<UInt8>!
		var vLength: Int = 0
		let _ = try extractValue(from: ptr, length: r, with: template.expectedTags, value: &v, valueLength: &vLength)
		
		return ASN1Object(buffer: UnsafeBufferPointer(buffer), length: input.count, valuePosition: 2, template: template)
	}
}

class ASN1Serialization
{
	class func ASN1Object(with data: Data, using template: ASN1Template) throws -> ASN1Object
	{
		return try ASN1Deserializer.parse(input: data, using: template)
	}
	
	@inlinable
	@inline(__always)
	static func readInt(from data: Data, l: Int) -> Int
	{
		var r: UInt64 = 0
		
		let start = data.startIndex
		let end = start + l
		
		for i in start..<end
		{
			r = r << 8
			r |= UInt64(data[i])
		}
		
		if r >= Int.max
		{
			return -1 //Invalid data
		}
		
		return Int(r)
	}
	
	static func readString(from data: Data, encoding: String.Encoding) -> String?
	{
		if encoding == .oid
		{
			return readOid(contentData: data)
		}else{
			return String(bytes: data, encoding: encoding)
		}
	}
	
	static func readOid(contentData: Data) -> String
	{
		if contentData.isEmpty { return "" }
		
		var oid: [UInt64] = [UInt64]()
		
		var shifted: UInt8 = 0x00
		var value: UInt64 = 0x00
		
		for (i, bit) in contentData.enumerated()
		{
			if i == 0
			{
				oid.append(UInt64(bit/40))
				oid.append(UInt64(bit%40))
			}else if (bit & 0x80) == 0
			{
				let v = UInt64((bit & 0x7F) | shifted)
				value |= v
				oid.append(value)
				
				shifted = 0x00
				value = 0x00
			}else
			{
				if value > 0 { value >>= 1 }
				
				let v = UInt64(((bit & 0x7F) | shifted) >> 1)
				value |= v
				value <<= 8
				
				shifted = bit << 7
			}
		}
		
		return oid.map { String($0) }.joined(separator: ".")
	}
}
