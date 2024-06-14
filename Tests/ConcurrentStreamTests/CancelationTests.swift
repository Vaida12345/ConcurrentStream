
import Foundation
@testable import ConcurrentStream
import CryptoKit
import Synchronization

#if canImport(Testing)
import Testing

@Suite("Cancelation Tests", .tags(.cancelation))
struct CancellationTests {
    
    @Suite("Non Throwing")
    struct UnThrowingTests {
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
                }
                try? await Task.sleep(for: .seconds(5)) //ensures stream is not deallocated at once.
                let _ = stream
            }
            
            while counter.load(ordering: .sequentiallyConsistent) == 0 {
                heavyJob()
            }
            
            task.cancel() // on cancel, would cause the sleep to return, hence task is returned, stream is released.
            let currentCounter = counter.load(ordering: .sequentiallyConsistent)
            try #require(currentCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
            
            try! await Task.sleep(for: .seconds(2)) //ensures stream is completed when task cancelation is faulty.
            
            #expect(counter.load(ordering: .sequentiallyConsistent) <= acceptableDistance + currentCounter)
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
                }
                let _ = stream
            }
            
            
            try! await Task.sleep(for: .seconds(2)) //ensures stream is completed when task cancelation is faulty.
            
            #expect(counter.load(ordering: .sequentiallyConsistent) == 0)
        }
        
        @available(macOS 15.0, *)
        @Test(.tags(.cancelationByReleasingReference))
        func releaseLater() async throws {
            let counter = Atomic<Int>(0)
            Task.detached {
                let stream = await (1...100).stream.map { _ in
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
            
            try! await Task.sleep(for: .seconds(2)) //ensures stream is completed when task cancelation is faulty.
            
            #expect(counter.load(ordering: .sequentiallyConsistent) <= acceptableDistance + currentCounter)
        }
        
        @available(macOS 15.0, *)
        @Test(.tags(.cancelationByParentTask))
        func cancelationByParentTask() async throws {
            let counter = Atomic<Int>(0)
            
            nonisolated(unsafe)
            var stream: (any ConcurrentStream<Void, Never>)? = nil
            
            Task.detached {
                stream = await (1...100).stream.map { _ in
                    heavyJob()
                    counter.add(1, ordering: .sequentiallyConsistent)
                }
                
                // On cancelation, this task will just return.
                try? await Task.sleep(for: .seconds(2))
                
                // the stream lives outside, and should not be deallocated due to release of reference.
            }
            
            while counter.load(ordering: .sequentiallyConsistent) == 0 {
                heavyJob()
            }
            
            let currentCounter = counter.load(ordering: .sequentiallyConsistent)
            try #require(currentCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
            
            try! await Task.sleep(for: .seconds(2)) //ensures stream is completed when task cancelation is faulty.
            
            #expect(counter.load(ordering: .sequentiallyConsistent) <= acceptableDistance + currentCounter)
            let _ = stream // ensure stream lives the entire duration.
        }
        
        @available(macOS 15.0, *)
        @Test(.tags(.cancelatioInNext))
        func cancelInNext() async throws {
            let counter = Atomic<Int>(0)
            let nextCounter = Atomic<Int>(0)
            let task = Task.detached {
                let stream = await (1...100).stream.map { _ in
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
            try #require(currentNextCounter > 0, "The stream should have been executed for at least one time, please adjust conditions before calling task.cancel")
            
            try! await Task.sleep(for: .seconds(2)) //ensures stream is completed when task cancelation is faulty.
            
            try #require(nextCounter.load(ordering: .sequentiallyConsistent) <= currentNextCounter + 3)
            #expect(counter.load(ordering: .sequentiallyConsistent) <= acceptableDistance + currentCounter)
        }
        
        @Test(.timeLimit(.minutes(1)))
        func useAfterCancel() async {
            let stream = await (1...100).stream.map { $0 }
            stream.cancel()
            
            await confirmation(expectedCount: 0) { confirmation in
                while let _ = await stream.next() {
                    confirmation()
                }
            }
        }
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
