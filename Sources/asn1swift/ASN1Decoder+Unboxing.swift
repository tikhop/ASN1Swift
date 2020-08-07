//
//  File.swift
//  
//
//  Created by Pavel Tikhonenko on 07.08.2020.
//

import Foundation

extension _ASN1Decoder
{
	/// Returns the given value unboxed from a container.
	func unbox(_ value: Data, as type: Bool.Type) throws -> Bool?
	{
		assertionFailure("Not yet implemented")
		return nil
	}
	
	func unbox(_ value: Data, as type: Int.Type) throws -> Int?
	{
		return ASN1Serialization.readInt(from: value, l: value.count) //TODO throw
	}
	
	func unbox(_ value: Data, as type: Int8.Type) throws -> Int8?
	{
		return Int8(ASN1Serialization.readInt(from: value, l: value.count))
	}
	
	func unbox(_ value: Data, as type: Int16.Type) throws -> Int16?
	{
		return Int16(ASN1Serialization.readInt(from: value, l: value.count))
	}
	
	func unbox(_ value: Data, as type: Int32.Type) throws -> Int32?
	{
		return Int32(ASN1Serialization.readInt(from: value, l: value.count))
	}
	
	func unbox(_ value: Data, as type: Int64.Type) throws -> Int64?
	{
		return Int64(ASN1Serialization.readInt(from: value, l: value.count))
	}
	
	func unbox(_ value: Data, as type: UInt.Type) throws -> UInt?
	{
		return UInt(ASN1Serialization.readInt(from: value, l: value.count))
	}
	
	func unbox(_ value: Data, as type: UInt8.Type) throws -> UInt8?
	{
		return UInt8(ASN1Serialization.readInt(from: value, l: value.count))
	}
	
	func unbox(_ value: Data, as type: UInt16.Type) throws -> UInt16?
	{
		return UInt16(ASN1Serialization.readInt(from: value, l: value.count))
	}
	
	func unbox(_ value: Data, as type: UInt32.Type) throws -> UInt32?
	{
		return UInt32(ASN1Serialization.readInt(from: value, l: value.count))
	}
	
	func unbox(_ value: Data, as type: UInt64.Type) throws -> UInt64?
	{
		return UInt64(ASN1Serialization.readInt(from: value, l: value.count))
	}
	
	func unbox(_ value: Data, as type: Float.Type) throws -> Float?
	{
		assertionFailure("Not yet implemented")
		return nil
	}
	
	func unbox(_ value: Data, as type: Double.Type) throws -> Double?
	{
		assertionFailure("Not yet implemented")
		return nil
	}
	
	func unbox(_ value: Data, as type: String.Type, encoding: String.Encoding) throws -> String?
	{
		return ASN1Serialization.readString(from: value, encoding: encoding)
	}
	
	func unbox(_ value: Data, as type: String.Type) throws -> String?
	{
		return try unbox(value, as: type, encoding: .utf8)
	}
	
	func unbox(_ value: Data, as type: Date.Type) throws -> Date?
	{
		assertionFailure("Not yet implemented")
		return nil
	}
	
	func unbox(_ value: Data, as type: Data.Type) throws -> Data?
	{
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
