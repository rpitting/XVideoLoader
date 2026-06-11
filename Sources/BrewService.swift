//
//  BrewService.swift
//  XVideoLoader
//  
//  Created by Reiner Pittinger on 13.04.26
//  Copyright © 2026 . All rights reserved.

import Foundation

enum BrewServiceError: LocalizedError {
    case notConnected
    case operationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConnected: return "XPC-Verbindung nicht verfügbar"
        case .operationFailed(let msg): return msg
        }
    }
}

final class BrewService {

    private var connection: NSXPCConnection?
    private let client = HomebrewHelperClient()

    func connect() {
        disconnect()
        let connection = NSXPCConnection(serviceName: "de.digitalwave.HomebrewHelper")
        connection.remoteObjectInterface = NSXPCInterface(with: HomebrewHelperProtocol.self)
        connection.exportedInterface = NSXPCInterface(with: HomebrewHelperClientProtocol.self)
        connection.exportedObject = client
        connection.interruptionHandler = {
            print("XPC: Verbindung unterbrochen")
        }
        connection.invalidationHandler = {
            print("XPC: Verbindung ungültig – Service nicht gefunden?")
        }
        connection.resume()

        self.connection = connection
    }

    func checkIfInstalled(_ program: String) async -> Bool {
        guard let proxy = connection?.remoteObjectProxy as? HomebrewHelperProtocol else {
            return false
        }

        return await withCheckedContinuation { continuation in
            proxy.isInstalled(program) { isInstalled in
                continuation.resume(returning: isInstalled)
            }
        }
    }

    func download(
        url: String,
        cookiesFilePath: String?,
        progressHandler: @escaping (Double) -> Void
    ) async throws -> String {
        guard let proxy = connection?.remoteObjectProxy as? HomebrewHelperProtocol else {
            throw BrewServiceError.notConnected
        }

        client.progressHandler = progressHandler
        defer { client.progressHandler = nil }

        return try await withCheckedThrowingContinuation { continuation in
            proxy.download(url: url, cookiesFilePath: cookiesFilePath) { filepath, errorMessage in
                if let filepath {
                    continuation.resume(returning: filepath)
                } else {
                    continuation.resume(
                        throwing: BrewServiceError.operationFailed(errorMessage ?? "Unbekannter Fehler")
                    )
                }
            }
        }
    }

    func disconnect() {
        connection?.invalidate()
        connection = nil
    }
}

final class HomebrewHelperClient: NSObject, HomebrewHelperClientProtocol {
    var progressHandler: ((Double) -> Void)?

    func downloadProgress(_ percent: Double) {
        progressHandler?(percent)
    }
}
