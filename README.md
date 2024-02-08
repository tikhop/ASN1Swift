<p align="left">
<img height="170" src="https://github.com/tikhop/ASN1Swift/blob/master/www/logo.png" />
</p>

[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/ASN1Swift.svg)](https://cocoapods.org/pods/ASN1Swift)
[![Swift Package Manager compatible](https://img.shields.io/badge/Swift%20Package%20Manager-compatible-brightgreen.svg)](https://github.com/apple/swift-package-manager)
[![Platform](https://img.shields.io/cocoapods/p/ASN1Swift.svg?style=flat)]()
[![GitHub license](https://img.shields.io/badge/license-BSD3-blue.svg)](https://raw.githubusercontent.com/tikhop/ASN1Swift/master/LICENSE)

ASN1Swift provides a transparent interface to decode ASN.1 data structures. The ASN.1 Data Structure must be encoded using BER/DER Encoding Rules. To simplify encoding and decoding process ASN1Swift implement Encoder/Decoder protocol provided by swift foundation. In other words it works preciesly the same as JSONEncoder/JSONDecoder. 

Installation
------------

### CocoaPods

To integrate ASN1Swift into your project using CocoaPods, specify it in your `Podfile`:

```ruby
platform :ios, '13.0'

target 'YOUR_TARGET' do
use_frameworks!

pod 'ASN1Swift'
end

```

Then, run the following command:

```bash
$ pod install
```

In any swift file you'd like to use ASN1Swift, import the framework with `import ASN1Swift`.

### Swift Package Manager

To integrate using Apple's Swift package manager, add the following as a dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/tikhop/ASN1Swift.git", .branch("master"))
```

Then, specify `"ASN1Swift"` as a dependency of the Target in which you wish to use ASN1Swift.

Lastly, run the following command:
```swift
swift package update
```

### Carthage

Make the following entry in your Cartfile:

```
github "tikhop/ASN1Swift" 
```

Then run `carthage update`.

If this is your first time using Carthage in the project, you'll need to go through some additional steps as explained [over at Carthage](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application).


### Requirements

- iOS 12.0+ / OSX 10.13+
- Swift 5.9+

Example
-------------

#### Decoding InAppReceipt 

```swift

let asn1Decoder = ASN1Decoder()
let r = try! asn1Decoder.decode(Receipt.self, from: Data(...))

struct Receipt: ASN1Decodable
{
    static var template: ASN1Template
    {
        return ASN1Template.universal(16).constructed()
    }

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

....
``` 

## Benchmarks

Library                                                        | Decoding Time
-------------------------------------------------------------- | ------------------
ASN1Swift                                                      | 0.154 seconds 
[filom/ASN1Decoder](https://github.com/filom/ASN1Decoder)      | 1.032 seconds
[asn1c](https://github.com/vlm/asn1c)			       | ???
[mrdepth/ASN1Decoder](https://github.com/mrdepth/ASN1Decoder)  | ???


## License

ASN1Swift is released under a BSD-3-Clause. See [LICENSE](https://github.com/tikhop/ASN1Swift/blob/master/LICENSE) for more information.
