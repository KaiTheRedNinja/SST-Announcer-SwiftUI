//
//  FileManager.swift
//  Announcer
//
//  Created by Kai Quan Tay on 11/1/23.
//

import Foundation

func read<T: Decodable>(_ type: T.Type, from file: String) -> T? {
    let filename = getDocumentsDirectory().appendingPathComponent(file)
    if let data = try? Data(contentsOf: filename) {
        if let values = try? JSONDecoder().decode(T.self, from: data) {
            Log.info("Data from \(file) found! \(values)")
            return values
        }
    }

    Log.info("Values not found :(")
    return nil
}

func write<T: Encodable>(_ value: T, to file: String, error onError: @escaping (Error) -> Void = { _ in }) {
    var encoded: Data

    do {
        encoded = try JSONEncoder().encode(value)
    } catch {
        onError(error)
        return
    }

    let filename = getDocumentsDirectory().appendingPathComponent(file)
    do {
        try encoded.write(to: filename)
        Log.info("Successfully wrote \(encoded) (from \(value)) to \(filename.description)")
        return
    } catch {
        // failed to write file – bad permissions, bad filename,
        // missing permissions, or more likely it can't be converted to the encoding
        Log.info("Failed to write to file!")
        onError(error)
    }
}
