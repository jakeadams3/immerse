//
//  Firestore+Query.swift
//  immerse
//
//

import Firebase

extension Query {
    func getDocuments<T: Decodable>(as type: T.Type) async throws -> [T] {
        let snapshot = try await getDocuments()
        return snapshot.documents.compactMap({ try? $0.data(as: T.self) })
    }
}
