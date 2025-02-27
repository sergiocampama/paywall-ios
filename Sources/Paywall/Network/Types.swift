//
//  File.swift
//  
//
//  Created by Jake Mor on 8/11/21.
//

import UIKit
import Foundation
import StoreKit
import CloudKit

internal struct EmptyResponse: Decodable {}

// MARK: Paywall

internal struct PaywallRequest: Codable {
    var appUserId: String
}

internal struct PaywallFromEventRequest: Codable {
	var appUserId: String
	var event: EventData? = nil
}

internal struct PaywallsResponse: Decodable {
    var paywalls: [PaywallResponse]
}

/// `PaywallInfo` is the primary class used to distinguish one paywall from another. Used primarily in `Paywall.present(onPresent:onDismiss)`'s completion handlers.
public class PaywallInfo: NSObject {
	
	/// Superwall's internal identifier for this paywall.
	internal let id: String
	
	/// The identifier set for this paywall in Superwall's web dashboard.
	public let identifier: String
	
	/// The name set for this paywall in Superwall's web dashboard.
	public let name: String
	public let slug: String
	
	/// The URL where this paywall is hosted.
	public let url: URL?
		
	/// The name of the event that triggered this Paywall. Defaults to `nil` if `triggeredByEvent` is false.
	public let presentedByEventWithName: String?
	
	/// The Superwall internal id (for debugging) of the event that triggered this Paywall. Defaults to `nil` if `triggeredByEvent` is false.
	public let presentedByEventWithId: String?
	
	/// The ISO date string (sorry) describing when the event triggered this paywall. Defaults to `nil` if `triggeredByEvent` is false.
	public let presentedByEventAt: String?
	
	/// How the paywall was presented, either 'programmatically', 'identifier', or 'event'
	public let presentedBy: String
	
	/// An array of product IDs that this paywall is displaying in `[Primary, Secondary, Tertiary]` order.
	public let productIds: [String]
	
	init(id: String, identifier: String, name: String, slug: String, url: URL?, productIds: [String], fromEventData: EventData?, calledByIdentifier: Bool = false) {
		self.id = id
		self.identifier = identifier
		self.name = name
		self.slug = slug
		self.url = url
		self.productIds = productIds
		self.presentedByEventWithName = fromEventData?.name
		self.presentedByEventAt = fromEventData?.createdAt
		self.presentedByEventWithId = fromEventData?.id.lowercased()
		
		if fromEventData != nil {
			self.presentedBy = "event"
		} else if calledByIdentifier {
			self.presentedBy = "identifier"
		} else {
			self.presentedBy = "programmatically"
		}
		
	}
}

internal struct PaywallResponse: Decodable {
    var id: String? = nil
    var name: String? = nil
    var slug: String? = nil
	var identifier: String? = nil
    var url: String
    var paywalljsEvent: String
    
    var presentationStyle: PaywallPresentationStyle = .sheet
    var backgroundColorHex: String? = nil
    
    var products: [Product]
    var variables: [Variables]? = []
    
    var idNonOptional: String {
        return id ?? ""
    }
	
//	var paywallInfo: PaywallInfo {
//
//	}
	
	func getPaywallInfo(fromEvent: EventData?, calledByIdentifier: Bool = false) -> PaywallInfo {
		return PaywallInfo(id: id ?? "unknown", identifier: identifier ?? "unknown", name: name ?? "unknown", slug: slug ?? "unknown", url: URL(string: url), productIds: productIds, fromEventData: fromEvent, calledByIdentifier: calledByIdentifier)
	}
    
    var paywallBackgroundColor: UIColor {
        
        if let s = backgroundColorHex {
            return UIColor(hexString: s)
        }
        
        return UIColor.darkGray
    }
    
    var productIds: [String] {
        return products.map { $0.productId }
    }
    
    var templateVariables: TemplateVariables {
        let variables = variables ?? []
        let vars = variables.reduce([String: [String:String]]()) { (dict, variable) -> [String: [String:String]] in
            var dict = dict
            dict[variable.key] = variable.value
            return dict
        }
        
        return TemplateVariables(event_name: "template_variables", variables: vars)
    }
	
	var userVariables: JSON {
		let values: [String: Any] = [
			"event_name":"template_variables",
			"variables": [
				"user": Store.shared.userAttributes,
				"device": templateDevice.dictionary ?? [String: Any]()
			]
		]
		return JSON(values)
	}
    
    var isFreeTrialAvailable: Bool? = false
    
    var _isFreeTrialAvailable: Bool {
        return isFreeTrialAvailable ?? false
    }
    
    var templateSubstitutionsPrefix: TemplateSubstitutionsPrefix {
        // TODO: Jake decide if we should send `freeTrial` or `null`
        return  TemplateSubstitutionsPrefix(event_name: "template_substitutions_prefix", prefix: _isFreeTrialAvailable ? "freeTrial" : nil)
    }

    var templateProducts: TemplateProducts {
        return TemplateProducts(event_name: "products", products: products)
    }
    
    var templateDevice: TemplateDevice {
        let aliases: [String]
        if let alias = Store.shared.aliasId {
            aliases = [alias]
        } else {
            aliases = []
        }

        return TemplateDevice(publicApiKey: Store.shared.apiKey ?? "", platform: "iOS", appUserId: Store.shared.appUserId ?? "", aliases: aliases, vendorId: DeviceHelper.shared.vendorId, appVersion: DeviceHelper.shared.appVersion, osVersion: DeviceHelper.shared.osVersion, deviceModel: DeviceHelper.shared.model, deviceLocale: DeviceHelper.shared.locale, deviceLanguageCode: DeviceHelper.shared.languageCode, deviceCurrencyCode: DeviceHelper.shared.currencyCode, deviceCurrencySymbol: DeviceHelper.shared.currencySymbol)
    }
    
    var templateEventsBase64String: String {
		
		let encodedStrings = [encodedEventString(templateDevice), encodedEventString(templateProducts), encodedEventString(templateVariables), encodedEventString(templateSubstitutionsPrefix), encodedEventString(userVariables)]
		
		let string = "[" + encodedStrings.joined(separator: ",") + "]"

		let utf8str = string.data(using: .utf8)
		return utf8str?.base64EncodedString() ?? ""
	}
	
	internal func equals(_ r: PaywallResponse) -> Bool {
		let sameIdentity = id == r.id && identifier == r.identifier && name == r.name && slug == r.slug && identifier == r.identifier && url == r.url && paywalljsEvent == r.paywalljsEvent && presentationStyle == r.presentationStyle && backgroundColorHex == r.backgroundColorHex
		
		let sameProducts = r.productIds == productIds
		
		return sameIdentity && sameProducts
	}
    
    private func encodedEventString<T: Codable>(_ input: T) -> String {
        let data = try? JSONEncoder().encode(input)
        return data != nil ? String(data: data!, encoding: .utf8) ?? "{}" : "{}"
    }
}

internal struct Variables: Decodable {
    var key: String
    var value: [String: String]
}

internal enum PaywallPresentationStyle: String, Decodable {
    case sheet = "SHEET"
    case modal = "MODAL"
    case fullscreen = "FULLSCREEN"
}

internal struct Product: Codable {
    var product: ProductType
    var productId: String
}


internal  enum ProductType: String, Codable {
    case primary
    case secondary
    case tertiary
}

internal struct TemplateVariables: Codable {
    var event_name: String
    var variables: [String: [String: String]]
}

internal struct TemplateSubstitutionsPrefix: Codable {
    var event_name: String
    // Right now can be `null` or `freeTrial`
    var prefix: String?
}

internal struct TemplateProducts: Codable {
    var event_name: String
    var products: [Product]
}

internal struct TemplateDevice: Codable {
    var publicApiKey: String
    var platform: String
    var appUserId: String
    var aliases: [String]
    var vendorId: String
    var appVersion: String
    var osVersion: String
    var deviceModel: String
    var deviceLocale: String
    var deviceLanguageCode: String
    var deviceCurrencyCode: String
    var deviceCurrencySymbol: String
}

// Mark - Events
internal struct EventsRequest: Codable {
    var events: [JSON]
}

internal struct EventsResponse: Codable {
    var status: String
}

internal struct EventData: Codable {
	var id: String
	var name: String
	var parameters: JSON
	var createdAt: String
	
	var jsonData: JSON {
		return [
			"event_id": JSON(id),
			"event_name": JSON(name),
			"parameters": parameters,
			"created_at": JSON(createdAt),
		]
	}
}

// Config

internal struct ProductConfig: Decodable {
	var identifier: String
}

internal struct PaywallConfig: Decodable {
	var identifier: String
	var products: [ProductConfig]
}

internal struct ConfigResponse: Decodable {
	var triggers: [Trigger]
	var paywalls: [PaywallConfig]
	var logLevel: Int
//	var productIdentifierGroups: [[String]]
	
	func cache() {
		for paywall in paywalls {
			StoreKitManager.shared.get(productsWithIds: paywall.products.map { $0.identifier }, completion: nil)
			PaywallManager.shared.viewController(identifier: paywall.identifier, event: nil, cached: true, completion: nil)
		}
	}
}

// Triggers

internal struct Trigger: Decodable {
	var eventName: String
}


extension Encodable {
  var dictionary: [String: Any]? {
	guard let data = try? JSONEncoder().encode(self) else { return nil }
	return (try? JSONSerialization.jsonObject(with: data, options: .allowFragments)).flatMap { $0 as? [String: Any] }
  }
}
