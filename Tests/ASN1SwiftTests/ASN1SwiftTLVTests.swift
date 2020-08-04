//
//  File.swift
//  
//
//  Created by Pavel Tikhonenko on 04.08.2020.
//

import XCTest
@testable import ASN1Swift

final class ASN1SwiftTLVTests: XCTestCase
{
	
	
	func testLengthFetching_simpleForm() throws
	{
		let bytes = Data([0x04])
		
		var r: Int = 0
		let dec = _ASN1Decoder()
		let consumed = dec.fetchLength(from: bytes, isConstructed: false, rLen: &r)
		
		XCTAssert(r == 4)
		XCTAssert(consumed == 1)
	}
	
	func testLengthFetching_longForm() throws
	{
		let bytes = Data([0x83, 0x01, 0x34, 0xEB])
		
		var r: Int = 0
		let dec = _ASN1Decoder()
		let consumed = dec.fetchLength(from: bytes, isConstructed: true, rLen: &r)
		
		XCTAssert(r == 79083)
		XCTAssert(consumed == 4)
	}
	
	func testLengthFetching_indefiniteLength() throws
	{
		let bytes = Data([0x80, 0xE1])
		
		var r: Int = 0
		let dec = _ASN1Decoder()
		let consumed = dec.fetchLength(from: bytes, isConstructed: true, rLen: &r)
		
		XCTAssert(r == -1)
		XCTAssert(consumed == 1)
	}
	
	func testTagChecking_CSSequence() throws
	{
		let bytes: [UInt8] = [0x30, 0x83, 0x01, 0x34, 0xEB, 0x02, 0x83, 0x01, 0x34, 0xE6]
		
		//var r: ASN1Tag = 0
		let dec = _ASN1Decoder()
		var l: Int = 0
		let consumed = try! dec.checkTags(from: Data(bytes), with: [ASN1Identifier.Tag.sequence | ASN1Identifier.Modifiers.constructed], lastTlvLength: &l)
		
		XCTAssert(consumed == 5)
	}
	
	func testTagChecking_CSInteger() throws
	{
		let bytes: [UInt8] = [0xa0, 0x3, 0x2, 0x01, 0xa0]
		
		//var r: ASN1Tag = 0
		let dec = _ASN1Decoder()
		var l: Int = 0
		let consumed = try! dec.checkTags(from: Data(bytes), with: [ASN1Identifier.Modifiers.contextSpecific | ASN1Identifier.Modifiers.constructed, ASN1Identifier.Tag.integer], lastTlvLength: &l)
		
		XCTAssert(consumed == 4)
	}
	
	func testTagFetching_simpleForm() throws
	{
		let bytes: [UInt8] = [ASN1Identifier.Tag.integer]
		
		var r: ASN1Tag = 0
		let dec = _ASN1Decoder()
		let consumed = dec.fetchTag(from: Data(bytes), to: &r)
		
		XCTAssert(r == ASN1Identifier.Tag.integer)
		XCTAssert(consumed == bytes.count)
	}
	
	func testTagFetching_complex() throws
	{
		let bytes: [UInt8] = [0x3f, 0x02, 0x10]
		
		var r: ASN1Tag = 0
		let dec = _ASN1Decoder()
		let consumed = dec.fetchTag(from: Data(bytes), to: &r)
		
		XCTAssert(r == 8)
		XCTAssert(consumed == 2)
	}
	
}
