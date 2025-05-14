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
        //Task { await duplicateDocument(originalDocumentID: "ROScb7V22U0xWLNQBJjD") }
        Task { await fetchUserTripsForDate(userId: "Tu4XNyUFxzc1cuEezkxAtmPD5LN2", dateString: "13-05-2025") }
        //Task { await fetchData() }
    }
    
    func fetchData() async {
        
        let db = Firestore.firestore()
        
        do {
            
            let contactsSnapshot = try await db.collection("rates")
                .getDocuments()
            
            JSONHelper.processAndPrintQuerySnapshot(snapshot: contactsSnapshot, title: "Firestore Rates Data as JSON", emptyMessage: "No rates found.")
            
        } catch {
            print("Error fetching rates: \(error.localizedDescription)")
            
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
}
