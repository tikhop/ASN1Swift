//
//  File.swift
//  
//
//  Created by Pavel Tikhonenko on 04.08.2020.
//

import XCTest
@testable import ASN1Swift

final class ASN1SwiftPrimitivesTests: XCTestCase
{
	
	func testDecoding_utf8String() throws
	{
		let bytes: [UInt8] = [0x0C, 0x19, 0x6E, 0x65, 0x74, 0x2E, 0x7A, 0x61, 0x63, 0x68, 0x61, 0x72, 0x69, 0x61, 0x64, 0x69, 0x73, 0x2E, 0x63, 0x79, 0x63, 0x6C, 0x65, 0x6D, 0x61, 0x70, 0x73]
		
		let asn1Decoder = ASN1Decoder()
		let r = try! asn1Decoder.decode(String.self, from: Data(bytes))
		XCTAssert(r == "net.zachariadis.cyclemaps")
	}
	
	func testDecoding_sequence() throws
	{
		let bytes: [UInt8] = [0x30, 0x03, 0x02, 0x01, 0xa0];
		
		let asn1Decoder = ASN1Decoder()
		let r = try! asn1Decoder.decode(DecodedStruct.self, from: Data(bytes))
		XCTAssert(r.a == 0xa0)
	}
	
	func testDecoding_csImplicitInteger() throws
	{
		let bytes: [UInt8] = [0xa0, 0x01, 0xa0];
		
		let asn1Decoder = ASN1Decoder()
		let t: ASN1Template = ASN1Template.contextSpecific(0).constructed().implicit(tag: ASN1Identifier.Tag.integer)
		let integer = try! asn1Decoder.decode(Int.self, from: Data(bytes), template: t)
		XCTAssert(integer == 0xa0)
	}
	
	func testDecoding_csExplicitInteger() throws
	{
		let bytes: [UInt8] = [0xa0, 0x03, 0x02, 0x01, 0xa0];
		
		let asn1Decoder = ASN1Decoder()
		let t: ASN1Template = ASN1Template.contextSpecific(0).constructed().explicit(tag: ASN1Identifier.Tag.integer)
		let integer = try! asn1Decoder.decode(Int.self, from: Data(bytes), template: t)
		XCTAssert(integer == 0xa0)
	}
	
	func testDecoding_integer() throws
	{
		let bytes: [UInt8] = [0x02, 0x01, 0xa0];
		
		let asn1Decoder = ASN1Decoder()
		let integer = try! asn1Decoder.decode(Int.self, from: Data(bytes))
		
		XCTAssert(integer == 0xa0)
	}
	

}

