Pod::Spec.new do |s|

	s.name         = "Paywall"
    s.version      = "2.2.0"
	s.summary      = "Superwall: In-App Paywalls Made Easy"
	s.description  = "Paywall infrastructure for mobile apps :) we make things like editing your paywall and running price tests as easy as clicking a few buttons. www.superwall.me"

	s.homepage     = "https://github.com/superwall-me/paywall-ios"
	s.license      =  { :type => 'MIT', :text => <<-LICENSE
		MIT License

		Copyright (c) 2021 Jake Mor

		Permission is hereby granted, free of charge, to any person obtaining a copy
		of this software and associated documentation files (the "Software"), to deal
		in the Software without restriction, including without limitation the rights
		to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
		copies of the Software, and to permit persons to whom the Software is
		furnished to do so, subject to the following conditions:

		The above copyright notice and this permission notice shall be included in all
		copies or substantial portions of the Software.

		THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
		IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
		FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
		AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
		LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
		OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
		SOFTWARE.
	    LICENSE
	}
	s.source       = { :git => "https://github.com/superwall-me/paywall-ios.git", :tag => "#{s.version}" }

	s.author       = { "Jake Mor" => "jake@superwall.me" }
	s.documentation_url = "https://docs.superwall.me/"
	s.swift_versions = ['5.3']
	s.ios.deployment_target = '12.0'
	s.requires_arc = true

  s.source_files  = "Sources/**/*.{swift}"
  s.resource_bundles = {
    "Paywall_Paywall" => ["Sources/Paywall/*.xcassets"]
  }
  s.dependency 'TPInAppReceipt', '~> 3.0.0'

end
