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
    
    static func processAndPrintQuerySnapshot(snapshot: QuerySnapshot, title: String, emptyMessage: String) {
        if snapshot.isEmpty {
            print(emptyMessage)
        } else {
            var documentsData: [[String: Any]] = []
            for document in snapshot.documents {
                documentsData.append(document.data())
            }
            JSONHelper.printAsJSON(data: documentsData, title: title)
        }
    }
}
