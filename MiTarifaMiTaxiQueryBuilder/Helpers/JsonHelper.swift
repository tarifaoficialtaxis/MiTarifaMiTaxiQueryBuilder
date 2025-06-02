//
//  JsonHelper.swift
//  MiTarifaMiTaxiQueryBuilder
//
//  Created by Brian Ortiz on 2025-05-14.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

class JSONHelper {
    static func printAsJSON(data: Any, title: String = "JSON Data") {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: [.prettyPrinted, .withoutEscapingSlashes])
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                print("\n--- \(title) ---\n")
                print(jsonString)
            }
        } catch {
            print("Error converting data to JSON: \(error.localizedDescription)")
        }
    }
    
    private static func convertTimestamps(in data: [String: Any]) -> [String: Any] {
        var processedData = [String: Any]()
        for (key, value) in data {
            if let timestamp = value as? Timestamp {
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                processedData[key] = dateFormatter.string(from: timestamp.dateValue())
            } else if let nestedData = value as? [String: Any] {
                processedData[key] = convertTimestamps(in: nestedData)
            } else if let nestedArray = value as? [[String: Any]] {
                processedData[key] = nestedArray.map { convertTimestamps(in: $0) }
            }
            else {
                processedData[key] = value
            }
        }
        return processedData
    }

    static func processAndPrintQuerySnapshot(snapshot: QuerySnapshot, title: String, emptyMessage: String) {
        if snapshot.isEmpty {
            print(emptyMessage)
        } else {
            var documentsData: [[String: Any]] = []
            for document in snapshot.documents {
                let data = document.data()
                let processedData = convertTimestamps(in: data)
                documentsData.append(processedData)
            }
            JSONHelper.printAsJSON(data: documentsData, title: title)
        }
    }
}
