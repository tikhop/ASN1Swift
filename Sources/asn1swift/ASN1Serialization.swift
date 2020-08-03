//
//  ASN1Serialization.swift
//  asn1swift
//
//  Created by Pavel Tikhonenko on 28.07.2020.
//

import Foundation

class ASN1Serialization
{
	@inlinable
	@inline(__always)
	static func readInt(from data: Data, l: Int) -> Int
	{
		var r: UInt64 = 0
		
		let start = data.startIndex
		let end = start + l
		
		for i in start..<end
		{
			r = r << 8
			r |= UInt64(data[i])
		}
		
		if r >= Int.max
		{
			return -1 //Invalid data
		}
		
		return Int(r)
	}
}
