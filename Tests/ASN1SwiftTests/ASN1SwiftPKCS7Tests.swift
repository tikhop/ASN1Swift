import XCTest
@testable import ASN1Swift

final class ASN1SwiftPKCS7Tests: XCTestCase
{

	func testDecoding_newInAppReceipt() throws
	{
		self.measure {
			let asn1Decoder = ASN1Decoder()
			let r = try! asn1Decoder.decode(PKCS7Container.self, from: newReceipt)
			//XCTAssert(r.signedData.version == 1)
		}
		
		
	}
	
	func testDecoding_dataWithIndefiniteLength() throws
	{
		var r: IndefiniteLengthContainer!
		self.measure {
			let asn1Decoder = ASN1Decoder()
			r = try! asn1Decoder.decode(IndefiniteLengthContainer.self, from: Data([0x30, 0x80, 0x02, 0x01, 0x04, 0xa0, 0x80, 0x30, 0x80, 0x02, 0x01, 0x0a, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0]))
		}
		
		XCTAssert(r.integer == 0x4)
		XCTAssert(r.inner.integer == 0x0a)
	}
	
	func testDecoding_pkcs7() throws
	{
		var r: PKCS7Container!
		
		self.measure {
			let asn1Decoder = ASN1Decoder()
			r = try! asn1Decoder.decode(PKCS7Container.self, from: receipt)
		}
		
		//XCTAssert(r.signedData.version == 1)
	}
}
