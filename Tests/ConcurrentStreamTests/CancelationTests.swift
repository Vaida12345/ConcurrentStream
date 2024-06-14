
import Foundation
@testable import ConcurrentStream
import CryptoKit
import Synchronization

#if canImport(Testing)
import Testing

@Suite("Cancelation Tests", .tags(.cancelation))
struct CanceltaionTests {
    
    @available(macOS 15.0, *)
    func taskCancelation() async throws {
        let counter = Atomic<Int>(0)
        let task = Task.detached {
            let stream = await (1...100).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .relaxed)
            }
            try? await Task.sleep(for: .seconds(10)) //ensures stream is not deallocated at once.
        }
        
        heavyJob()
        heavyJob() // call it twice to ensure stream actually runs.
        
        task.cancel()
        try! await Task.sleep(for: .seconds(10)) //ensures stream is completed, even when task cancelation is faulty.
        
        try #require(counter.load(ordering: .acquiring) > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        #expect(counter.load(ordering: .acquiring) < 50)
    }
    
}

/// some real job that takes CPU.
private func heavyJob() {
    for _ in 1...100 {
        var coder = SHA512()
        var id = UUID()
        withUnsafeBytes(of: &id) { buffer in
            coder.update(data: buffer)
        }
        let _ = coder.finalize()
    }
}

#endif
