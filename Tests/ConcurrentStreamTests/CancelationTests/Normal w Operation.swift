
import Foundation
@testable import ConcurrentStream
import CryptoKit
import Synchronization

#if canImport(Testing)
import Testing

@Suite("Cancelation Tests With operations", .tags(.cancelation, .lightweightOperations))
struct CancelationTestsWithOperations {
    
    // The job may have been scheduled, and impossible to cancel in this Test
    let acceptableDistance = 15
    
    // The stream is deallocated when the task is cancelled, hence the life time of the closure ended, calling cancelation in deinit.
    @available(macOS 15.0, *)
    @Test(.tags(.cancelationByReleasingReference))
    func deinitCancel() async throws {
        let counter = Atomic<Int>(0)
        let task = Task.detached {
            let stream = await (1...100).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }.filter{ _ in true }
            try? await Task.sleep(for: .seconds(10)) //ensures stream is not deallocated at once.
            let _ = stream
        }
        
        while counter.load(ordering: .sequentiallyConsistent) == 0 {
            heavyJob()
        }
        
        task.cancel() // on cancel, would cause the sleep to return, hence task is returned, stream is released.
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        try #require(currentCounter < 99 - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= 100)
    }
    
    // stream is released at once, should be blocked before the first child task was even created.
    @available(macOS 15.0, *)
    @Test(.tags(.cancelationByReleasingReference))
    func releaseAtOnce() async throws {
        let counter = Atomic<Int>(0)
        Task.detached {
            let stream = await (1...100).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }.filter{ _ in false }
            let _ = stream
        }
        
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= 10)
    }
    
    @available(macOS 15.0, *)
    @Test(.tags(.cancelationByReleasingReference))
    func releaseLater() async throws {
        let counter = Atomic<Int>(0)
        Task.detached {
            let stream = await (1...100).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }.filter{ _ in false }
            
            while counter.load(ordering: .sequentiallyConsistent) == 0 {
                heavyJob()
            }
            
            let _ = stream
        }
        
        while counter.load(ordering: .sequentiallyConsistent) == 0 {
            heavyJob()
        }
        
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        try #require(currentCounter < 99 - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= 100)
    }
    
    
    @Test(.timeLimit(.minutes(1)))
    func useAfterCancel() async {
        let stream = await (1...100).stream.map { $0 }.filter{ _ in true }
        stream.cancel()
        
        var counter = 0
        while let _ = await stream.next() {
            counter += 1
        }
        #expect(counter <= acceptableDistance)
    }
    
}
#endif
