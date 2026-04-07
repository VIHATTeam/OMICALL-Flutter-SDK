import Foundation
import AVFoundation
import SwiftUI
import OmiKit

public class OmiUtils {

    static private var instance: OmiUtils? = nil // Instance

    static func shareInstance() -> OmiUtils {
        if (instance == nil) {
           instance = OmiUtils()
        }
        return instance!
    }

    func convertDictionaryToJson(dictionary: [String: Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dictionary, options: [])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return jsonString
            }
        } catch {
            print("Error converting dictionary to JSON: \(error)")
        }
        return nil
    }
}
