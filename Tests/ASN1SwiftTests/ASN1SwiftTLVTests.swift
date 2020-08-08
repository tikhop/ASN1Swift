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
		
		bytes.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
			
			let pp = p.baseAddress!.assumingMemoryBound(to: UInt8.self)
			
			var r: Int = 0
			let consumed = fetchLength(from: pp, size: 1, isConstructed: false, rLen: &r)
			
			XCTAssert(r == 4)
			XCTAssert(consumed == 1)
		}
	}
	
	func testLengthFetching_longForm() throws
	{
		let bytes = Data([0x83, 0x01, 0x34, 0xEB])
		
		bytes.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
			
			let pp = p.baseAddress!.assumingMemoryBound(to: UInt8.self)
			
			var r: Int = 0
			let consumed = fetchLength(from: pp, size: bytes.count, isConstructed: false, rLen: &r)
			
			XCTAssert(r == 79083)
			XCTAssert(consumed == 4)
		}
	}
	
	func testLengthFetching_indefiniteLength() throws
	{
		let bytes = Data([0x80, 0xE1])
		
		bytes.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
			
			let pp = p.baseAddress!.assumingMemoryBound(to: UInt8.self)
			
			var r: Int = 0
			let consumed = fetchLength(from: pp, size: bytes.count, isConstructed: true, rLen: &r)
			
			XCTAssert(r == -1)
			XCTAssert(consumed == 1)
		}
	}
	
	func testTagChecking_CSSequence() throws
	{
		let bytes: [UInt8] = [0x30, 0x83, 0x01, 0x34, 0xEB, 0x02, 0x83, 0x01, 0x34, 0xE6]
		
		bytes.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
			
			let pp = p.baseAddress!.assumingMemoryBound(to: UInt8.self)
			
			var l: Int = 0
			let consumed = try! checkTags(from: pp, size: bytes.count, with: [ASN1Identifier.Tag.sequence | ASN1Identifier.Modifiers.constructed], lastTlvLength: &l)
			
			XCTAssert(consumed == 5)
		}
	}
	
	func testTagChecking_CSInteger() throws
	{
		let bytes: [UInt8] = [0xa0, 0x3, 0x2, 0x01, 0xa0]
		
		bytes.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
			
			let pp = p.baseAddress!.assumingMemoryBound(to: UInt8.self)
			
			var l: Int = 0
			let consumed = try! checkTags(from: pp, size: bytes.count, with: [ASN1Identifier.Modifiers.contextSpecific | ASN1Identifier.Modifiers.constructed, ASN1Identifier.Tag.integer], lastTlvLength: &l)
			
			XCTAssert(consumed == 4)
		}
	}
	
	func testTagFetching_simpleForm() throws
	{
		let bytes: [UInt8] = [ASN1Identifier.Tag.integer]
		
		bytes.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
			
			let pp = p.baseAddress!.assumingMemoryBound(to: UInt8.self)
			
			var r: ASN1Tag = 0
			let consumed = fetchTag(from: pp, size: bytes.count, to: &r)
			
			XCTAssert(r == ASN1Identifier.Tag.integer)
			XCTAssert(consumed == bytes.count)
		}
	}
	
	func testTagFetching_complex() throws
	{
		let bytes: [UInt8] = [0x3f, 0x02, 0x10]
		
		bytes.withUnsafeBytes { (p: UnsafeRawBufferPointer) in
			
			let pp = p.baseAddress!.assumingMemoryBound(to: UInt8.self)
			
			var r: ASN1Tag = 0
			let consumed = fetchTag(from: pp, size: bytes.count, to: &r)
			
			XCTAssert(r == 8)
			XCTAssert(consumed == 2)
		}
		
	}
	
}
