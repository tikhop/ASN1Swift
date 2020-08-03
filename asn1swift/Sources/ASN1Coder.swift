//
//  ASN1Coder.swift
//  asn1swift
//
//  Created by Pavel Tikhonenko on 29.07.2020.
//

import Foundation

public protocol ASN1Encodable: Encodable { }
public protocol ASN1Decodable: Decodable
{
	static var template: ASN1Template { get }
}

public typealias ASN1Codable = ASN1Encodable & ASN1Decodable

protocol CK: CodingKey
{
	
}

protocol ASN1CodingKey: CodingKey
{
	var template: ASN1Template { get }
//{
//		//throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: ""))
//		return .universal(0)
//	}
}

