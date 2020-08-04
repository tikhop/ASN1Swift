//
//  LegacyReceipt.swift
//  asn1swiftTests
//
//  Created by Pavel Tikhonenko on 03.08.2020.
//

import Foundation
import ASN1Swift

public enum InAppReceiptField: Int
{
	case environment = 0 // Sandbox, Production, ProductionSandbox
	case bundleIdentifier = 2
	case appVersion = 3
	case opaqueValue = 4
	case receiptHash = 5 // SHA-1 Hash
	case receiptCreationDate = 12
	case inAppPurchaseReceipt = 17 // The receipt for an in-app purchase.
	//TODO: case originalPurchaseDate = 18
	case originalAppVersion = 19
	case expirationDate = 21
	
	
	case quantity = 1701
	case productIdentifier = 1702
	case transactionIdentifier = 1703
	case purchaseDate = 1704
	case originalTransactionIdentifier = 1705
	case originalPurchaseDate = 1706
	case productType = 1707
	case subscriptionExpirationDate = 1708
	case webOrderLineItemID = 1711
	case cancellationDate = 1712
	case subscriptionTrialPeriod = 1713
	case subscriptionIntroductoryPricePeriod = 1719
	case promotionalOfferIdentifier = 1721
}


struct InAppReceiptPayload
{
	/// In-app purchase's receipts
	let purchases: [InAppPurchase]
	
	/// The app’s bundle identifier
	let bundleIdentifier: String
	
	/// The app’s version number
	let appVersion: String
	
	/// The version of the app that was originally purchased.
	let originalAppVersion: String
	
	/// The date that the app receipt expires
	let expirationDate: String?
	
	/// Used to validate the receipt
	let bundleIdentifierData: Data
	
	/// An opaque value used, with other data, to compute the SHA-1 hash during validation.
	let opaqueValue: Data
	
	/// A SHA-1 hash, used to validate the receipt.
	let receiptHash: Data
	
	/// The date when the app receipt was created.
	let creationDate: String
	
	/// Receipt's environment
	let environment: String
	
	/// Initialize a `InAppReceipt` passing all values
	///
	init(bundleIdentifier: String, appVersion: String, originalAppVersion: String, purchases: [InAppPurchase], expirationDate: String?, bundleIdentifierData: Data, opaqueValue: Data, receiptHash: Data, creationDate: String, environment: String)
	{
		self.bundleIdentifier = bundleIdentifier
		self.appVersion = appVersion
		self.originalAppVersion = originalAppVersion
		self.purchases = purchases
		self.expirationDate = expirationDate
		self.bundleIdentifierData = bundleIdentifierData
		self.opaqueValue = opaqueValue
		self.receiptHash = receiptHash
		self.creationDate = creationDate
		self.environment = environment
	}
}

public struct InAppPurchase
{
	public enum `Type`: Int
	{
		/// Type that we can't recognize for some reason
		case unknown = -1
		
		/// Type that customers purchase once. They don't expire.
		case nonConsumable
		
		/// Type that are depleted after one use. Customers can purchase them multiple times.
		case consumable
		
		/// Type that customers purchase once and that renew automatically on a recurring basis until customers decide to cancel.
		case nonRenewingSubscription
		
		/// Type that customers purchase and it provides access over a limited duration and don't renew automatically. Customers can purchase them again.
		case autoRenewableSubscription
	}
	
	/// The product identifier which purchase related to
	public var productIdentifier: String
	
	/// Product type
	public var productType: Type = .unknown
	
	/// Transaction identifier
	public var transactionIdentifier: String
	
	/// Original Transaction identifier
	public var originalTransactionIdentifier: String
	
	/// Purchase Date in string format
	public var purchaseDateString: String
	
	/// Original Purchase Date in string format
	public var originalPurchaseDateString: String
	
	/// Subscription Expiration Date in string format. Returns `nil` if the purchase is not a renewable subscription
	public var subscriptionExpirationDateString: String? = nil
	
	/// Cancellation Date in string format. Returns `nil` if the purchase is not a renewable subscription
	public var cancellationDateString: String? = nil
	
	/// This value is `true`if the customer’s subscription is currently in the free trial period, or `false` if not.
	public var subscriptionTrialPeriod: Bool = false
	
	/// This value is `true` if the customer’s subscription is currently in an introductory price period, or `false` if not.
	public var subscriptionIntroductoryPricePeriod: Bool = false
	
	/// A unique identifier for purchase events across devices, including subscription-renewal events. This value is the primary key for identifying subscription purchases.
	public var webOrderLineItemID: Int? = nil
	
	/// The value is an identifier of the subscription offer that the user redeemed.
	/// Returns `nil` if  the user didn't use any subscription offers.
	public var promotionalOfferIdentifier: String? = nil
	
	/// The number of consumable products purchased
	/// The default value is `1` unless modified with a mutable payment. The maximum value is 10.
	public var quantity: Int = 1
	
	public init()
	{
		originalTransactionIdentifier = ""
		productIdentifier = ""
		transactionIdentifier = ""
		purchaseDateString = ""
		originalPurchaseDateString = ""
	}
}

protocol _InAppReceipt: PKCS7
{
	var receiptPayload: InAppReceiptPayload { get }
}

extension _InAppReceipt
{
	var receiptPayload: InAppReceiptPayload { return payload as! InAppReceiptPayload }
}

extension InAppReceiptPayload: PKCS7Payload
{
	static var template: ASN1Template
	{
		return ASN1Template.universal(ASN1Identifier.Tag.octetString).explicit(tag: ASN1Identifier.Tag.set).constructed()
	}
	
	init(from decoder: Decoder) throws
	{
		var container = try decoder.unkeyedContainer()
		
		var bundleIdentifier = ""
		var bundleIdentifierData = Data()
		var appVersion = ""
		var originalAppVersion = ""
		var purchases = [InAppPurchase]()
		var opaqueValue = Data()
		var receiptHash = Data()
		var expirationDate: String? = ""
		var receiptCreationDate: String = ""
		var environment: String = ""
		
		
		var attr: [ReceiptAttribute] = []
		
		let asn1Decoder = ASN1Decoder()
		
		while !container.isAtEnd
		{
			let attribute = try container.decode(ReceiptAttribute.self)
			
			guard let receiptField = InAppReceiptField(rawValue: attribute.type) else
			{
				continue
			}
			
			let octetString = attribute.value
			let valueData = try asn1Decoder.decode(Data.self, from: octetString, template: .universal(ASN1Identifier.Tag.octetString))
			
			switch (receiptField)
			{
			case .bundleIdentifier:
				bundleIdentifier = try asn1Decoder.decode(String.self, from: valueData)
				bundleIdentifierData = octetString //valueData TODO: check this
			case .appVersion:
				appVersion = try asn1Decoder.decode(String.self, from: valueData)
			case .opaqueValue:
				opaqueValue = valueData
			case .receiptHash:
				receiptHash = valueData
			case .inAppPurchaseReceipt:
				purchases.append(try asn1Decoder.decode(InAppPurchase.self, from: valueData))
				break
			case .originalAppVersion:
				originalAppVersion = try asn1Decoder.decode(String.self, from: valueData)
			case .expirationDate:
				expirationDate = try asn1Decoder.decode(String.self, from: valueData, template: .universal(ASN1Identifier.Tag.ia5String))
			case .receiptCreationDate:
				receiptCreationDate = try asn1Decoder.decode(String.self, from: valueData, template: .universal(ASN1Identifier.Tag.ia5String))
			case .environment:
				environment = try asn1Decoder.decode(String.self, from: valueData)
			default:
				print("attribute.type = \(String(describing: attribute.type)))")
			}
			
			attr.append(attribute)
		}
		
		self.init(bundleIdentifier: bundleIdentifier,
				  appVersion: appVersion,
				  originalAppVersion: originalAppVersion,
				  purchases: purchases,
				  expirationDate: expirationDate,
				  bundleIdentifierData: bundleIdentifierData,
				  opaqueValue: opaqueValue,
				  receiptHash: receiptHash,
				  creationDate: receiptCreationDate,
				  environment: environment)
	}
}

extension InAppPurchase: ASN1Decodable
{
	public init(from decoder: Decoder) throws
	{
		
		self.init()
		
		var container = try decoder.unkeyedContainer()
		let asn1Decoder = ASN1Decoder()
		
		while !container.isAtEnd
		{
			let attribute = try container.decode(ReceiptAttribute.self)
			
			guard let field = InAppReceiptField(rawValue: attribute.type) else
			{
				continue
			}
			
			let octetString = attribute.value
			let valueData = try asn1Decoder.decode(Data.self, from: octetString, template: .universal(ASN1Identifier.Tag.octetString))
			
			switch field
			{
			case .quantity:
				quantity = try asn1Decoder.decode(Int.self, from: valueData)
			case .productIdentifier:
				productIdentifier = try asn1Decoder.decode(String.self, from: valueData)
			case .productType:
				productType = Type(rawValue: try asn1Decoder.decode(Int.self, from: valueData)) ?? .unknown
			case .transactionIdentifier:
				transactionIdentifier = try asn1Decoder.decode(String.self, from: valueData)
			case .purchaseDate:
				purchaseDateString = try asn1Decoder.decode(String.self, from: valueData, template: .universal(ASN1Identifier.Tag.ia5String))
			case .originalTransactionIdentifier:
				originalTransactionIdentifier = try asn1Decoder.decode(String.self, from: valueData)
			case .originalPurchaseDate:
				originalPurchaseDateString = try asn1Decoder.decode(String.self, from: valueData, template: .universal(ASN1Identifier.Tag.ia5String))
			case .subscriptionExpirationDate:
				if !valueData.isEmpty
				{
					let str = try asn1Decoder.decode(String.self, from: valueData, template: .universal(ASN1Identifier.Tag.ia5String))
					subscriptionExpirationDateString = str == "" ? nil : str
				}
			case .cancellationDate:
				if !valueData.isEmpty
				{
					let str = try asn1Decoder.decode(String.self, from: valueData, template: .universal(ASN1Identifier.Tag.ia5String))
					cancellationDateString = str == "" ? nil : str
				}
			case .webOrderLineItemID:
				webOrderLineItemID = try asn1Decoder.decode(Int.self, from: valueData)
			case .subscriptionTrialPeriod:
				subscriptionTrialPeriod = (try asn1Decoder.decode(Int.self, from: valueData)) != 0
			case .subscriptionIntroductoryPricePeriod:
				subscriptionIntroductoryPricePeriod = (try asn1Decoder.decode(Int.self, from: valueData)) != 0
			case .promotionalOfferIdentifier:
				promotionalOfferIdentifier = try asn1Decoder.decode(String.self, from: valueData)
			default:
				break
			}
		}
	}
	
	public static var template: ASN1Template
	{
		return ASN1Template.universal(ASN1Identifier.Tag.set).constructed()
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

/// In App Receipt
class _PKCS7Container: _InAppReceipt
{
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

extension _PKCS7Container
{
	var payload: PKCS7Payload
	{
		return signedData.contentInfo.payload.payload
	}
}

extension _PKCS7Container
{
	struct SignedData: ASN1Decodable
	{
		static var template: ASN1Template
		{
			return ASN1Template.contextSpecific(0).constructed().explicit(tag: 16).constructed()
		}
		
		var version: Int
		var alg: ASN1SkippedField
		var contentInfo: ContentInfo
		
		enum CodingKeys: ASN1CodingKey
		{
			case version
			case alg
			case contentInfo
			
			var template: ASN1Template
			{
				switch self
				{
				case .version:
					return .universal(ASN1Identifier.Tag.integer)
				case .alg:
					return ASN1Template.universal(ASN1Identifier.Tag.set).constructed()
				case .contentInfo:
					return ContentInfo.template
				}
			}
		}
	}
	
	struct ContentInfo: ASN1Decodable
	{
		static var template: ASN1Template
		{
			return ASN1Template.universal(ASN1Identifier.Tag.sequence).constructed()
		}
		
		var oid: ASN1SkippedField
		var payload: PayloadContainer
		
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
					return PayloadContainer.template
				}
			}
		}
	}
	
	struct PayloadContainer: ASN1Decodable
	{
		var payload: InAppReceiptPayload
		
		static var template: ASN1Template
		{
			return ASN1Template.contextSpecific(0).constructed().explicit(tag: ASN1Identifier.Tag.octetString).constructed()
		}
		
		enum CodingKeys: ASN1CodingKey
		{
			case payload
			
			var template: ASN1Template
			{
				switch self
				{
				case .payload:
					return InAppReceiptPayload.template
				}
			}
		}
	}
}

/// Legacy In App Receipt
class __PKCS7Container: _InAppReceipt
{
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

extension __PKCS7Container
{
	var payload: PKCS7Payload
	{
		return signedData.contentInfo.payload.payload
	}
}

extension __PKCS7Container
{
	struct SignedData: ASN1Decodable
	{
		static var template: ASN1Template
		{
			return ASN1Template.contextSpecific(0).constructed().explicit(tag: 16).constructed()
		}
		
		var version: Int
		var alg: ASN1SkippedField
		var contentInfo: ContentInfo
		
		enum CodingKeys: ASN1CodingKey
		{
			case version
			case alg
			case contentInfo
			
			var template: ASN1Template
			{
				switch self
				{
				case .version:
					return .universal(ASN1Identifier.Tag.integer)
				case .alg:
					return ASN1Template.universal(ASN1Identifier.Tag.set).constructed()
				case .contentInfo:
					return ContentInfo.template
				}
			}
		}
	}
	
	struct ContentInfo: ASN1Decodable
	{
		static var template: ASN1Template
		{
			return ASN1Template.universal(ASN1Identifier.Tag.sequence).constructed()
		}
		
		var oid: ASN1SkippedField
		var payload: PayloadContainer
		
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
					return PayloadContainer.template
				}
			}
		}
	}
	
	struct PayloadContainer: ASN1Decodable
	{
		var payload: InAppReceiptPayload
		
		static var template: ASN1Template
		{
			return ASN1Template.contextSpecific(0).constructed()
		}
		
		enum CodingKeys: ASN1CodingKey
		{
			case payload
			
			var template: ASN1Template
			{
				switch self
				{
				case .payload:
					return InAppReceiptPayload.template
				}
			}
		}
	}
}


struct PKC7
{
	enum OID: String
	{
		case data = "1.2.840.113549.1.7.1"
		case signedData = "1.2.840.113549.1.7.2"
		case envelopedData = "1.2.840.113549.1.7.3"
		case signedAndEnvelopedData = "1.2.840.113549.1.7.4"
		case digestedData = "1.2.840.113549.1.7.5"
		case encryptedData = "1.2.840.113549.1.7.6"
	}
}

protocol PKCS7: ASN1Decodable
{
	var payload: PKCS7Payload { get }
}

extension PKCS7
{
	static var template: ASN1Template
	{
		return ASN1Template.universal(16).constructed()
	}
}

protocol PKCS7Payload: ASN1Decodable
{
	
}



extension PKCS7
{
	/// Find content by pkcs7 oid
	///
	/// - Returns: Data slice make sure you allocate memory and copy bytes for long term usage
	func extractContent(by oid: PKC7.OID) -> Data?
	{
		var raw = Data()
		return extractContent(by: oid, from: &raw)
	}
	
	/// Extract content by pkcs7 oid
	///
	/// - Returns: Data slice make sure you allocate memory and copy bytes for long term usage
	func extractContent(by oid: PKC7.OID, from data: inout Data) -> Data?
	{
		return nil
	}
	
	/// Check if any data available for provided pkcs7 oid
	///
	///
	func checkContentExistance(by oid: PKC7.OID) -> Bool
	{
		var raw = Data()
		
		let r = checkContentExistance(by: oid, in: &raw)
		guard r.0, let _ = r.offset else
		{
			return false
		}
		
		return true
	}
	
	/// Extract content by pkcs7 oid
	///
	/// - Returns: Data slice make sure you allocate memory and copy bytes for long term usage
	func checkContentExistance(by oid: PKC7.OID, in data: inout Data) -> (Bool, offset: Int?)
	{
		return (false, nil)
	}
}
