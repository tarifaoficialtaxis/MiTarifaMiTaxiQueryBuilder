//
//  ContentViewModel.swift
//  MiTarifaMiTaxiQueryBuilder
//
//  Created by Brian Ortiz on 2025-05-14.
//

import Foundation
import FirebaseCore
import FirebaseFirestore

class ContentViewModel: ObservableObject {
    
    let db = Firestore.firestore()
    
    init() {
        Task { await duplicateDocument(originalDocumentID: "ROScb7V22U0xWLNQBJjD")}
    }
    
    func fetchData() async {
        
        let db = Firestore.firestore()
        
        do {
            
            let contactsSnapshot = try await db.collection("rates")
            //.whereField("city", isEqualTo: "Bogotá")
                .getDocuments()
            
            var documentsData: [[String: Any]] = []
            for document in contactsSnapshot.documents {
                documentsData.append(document.data())
            }
            
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted // For readable JSON output
            
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: documentsData, options: .prettyPrinted)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print("\n--- Firestore Data as JSON (from Dictionaries) ---\n")
                    print(jsonString)
                }
                
            } catch {
                print("Error converting data to JSON: \(error.localizedDescription)")
            }
            
        } catch {
            print("Error fetching trips: \(error.localizedDescription)")
            
        }
    }
    
    func duplicateDocument(originalDocumentID: String) async {
        let docRef = db.collection("rates").document(originalDocumentID)
        
        do {
            let documentSnapshot = try await docRef.getDocument()
            
            guard let dataToDuplicate = documentSnapshot.data() else {
                print("Error: Document \(originalDocumentID) does not exist or has no data.")
                return
            }
            
            var newDocumentRef: DocumentReference?
            newDocumentRef = try await db.collection("rates").addDocument(data: dataToDuplicate)
            if let newID = newDocumentRef?.documentID {
                print("Successfully duplicated document \(originalDocumentID) to new document ID: \(newID)")
            }
            
        } catch {
            print("Error duplicating document \(originalDocumentID): \(error.localizedDescription)")
        }
    }
}
