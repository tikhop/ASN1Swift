//
//  LegacyReceipt.swift
//  asn1swiftTests
//
//  Created by Pavel Tikhonenko on 03.08.2020.
//

import Foundation
import ASN1Swift

struct ReceiptPayload: ASN1Decodable
{
	static var template: ASN1Template
	{
		return ASN1Template.contextSpecific(0).constructed().explicit(tag: ASN1Identifier.Tag.octetString).explicit(tag: ASN1Identifier.Tag.set).constructed()
	}
	
	var attributes: [ReceiptAttribute]
	
	init(from decoder: Decoder) throws
	{
		var container = try decoder.unkeyedContainer()
		
		var attr: [ReceiptAttribute] = []
		while !container.isAtEnd
		{
			do
			{
				let element = try container.decode(ReceiptAttribute.self)
				attr.append(element)
			}catch{
				assertionFailure("Something wrong here")
			}
		}
		
		attributes = attr
	}
}

struct ReceiptAttribute: ASN1Decodable
{
	static var template: ASN1Template
	{
		return ASN1Template.universal(ASN1Identifier.Tag.sequence).constructed()
	}
	
	var type: Int
	var version: Int
	var value: Data
	
	enum CodingKeys: ASN1CodingKey
	{
		case type
		case version
		case value
		
		
		var template: ASN1Template
		{
			switch self
			{
			case .type:
				return .universal(ASN1Identifier.Tag.integer)
			case .version:
				return .universal(ASN1Identifier.Tag.integer)
			case .value:
				return .universal(ASN1Identifier.Tag.octetString)
			}
		}
	}
}

struct LegacyReceipt: ASN1Decodable
{
	static var template: ASN1Template
	{
		return ASN1Template.universal(16).constructed()
	}
	
	var oid: ASN1SkippedField
	var signedData: SignedData
	
	enum CodingKeys: ASN1CodingKey
	{
		case oid
		case signedData
		
		var template: ASN1Template
		{
			switch self
			{
			case .oid:
				return .universal(ASN1Identifier.Tag.objectIdentifier)
			case .signedData:
				return SignedData.template
			}
		}
	}
}

extension LegacyReceipt
{
	struct SignedData: ASN1Decodable
	{
		static var template: ASN1Template
		{
			return ASN1Template.contextSpecific(0).constructed().explicit(tag: 16).constructed()
		}
		
		var version: Int
		var alg: ASN1SkippedField
		var data: ContentData
		
		enum CodingKeys: ASN1CodingKey
		{
			case version
			case alg
			case data
			
			var template: ASN1Template
			{
				switch self
				{
				case .version:
					return .universal(ASN1Identifier.Tag.integer)
				case .alg:
					return ASN1Template.universal(ASN1Identifier.Tag.set).constructed()
				case .data:
					return ContentData.template
				}
			}
		}
	}
	
	struct ContentData: ASN1Decodable
	{
		static var template: ASN1Template
		{
			return ASN1Template.universal(ASN1Identifier.Tag.sequence).constructed()
		}
		
		var oid: ASN1SkippedField
		var payload: ReceiptPayload
		
		enum CodingKeys: ASN1CodingKey
		{
			case oid
			case payload
			
			var template: ASN1Template
			{
				switch self
				{
				case .oid:
					return .universal(ASN1Identifier.Tag.objectIdentifier)
				case .payload:
					return ReceiptPayload.template
				}
			}
		}
	}
}
