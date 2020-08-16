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
	func testDecoding_DataFromOctetString() throws
	{
		let bytes: [UInt8] = [0x04, 0x18, 0x34, 0x30, 0x30, 0x31, 0x2D, 0x30, 0x31, 0x2D, 0x30, 0x31, 0x54, 0x30, 0x30, 0x3A, 0x30, 0x30, 0x3A, 0x30, 0x30, 0x2B, 0x30, 0x30, 0x30, 0x30]
		
		let asn1Decoder = ASN1Decoder()
		let r = try! asn1Decoder.decode(Data.self, from: Data(bytes), template: ASN1Template.universal(ASN1Identifier.Tag.octetString))
		print(r)
	}
	
	func testDecoding_null() throws
	{
		let bytes: [UInt8] = [0x05, 0x00]
		
		let asn1Decoder = ASN1Decoder()
		let _ = try! asn1Decoder.decode(ASN1Null.self, from: Data(bytes))
	}
	
	func testDecoding_oid() throws
	{
		let bytes: [UInt8] = [0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x07, 0x01]
		
		let asn1Decoder = ASN1Decoder()
		let r = try! asn1Decoder.decode(String.self, from: Data(bytes), template: ASN1Template.universal(ASN1Identifier.Tag.objectIdentifier))
		XCTAssert(r == "1.2.840.113549.1.7.1")
	}
	
	func testDecoding_IA5String() throws
	{
		let bytes: [UInt8] = [0x16, 0x18, 0x34, 0x30, 0x30, 0x31, 0x2D, 0x30, 0x31, 0x2D, 0x30, 0x31, 0x54, 0x30, 0x30, 0x3A, 0x30, 0x30, 0x3A, 0x30, 0x30, 0x2B, 0x30, 0x30, 0x30, 0x30]
		
		let asn1Decoder = ASN1Decoder()
		let r = try! asn1Decoder.decode(String.self, from: Data(bytes), template: ASN1Template.universal(ASN1Identifier.Tag.ia5String))
		XCTAssert(r == "4001-01-01T00:00:00+0000")
	}
	
	func testDecoding_emptyUTF8String() throws
	{
		let bytes: [UInt8] = [0x0C, 0x00]
		
		let asn1Decoder = ASN1Decoder()
		let r = try! asn1Decoder.decode(String.self, from: Data(bytes))
		XCTAssert(r == "")
	}
	
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
	
	func testDecoding_integer32() throws
	{
		let bytes: [UInt8] = [0x02, 0x02, 0x06, 0xa6];
		
		let asn1Decoder = ASN1Decoder()
		let integer = try! asn1Decoder.decode(Int32.self, from: Data(bytes))
		
		XCTAssert(integer == 1702)
	}
	func testDecoding_integer() throws
	{
		let bytes: [UInt8] = [0x02, 0x01, 0xa0];
		
		let asn1Decoder = ASN1Decoder()
		let integer = try! asn1Decoder.decode(Int.self, from: Data(bytes))
		
		XCTAssert(integer == 0xa0)
	}
	

}

