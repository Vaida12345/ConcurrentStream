
import Foundation
@testable import ConcurrentStream
import CryptoKit
import Synchronization

#if canImport(Testing)
import Testing

/// The new tests are forgiving on the test results, the counter could be off by over 50. However, the test results should be accurate, as enough sleep time was given.
@Suite("Normal Cancelation Tests", .tags(.cancelation))
struct NormalCancellationTests {
    
    // The stream is deallocated when the task is cancelled, hence the life time of the closure ended, calling cancelation in deinit.
    @available(macOS 15.0, *)
    @Test(.tags(.cancelationByReleasingReference))
    func deinitCancel() async throws {
        let counter = Atomic<Int>(0)
        let task = Task.detached {
            let stream = await (1...upperBound).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }
            try? await Task.sleep(for: .seconds(10)) //ensures stream is not deallocated at once.
            let _ = stream
        }
        
        while counter.load(ordering: .sequentiallyConsistent) == 0 {
            heavyJob()
        }
        
        task.cancel() // on cancel, would cause the sleep to return, hence task is returned, stream is released.
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        try #require(currentCounter < upperBound - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= upperBound - acceptableDistance)
    }
    
    // stream is released at once, should be blocked before the first child task was even created.
    @available(macOS 15.0, *)
    @Test(.tags(.cancelationByReleasingReference))
    func releaseAtOnce() async throws {
        let counter = Atomic<Int>(0)
        Task.detached {
            let stream = await (1...upperBound).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }
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
            let stream = await (1...upperBound).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }
            
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
        try #require(currentCounter < upperBound - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= upperBound - acceptableDistance)
    }
    
    @available(macOS 15.0, *)
    @Test(.tags(.cancelationByParentTask), .disabled("This is currently impossible, the stream cannot observe the state of the Task while being non-blocking"))
    func cancelationByParentTask() async throws {
        let counter = Atomic<Int>(0)
        
        nonisolated(unsafe)
        var stream: (any ConcurrentStream<Void, Never>)? = nil
        
        Task.detached {
            stream = await (1...upperBound).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }
            
            // On cancelation, this task will just return.
            try? await Task.sleep(for: .seconds(10))
            
            // the stream lives outside, and should not be deallocated due to release of reference.
        }
        
        while counter.load(ordering: .sequentiallyConsistent) == 0 {
            heavyJob()
        }
        
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        try #require(currentCounter < upperBound - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= upperBound - acceptableDistance)
        let _ = stream // ensure stream lives the entire duration.
    }
    
    @available(macOS 15.0, *)
    @Test(.tags(.cancelationByParentTask, .explicitCancel))
    func manualCancelationByParentTask() async throws {
        let counter = Atomic<Int>(0)
        
        nonisolated(unsafe)
        var stream: (any ConcurrentStream<Void, Never>)? = nil
        
        let task = Task.detached {
            await withTaskCancellationHandler {
                stream = await (1...upperBound).stream.map { _ in
                    heavyJob()
                    counter.add(1, ordering: .sequentiallyConsistent)
                }
                
                // On cancelation, this task will just return.
                try? await Task.sleep(for: .seconds(10))
            } onCancel: {
                stream?.cancel()
            }
            
            
            // the stream lives outside, and should not be deallocated due to release of reference.
        }
        
        while counter.load(ordering: .sequentiallyConsistent) == 0 {
            heavyJob()
        }
        
        task.cancel()
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        try #require(currentCounter < upperBound - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= upperBound - acceptableDistance)
        let _ = stream // ensure stream lives the entire duration.
    }
    
    @available(macOS 15.0, *)
    @Test(.tags(.cancelationInNext))
    func cancelInNext() async throws {
        let counter = Atomic<Int>(0)
        let nextCounter = Atomic<Int>(0)
        let task = Task.detached {
            let stream = await (1...upperBound).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }
            
            while let _ = await stream.next() {
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
        try #require(currentCounter < upperBound - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        try #require(currentNextCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        try #require(nextCounter.load(ordering: .sequentiallyConsistent) <= currentNextCounter + 10)
        #expect(counter.load(ordering: .sequentiallyConsistent) <= upperBound - acceptableDistance)
    }
    
    @available(macOS 15.0, *)
    @Test(.tags(.explicitCancel))
    func explicitCancellation() async throws {
        let counter = Atomic<Int>(0)
        let stream = await (1...upperBound).stream.map { _ in
            heavyJob()
            counter.add(1, ordering: .sequentiallyConsistent)
        }
        stream.cancel()
        
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= upperBound - acceptableDistance)
    }
    
    @available(macOS 15.0, *)
    @Test(.tags(.cancelationByError))
    func cancelationByError() async throws {
        let counter = Atomic<Int>(0)
        let stream = await (1...upperBound).stream.map { _ in
            heavyJob()
            counter.add(1, ordering: .sequentiallyConsistent)
            throw TestError.example // after add, or would never run
        }
        
        await #expect(throws: TestError.example) {
            try await confirmation(expectedCount: 0) { confirmation in
                func next() async throws -> Bool {
                    try await stream.next()
                    return true
                }
                
                while try await next() { // should never return, should always throw
                    confirmation()
                }
            }
        }
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter < upperBound - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= upperBound - acceptableDistance)
    }
    
    @available(macOS 15.0, *)
    @Test("Cancel by bridge to Sequence", .tags(.cancelationByBridge))
    func cancelationBySequence() async throws {
        let counter = Atomic<Int>(0)
        let task = Task.detached {
            let stream = await (1...upperBound).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }
            
            let _ = try? await stream.sequence
        }
        
        while counter.load(ordering: .sequentiallyConsistent) == 0 {
            heavyJob()
        }
        task.cancel()
        
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        try #require(currentCounter < upperBound - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= upperBound - acceptableDistance)
    }
    
    @available(macOS 15.0, *)
    @Test("Cancel by bridge to Async", .tags(.cancelationByBridge))
    func cancelationByAsync() async throws {
        let counter = Atomic<Int>(0)
        let stream = await (1...upperBound).stream.map { _ in
            heavyJob()
            counter.add(1, ordering: .sequentiallyConsistent)
        }
        
        let async = stream.async
        
        while counter.load(ordering: .sequentiallyConsistent) == 0 {
            heavyJob()
        }
        async.cancel()
        
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        try #require(currentCounter < upperBound - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= upperBound - acceptableDistance)
    }
    
    @available(macOS 15.0, *)
    @Test("Cancel by bridge to ForEach", .tags(.cancelationByBridge))
    func cancelationByForEach() async throws {
        let counter = Atomic<Int>(0)
        let forEachCounter = Atomic<Int>(0)
        
        let task = Task.detached {
            let stream = await (1...upperBound).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }
            
            try await stream.forEach { _, _ in
                forEachCounter.add(1, ordering: .sequentiallyConsistent)
            }
        }
        
        while counter.load(ordering: .sequentiallyConsistent) == 0 || forEachCounter.load(ordering: .sequentiallyConsistent) == 0 {
            heavyJob()
        }
        task.cancel()
        
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        let currentForEachCounter = forEachCounter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        try #require(currentCounter < upperBound - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        try #require(currentForEachCounter <= counter.load(ordering: .sequentiallyConsistent) + 10)
        #expect(counter.load(ordering: .sequentiallyConsistent) <= upperBound - acceptableDistance)
    }
    
    @available(macOS 15.0, *)
    @Test("Cancel by bridge to ForEach Error", .tags(.cancelationByBridge, .cancelationByError))
    func cancelationByForEachError() async throws {
        let counter = Atomic<Int>(0)
        let forEachCounter = Atomic<Int>(0)
        
        let stream = await (1...upperBound).stream.map { _ in
            heavyJob()
            counter.add(1, ordering: .sequentiallyConsistent)
        }
        
        try? await stream.forEach { _, _ in
            forEachCounter.add(1, ordering: .sequentiallyConsistent)
            throw TestError.example // throw after forEach
        }
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= upperBound - acceptableDistance)
        #expect(forEachCounter.load(ordering: .sequentiallyConsistent) <= acceptableDistance)
    }
    
    @Test(.timeLimit(.minutes(1)))
    func useAfterCancel() async {
        let stream = await (1...upperBound).stream.map { $0 }
        stream.cancel()
        
        var counter = 0
        while let _ = await stream.next() {
            counter += 1
        }
        #expect(counter <= upperBound - acceptableDistance)
    }
    
}

/// Ensures that the testing is valid
@Test
@available(macOS 15.0, *)
func assertSufficiantHeavy() async throws {
    let counter = Atomic<Int>(0)
    let stream = await (1...upperBound).stream.map { _ in
        heavyJob()
        counter.add(1, ordering: .sequentiallyConsistent)
    }
    
    try await Task.sleep(for: sleepDuration)
    try #require(counter.load(ordering: .sequentiallyConsistent) == upperBound, "The tests are invalid")
    
    let _ = stream
}

/// Some real job that takes CPU.
///
/// Must be sufficiently large to avoid the task being completed before it could be cancelled.
internal func heavyJob() {
    for _ in 1...10 {
        var coder = SHA512()
        var id = UUID()
        withUnsafeBytes(of: &id) { buffer in
            coder.update(data: buffer)
        }
        let _ = coder.finalize()
    }
}

internal let sleepDuration = Duration(secondsComponent: 1, attosecondsComponent: 0)

internal let upperBound = 200

// Error is acceptable. The job may have been scheduled, and impossible to cancel in this Test
let acceptableDistance = 50

#endif
