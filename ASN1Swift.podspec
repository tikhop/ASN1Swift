Pod::Spec.new do |s|

s.name         = "ASN1Swift"
s.version      = "1.0.0"
s.summary      = "Decoding ASN.1 in swift"
s.description  = "A lightweight swift library for decoding ASN.1 structure. Similar to `JSONDecoder`"

s.homepage     = "https://github.com/tikhop/ASN1Swift"
s.license      = "MIT"
s.source       = { :git => "https://github.com/tikhop/ASN1Swift.git", :tag => "#{s.version}" }

s.author       = { "Pavel Tikhonenko" => "hi@tikhop.com" }

s.swift_versions = ['5.3']
s.ios.deployment_target = '9.0'
s.osx.deployment_target = '10.10'
s.tvos.deployment_target = '9.0'
s.watchos.deployment_target = '2.0'
s.requires_arc = true

s.source_files  = "Sources/ASN1Swift/*.{swift}"

end
