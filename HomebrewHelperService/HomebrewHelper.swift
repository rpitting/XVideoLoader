//
//  HomebrewHelper.swift
//  XVideoLoader
//  
//  Created by Reiner Pittinger on 13.04.26
//  Copyright © 2026 ___ORGANIZATIONNAME___. All rights reserved.

import Foundation

class HomebrewHelper: NSObject, HomebrewHelperProtocol {

    private static func installPath(for programName: String) -> String? {
        let paths = [
            "/opt/homebrew/bin/\(programName)",
            "/usr/local/bin/\(programName)",
        ]
        return paths.first { FileManager.default.fileExists(atPath: $0) }
    }

    func isInstalled(_ programName: String, reply: @escaping (Bool) -> Void) {
        reply(Self.installPath(for: programName) != nil)
    }

    func download(
        url: String,
        cookiesFilePath: String?,
        reply: @escaping (String?, String?) -> Void
    ) {
        guard let ytdlp = Self.installPath(for: "yt-dlp") else {
            reply(nil, "yt-dlp nicht gefunden")
            return
        }

        let clientProxy = NSXPCConnection.current()?.remoteObjectProxy
            as? HomebrewHelperClientProtocol

        let downloadsDir = URL.downloadsDirectory.path(percentEncoded: false)

        var args = [
            "--no-playlist",
            "--quiet",
            "--no-warnings",
            "--progress",
            "--newline",
            "--color", "never",
            "--progress-template", "[XVL]%(progress._percent_str)s",
            "--xattrs",
            "-P", downloadsDir,
            "-o", "%(uploader_id)s-%(id)s.%(ext)s",
            "--print", "after_move:filepath",
        ]
        if let cookiesFilePath {
            args += ["--cookies", cookiesFilePath]
        }
        args.append(url)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: ytdlp)
        process.arguments = args

        let outPipe = Pipe()
        let errPipe = Pipe()
        process.standardOutput = outPipe
        process.standardError = errPipe

        let lock = NSLock()
        var stdoutLineBuffer = Data()
        var nonProgressStdout = Data()
        var stderrData = Data()
        let stdoutDone = DispatchSemaphore(value: 0)
        let stderrDone = DispatchSemaphore(value: 0)

        outPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                stdoutDone.signal()
                return
            }
            lock.lock()
            stdoutLineBuffer.append(data)
            while let nlIdx = stdoutLineBuffer.firstIndex(of: 0x0A) {
                let startIdx = stdoutLineBuffer.startIndex
                let line = String(
                    data: stdoutLineBuffer.subdata(in: startIdx..<nlIdx),
                    encoding: .utf8
                ) ?? ""
                stdoutLineBuffer.removeSubrange(startIdx...nlIdx)
                if let percent = Self.parseProgressLine(line) {
                    clientProxy?.downloadProgress(percent)
                } else if !line.isEmpty {
                    nonProgressStdout.append(Data(line.utf8))
                    nonProgressStdout.append(0x0A)
                }
            }
            lock.unlock()
        }

        errPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if data.isEmpty {
                handle.readabilityHandler = nil
                stderrDone.signal()
                return
            }
            lock.lock()
            stderrData.append(data)
            lock.unlock()
        }

        process.terminationHandler = { proc in
            stdoutDone.wait()
            stderrDone.wait()

            if proc.terminationStatus != 0 {
                let errMsg = String(data: stderrData, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                reply(nil, errMsg.isEmpty ? "Download fehlgeschlagen" : errMsg)
                return
            }

            let filepath = String(data: nonProgressStdout, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

            if filepath.isEmpty {
                reply(nil, "Dateipfad nicht ermittelt")
            } else {
                reply(filepath, nil)
            }
        }

        do {
            try process.run()
        } catch {
            outPipe.fileHandleForReading.readabilityHandler = nil
            errPipe.fileHandleForReading.readabilityHandler = nil
            reply(nil, error.localizedDescription)
        }
    }

    private static func parseProgressLine(_ line: String) -> Double? {
        let prefix = "[XVL]"
        guard line.hasPrefix(prefix) else { return nil }
        let cleaned = line.dropFirst(prefix.count)
            .replacingOccurrences(of: "%", with: "")
            .trimmingCharacters(in: .whitespaces)
        return Double(cleaned)
    }
}

// XPC Listener starten
class Delegate: NSObject, NSXPCListenerDelegate {

    func listener(_ listener: NSXPCListener,
                  shouldAcceptNewConnection connection: NSXPCConnection) -> Bool {
        connection.exportedInterface = NSXPCInterface(with: HomebrewHelperProtocol.self)
        connection.exportedObject = HomebrewHelper()
        connection.remoteObjectInterface = NSXPCInterface(with: HomebrewHelperClientProtocol.self)
        connection.resume()
        return true
    }
}
