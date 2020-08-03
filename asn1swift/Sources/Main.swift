//
//  Main.swift
//  asn1swift
//
//  Created by Pavel Tikhonenko on 27.07.2020.
//

import Foundation

struct BMask: OptionSet
{
	let rawValue: UInt8
	
	static let pepperoni    = BMask(rawValue: 1 << 0)
}

enum BMasks: UInt8
{
	case all 
	case none
}
class A
{
	var str: String = "12321#"
	var str2: String = "1232132432#"
}

struct B
{
	var shorInt: UInt8 = 8
	var str: String = "12321#"
	var shorInt2: UInt8 = 9
	var int: Int = 10
	
	var str2: String = "1232132432#"
	var c: Character = "C"
}



struct DecodedStruct: ASN1Decodable
{
	static var template: ASN1Template
	{
		return ASN1Template.universal(16).constructed()
	}
	
	var a: Int
//	var b: Int
//	var inner: Inner
	
	enum CodingKeys: ASN1CodingKey
	{
		case a
//		case b
//		case inner
		
		var template: ASN1Template
		{
			switch self
			{
			case .a:
				return .universal(ASN1Identifier.Tag.integer)
				//		case .b:
				//			return 0x04
				//		case .inner:
				//			return 0x33
			}
		}
	}
}


func start()
{
	var bytes: [UInt8] = [0x02, 0x01, 0xa0];
	
	let asn1Decoder = ASN1Decoder()
	let integer = try! asn1Decoder.decode(Int.self, from: Data(bytes))
	
	bytes = [0x30, 0x03, 0x02, 0x01, 0xa0];
	
	let obj = try! asn1Decoder.decode(DecodedStruct.self, from: Data(bytes))
	print("coool", integer, obj)
}




struct Inner: ASN1Decodable
{
	static var template: ASN1Template = ASN1Template.contextSpecific(0).constructed().explicit(tag: ASN1Identifier.Tag.sequence).constructed()
	
	var integer: Int
	
	enum CodingKeys: ASN1CodingKey
	{
		case integer
		
		var template: ASN1Template
		{
			switch self
			{
			case .integer:
				return .universal(ASN1Identifier.Tag.integer)
			}
		}
	}
}

struct IndefiniteLengthContainer: ASN1Decodable
{
	static var template: ASN1Template = .universal(0x30)
	
	var integer: Int
	var inner: Inner
	
	enum CodingKeys: ASN1CodingKey
	{
		case integer
		case inner
		
		var template: ASN1Template
		{
			switch self
			{
			case .integer:
				return .universal(ASN1Identifier.Tag.integer)
			case .inner:
				return Inner.template
			}
		}
	}
}
