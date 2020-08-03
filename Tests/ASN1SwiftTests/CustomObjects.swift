//
//  Main.swift
//  asn1swift
//
//  Created by Pavel Tikhonenko on 27.07.2020.
//

import Foundation
import ASN1Swift

struct DecodedStruct: ASN1Decodable
{
	static var template: ASN1Template
	{
		return .universal(0x30)
	}
	
	var a: Int
	
	enum CodingKeys: ASN1CodingKey
	{
		case a
		var template: ASN1Template
		{
			switch self
			{
			case .a:
				return .universal(ASN1Identifier.Tag.integer)
			}
		}
	}
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
