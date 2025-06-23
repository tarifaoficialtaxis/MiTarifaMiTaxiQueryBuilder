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
        //Task { await duplicateDocument(collection: "contacts", documentID: "3r5VVAJpxpbtx7u7SNlw") }
        //Task { await fetchUserTripsForDate(userId: "uIeFGe937wd0d0r5ItGK7RfFKut2", dateString: "02-06-2025") }
        //Task { await fetchData() }
        
        Task { await addRoleToUsers() }
    }
    
    func fetchData() async {
        
        let db = Firestore.firestore()
        
        do {
            
            let snapshot = try await db.collection("users")
                .whereField("city", isEqualTo: "Bogotá")
            //.whereField("lastActive", isNotEqualTo: NSNull())
                .getDocuments()
            
            JSONHelper.processAndPrintQuerySnapshot(snapshot: snapshot, title: "Firestore Data as JSON", emptyMessage: "No data found.")
            
        } catch {
            print("Error fetching data: \(error.localizedDescription)")
            
        }
    }
    
    func duplicateDocument(collection: String, documentID: String) async {
        let docRef = db.collection(collection).document(documentID)
        
        do {
            let documentSnapshot = try await docRef.getDocument()
            
            guard let dataToDuplicate = documentSnapshot.data() else {
                print("Error: Document \(documentID) does not exist or has no data.")
                return
            }
            
            var newDocumentRef: DocumentReference?
            newDocumentRef = try await db.collection(collection).addDocument(data: dataToDuplicate)
            if let newID = newDocumentRef?.documentID {
                print("Successfully duplicated document \(documentID) to new document ID: \(newID)")
            }
            
        } catch {
            print("Error duplicating document \(documentID): \(error.localizedDescription)")
        }
    }
    
    func fetchUserTripsForDate(userId: String, dateString: String) async {
        let db = Firestore.firestore()
        
        let inputDateFormatter = DateFormatter()
        inputDateFormatter.dateFormat = "dd-MM-yyyy"
        inputDateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        guard let specificDate = inputDateFormatter.date(from: dateString) else {
            print("Error: Invalid date string format. Please use dd-MM-yyyy")
            return
        }
        
        var utcCalendar = Calendar.current
        guard let utcTimeZone = TimeZone(secondsFromGMT: 0) else {
            print("Error creating UTC TimeZone")
            return
        }
        utcCalendar.timeZone = utcTimeZone
        
        let startOfSpecifiedDayUTC = utcCalendar.startOfDay(for: specificDate)
        
        guard let startOfNextDayUTC = utcCalendar.date(byAdding: .day, value: 1, to: startOfSpecifiedDayUTC) else {
            print("Error calculating start of the next day UTC")
            return
        }
        
        let isoDateFormatter = ISO8601DateFormatter()
        isoDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let startOfSpecifiedDayString = isoDateFormatter.string(from: startOfSpecifiedDayUTC)
        let startOfNextDayString = isoDateFormatter.string(from: startOfNextDayUTC)
        
        do {
            let tripsSnapshot = try await db.collection("trips")
                .whereField("userId", isEqualTo: userId)
                .whereField("endHour", isGreaterThanOrEqualTo: startOfSpecifiedDayString)
                .whereField("endHour", isLessThan: startOfNextDayString)
                .getDocuments()
            
            let emptyMessage = "No trips found for \(dateString) (from \(startOfSpecifiedDayString) to \(startOfNextDayString))."
            JSONHelper.processAndPrintQuerySnapshot(snapshot: tripsSnapshot, title: "User Trips for \(dateString)", emptyMessage: emptyMessage)
            
        } catch {
            print("Error fetching user trips for \(dateString): \(error.localizedDescription)")
        }
    }
    
    func addRoleToUsers() async {
        do {
            let snapshot = try await db.collection("users").getDocuments()
            for doc in snapshot.documents {
                // Recupera el valor actual (puede no existir o ser NSNull)
                let role = doc.data()["role"]
                if role == nil || role is NSNull {
                    try await doc.reference.updateData(["role": "USER"])
                }
            }
            print("✅ Se ha añadido `role: \"USER\"` a todos los usuarios con role faltante o nulo")
        } catch {
            print("❌ Error actualizando roles: \(error.localizedDescription)")
        }
    }
}
