
import Foundation
@testable import ConcurrentStream
import CryptoKit
import Synchronization

#if canImport(Testing)
import Testing

@Suite("Cancelation Tests", .tags(.cancelation))
struct CancellationTests {
    
    // The stream is deallocated when the task is cancelled, hence the life time of the closure ended, calling cancelation in deinit.
    @available(macOS 15.0, *)
    @Test
    func deinitCancel() async throws {
        let counter = Atomic<Int>(0)
        let task = Task.detached {
            let stream = await (1...100).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }
            try? await Task.sleep(for: .seconds(5)) //ensures stream is not deallocated at once.
        }
        
        heavyJob()
        heavyJob() // call it twice to ensure stream actually runs.
        
        task.cancel()
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        
        try! await Task.sleep(for: .seconds(2)) //ensures stream is completed when task cancelation is faulty.
        
        #expect(currentCounter == counter.load(ordering: .sequentiallyConsistent))
    }
    
    // stream is released at once, should be blocked before the first child task was even created.
    @available(macOS 15.0, *)
    @Test
    func releaseAtOnce() async throws {
        let counter = Atomic<Int>(0)
        let task = Task.detached {
            let stream = await (1...100).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }
        }
        
        heavyJob()
        heavyJob() // call it twice to ensure stream actually runs.
        
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        
        try! await Task.sleep(for: .seconds(2)) //ensures stream is completed when task cancelation is faulty.
        
        #expect(currentCounter == counter.load(ordering: .sequentiallyConsistent))
    }
    
    @available(macOS 15.0, *)
    @Test
    func releaseLater() async throws {
        let counter = Atomic<Int>(0)
        let task = Task.detached {
            let stream = await (1...100).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }
            
            heavyJob()
            heavyJob() //ensures stream is not deallocated at once.
        }
        
        heavyJob()
        heavyJob() // call it twice to ensure stream actually runs.
        
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        
        try! await Task.sleep(for: .seconds(2)) //ensures stream is completed when task cancelation is faulty.
        
        #expect(currentCounter == counter.load(ordering: .sequentiallyConsistent))
    }
    
    @available(macOS 15.0, *)
    @Test
    func cancelInNext() async throws {
        let counter = Atomic<Int>(0)
        let nextCounter = Atomic<Int>(0)
        let task = Task.detached {
            let stream = await (1...100).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }
            
            while let next = await stream.next() {
                nextCounter.add(1, ordering: .sequentiallyConsistent)
            }
        }
        
        // ensure it actually runs.
        while counter.load(ordering: .sequentiallyConsistent) == 0 || nextCounter.load(ordering: .sequentiallyConsistent) == 0 {
            heavyJob()
        }
        
        task.cancel()
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        let currentNextCounter = nextCounter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        try #require(currentNextCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        
        try! await Task.sleep(for: .seconds(2)) //ensures stream is completed when task cancelation is faulty.
        
        try #require(currentNextCounter == nextCounter.load(ordering: .sequentiallyConsistent))
        #expect(currentCounter == counter.load(ordering: .sequentiallyConsistent))
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
