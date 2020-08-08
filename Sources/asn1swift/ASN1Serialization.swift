//
//  ASN1Serialization.swift
//  asn1swift
//
//  Created by Pavel Tikhonenko on 28.07.2020.
//

import Foundation


class ASN1Object
{
	var valueData: Data { Data(pointer: valuePtr, size: valueLength) }
	var rawData: Data { Data(pointer: dataPtr, size: dataLength) }
	var template: ASN1Template
	
	var dataPtr: UnsafePointer<UInt8>
	var dataLength: Int
	
	var valuePtr: UnsafePointer<UInt8> { return dataPtr + valuePosition }
	var valueLength: Int
	private var valuePosition: Int
	
	init(data: UnsafePointer<UInt8>, dataLength: Int, valuePosition: Int, valueLength: Int, template: ASN1Template)
	{
		self.dataPtr = data
		self.dataLength = dataLength
		self.valuePosition = valuePosition
		self.valueLength = valueLength
		self.template = template
	}
}

struct ASN1Deserializer
{
//	static func parse(input: Data, using template: ASN1Template) throws -> ASN1Object
//	{
//		let buffer: UnsafeMutableBufferPointer<UInt8> = UnsafeMutableBufferPointer.allocate(capacity: input.count)
//		let r = input.copyBytes(to: buffer)
//		
//		let ptr = buffer.baseAddress!
//		var v: UnsafePointer<UInt8>!
//		var vLength: Int = 0
//		let c = try extractValue(from: ptr, length: r, with: template.expectedTags, value: &v, valueLength: &vLength)
//		
//		return ASN1Object(buffer: UnsafeBufferPointer(buffer), valuePosition: c, valueLength: vLength, template: template)
//	}
}

class ASN1Serialization
{
//	class func ASN1Object(with data: Data, using template: ASN1Template) throws -> ASN1Object
//	{
//		return try ASN1Deserializer.parse(input: data, using: template)
//	}
//	
	class func ASN1Object(with data: UnsafePointer<UInt8>, length: Int, using template: ASN1Template) throws -> ASN1Object
	{
		let ptr = data
		var v: UnsafePointer<UInt8>!
		var vLength: Int = 0
		let c = try extractValue(from: ptr, length: length, with: template.expectedTags, value: &v, valueLength: &vLength)
		
		return ASN1Swift.ASN1Object(data: data, dataLength: c + vLength, valuePosition: c, valueLength: vLength, template: template)
	}
	
	static func readInt(from obj: ASN1Object) -> Int
	{
		return readInt(from: obj.valueData)
	}
	
	@inlinable
	@inline(__always)
	static func readInt(from data: Data) -> Int
	{
		var r: UInt64 = 0
		
		let start = data.startIndex
		let end = start + data.endIndex
		
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
	
	static func readString(from data: ASN1Object, encoding: String.Encoding) -> String?
	{
		return readString(from: data.valueData, encoding: encoding)
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
