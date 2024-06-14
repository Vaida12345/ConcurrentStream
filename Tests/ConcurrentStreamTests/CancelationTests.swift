
import Foundation
@testable import ConcurrentStream
import CryptoKit
import Synchronization

#if canImport(Testing)
import Testing

@Suite("Cancelation Tests", .tags(.cancelation))
struct CancellationTests {
    
    @available(macOS 15.0, *)
    @Test
    func taskCancellation() async throws {
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
    
    // stream is released at once, should be blocked before the first child task was even created.
    @available(macOS 15.0, *)
    @Test
    func releaseAtOnce() async throws {
        let counter = Atomic<Int>(0)
        let task = Task.detached {
            let stream = await (1...100).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .relaxed)
            }
        }
        
        heavyJob()
        heavyJob() // call it twice to ensure stream actually runs.
        
        try! await Task.sleep(for: .seconds(10)) //ensures stream is completed, even when task cancelation is faulty.
        
        #expect(counter.load(ordering: .acquiring) == 0)
    }
    
    @available(macOS 15.0, *)
    @Test
    func releaseLater() async throws {
        let counter = Atomic<Int>(0)
        let task = Task.detached {
            let stream = await (1...100).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .relaxed)
            }
            
            heavyJob()
            heavyJob() //ensures stream is not deallocated at once.
        }
        
        heavyJob()
        heavyJob() // call it twice to ensure stream actually runs.
        
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
