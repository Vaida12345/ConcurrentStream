
import Foundation
@testable import ConcurrentStream
import CryptoKit
import Synchronization

#if canImport(Testing)
import Testing

@Suite("Stacked Cancelation (Flat)", .tags(.cancelation, .mapping))
struct StackedCancellationTests {
    
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
            }.flatMap { [$0] }
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
            }.flatMap { [$0] }
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
            }.flatMap { [$0] }
            
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
    
    @available(macOS 15.0, *)
    @Test(.tags(.cancelationByParentTask, .explicitCancel))
    func manualCancelationByParentTask() async throws {
        let counter = Atomic<Int>(0)
        
        nonisolated(unsafe)
        var stream: (any ConcurrentStream<Void, Never>)? = nil
        
        let task = Task.detached {
            await withTaskCancellationHandler {
                stream = await (1...100).stream.map { _ in
                    heavyJob()
                    counter.add(1, ordering: .sequentiallyConsistent)
                }.flatMap { [$0] }
                
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
        try #require(currentCounter < 99 - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= 100)
        let _ = stream // ensure stream lives the entire duration.
    }
    
    @available(macOS 15.0, *)
    @Test(.tags(.cancelationInNext))
    func cancelInNext() async throws {
        let counter = Atomic<Int>(0)
        let nextCounter = Atomic<Int>(0)
        let task = Task.detached {
            let stream = await (1...100).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }.flatMap { [$0] }
            
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
        try #require(currentCounter < 99 - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        try #require(currentNextCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        try #require(nextCounter.load(ordering: .sequentiallyConsistent) <= currentNextCounter + 10)
        #expect(counter.load(ordering: .sequentiallyConsistent) <= 100)
    }
    
    @available(macOS 15.0, *)
    @Test(.tags(.explicitCancel))
    func explicitCancellation() async throws {
        let counter = Atomic<Int>(0)
        let stream = await (1...100).stream.map { _ in
            heavyJob()
            counter.add(1, ordering: .sequentiallyConsistent)
        }
        stream.cancel()
        
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= 10)
    }
    
    @available(macOS 15.0, *)
    @Test(.tags(.cancelationByError))
    func cancelationByError() async throws {
        let counter = Atomic<Int>(0)
        let stream = await (1...100).stream.map { _ in
            heavyJob()
            counter.add(1, ordering: .sequentiallyConsistent)
            throw TestError.example // after add, or would never run
        }.flatMap { [$0] }
        
        await #expect(throws: TestError.example) {
            try await confirmation(expectedCount: 0) { confirmation in
                func next() async throws -> Bool {
                    let next: ()? = try await stream.next()
                    return true
                }
                
                while try await next() { // should never return, should always throw
                    confirmation()
                }
            }
        }
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter < 99 - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= 100)
    }
    
    @available(macOS 15.0, *)
    @Test(.tags(.cancelationByError))
    func cancelationByChildError() async throws {
        let counter = Atomic<Int>(0)
        let stream = await (1...100).stream.map { _ in
            heavyJob()
            counter.add(1, ordering: .sequentiallyConsistent)
        }.flatMap { Void -> Array<Void> in [Void]; throw TestError.example }
        
        await #expect(throws: TestError.example) {
            try await confirmation(expectedCount: 0) { confirmation in
                func next() async throws -> Bool {
                    let next: ()? = try await stream.next()
                    return true
                }
                
                while try await next() { // should never return, should always throw
                    confirmation()
                }
            }
        }
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter < 99 - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= 100)
    }
    
    @available(macOS 15.0, *)
    @Test("Cancel by bridge to Sequence", .tags(.cancelationByBridge))
    func cancelationBySequence() async throws {
        let counter = Atomic<Int>(0)
        let task = Task.detached {
            let stream = await (1...100).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }.flatMap { [$0] }
            
            let _ = try? await stream.sequence
        }
        
        while counter.load(ordering: .sequentiallyConsistent) == 0 {
            heavyJob()
        }
        task.cancel()
        
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        try #require(currentCounter < 99 - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= 100)
    }
    
    @available(macOS 15.0, *)
    @Test("Cancel by bridge to Async", .tags(.cancelationByBridge))
    func cancelationByAsync() async throws {
        let counter = Atomic<Int>(0)
        let stream = await (1...100).stream.map { _ in
            heavyJob()
            counter.add(1, ordering: .sequentiallyConsistent)
        }.flatMap { [$0] }
        
        let async = stream.async
        
        while counter.load(ordering: .sequentiallyConsistent) == 0 {
            heavyJob()
        }
        async.cancel()
        
        let currentCounter = counter.load(ordering: .sequentiallyConsistent)
        try #require(currentCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
        try #require(currentCounter < 99 - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= 100)
    }
    
    @available(macOS 15.0, *)
    @Test("Cancel by bridge to ForEach", .tags(.cancelationByBridge))
    func cancelationByForEach() async throws {
        let counter = Atomic<Int>(0)
        let forEachCounter = Atomic<Int>(0)
        
        let task = Task.detached {
            let stream = await (1...100).stream.map { _ in
                heavyJob()
                counter.add(1, ordering: .sequentiallyConsistent)
            }.flatMap { [$0] }
            
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
        try #require(currentCounter < 99 - acceptableDistance, "The test has been rendered meaningless, please adjust parameters.")
        
        try! await Task.sleep(for: sleepDuration) //ensures stream is completed when task cancelation is faulty.
        
        try #require(currentForEachCounter <= counter.load(ordering: .sequentiallyConsistent) + 10)
        #expect(counter.load(ordering: .sequentiallyConsistent) <= 100)
    }
    
    @available(macOS 15.0, *)
    @Test("Cancel by bridge to ForEach Error", .tags(.cancelationByBridge, .cancelationByError))
    func cancelationByForEachError() async throws {
        let counter = Atomic<Int>(0)
        let forEachCounter = Atomic<Int>(0)
        
        let stream = await (1...100).stream.map { _ in
            heavyJob()
            counter.add(1, ordering: .sequentiallyConsistent)
        }.flatMap { [$0] }
        
        try await stream.forEach { _, _ in
            forEachCounter.add(1, ordering: .sequentiallyConsistent)
            throw TestError.example // throw after forEach
        }
        
        #expect(counter.load(ordering: .sequentiallyConsistent) <= acceptableDistance)
        #expect(forEachCounter.load(ordering: .sequentiallyConsistent) <= acceptableDistance)
    }
    
    @Test(.timeLimit(.minutes(1)))
    func useAfterCancel() async {
        let stream = await (1...100).stream.map { $0 }.flatMap { [$0] }
        stream.cancel()
        
        var counter = 0
        while let _ = await stream.next() {
            counter += 1
        }
        #expect(counter <= acceptableDistance)
    }
    
}
#endif
