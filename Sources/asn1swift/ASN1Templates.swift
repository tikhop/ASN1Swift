//
//  ASN1Templates.swift
//  asn1swift
//
//  Created by Pavel Tikhonenko on 29.07.2020.
//

import Foundation

public class ASN1Template
{
	var expectedTags: [UInt32] = []
	
	fileprivate init(kind: UInt32)
	{
		expectedTags.append(kind)
	}
	
	public func implicit(tag: UInt8) -> ASN1Template
	{
		return self
	}
	
	public func explicit(tag: UInt8) -> ASN1Template
	{
		expectedTags.append(UInt32(tag))
		
		return self
	}
	
	public func constructed() -> ASN1Template
	{
		if expectedTags.isEmpty
		{
			expectedTags.append(0)
		}
		
		if var last = expectedTags.last
		{
			last |= UInt32(ASN1Identifier.Modifiers.constructed)
			expectedTags[expectedTags.count - 1] = last
		}
		
		return self
	}
}

public extension ASN1Template
{
	static func contextSpecific(_ id: UInt8) -> ASN1Template
	{
		return ASN1Template(kind: UInt32(ASN1Identifier.Modifiers.contextSpecific | id))
	}
	
	static func universal(_ tag: UInt8) -> ASN1Template
	{
		return ASN1Template(kind: UInt32(ASN1Identifier.Modifiers.universal | tag))
	}
}
