import XCTest
@testable import ConcurrentStream
import CryptoKit

final class ConcurrentStreamTests: XCTestCase {
    
    func testSequence() async throws {
        let sequence = [Int](0...100).shuffled()
        let stream = try await sequence.stream.sequence
        XCTAssertEqual(sequence, stream)
    }
    
    func testsResultingAsyncSequence() async throws {
        let sequence = [Int](0...100).shuffled()
        let async = try await Task {
            await sequence.stream.map({ $0 }).async
        }.value.allObjects
        XCTAssertEqual(sequence, async)
    }
    
    func testsAsyncSequence() async throws {
        let sequence = [Int](0...100).shuffled()
        let async = try await sequence.stream.async.stream.sequence
        XCTAssertEqual(sequence, async)
    }
    
    func testsUniqueSequence() async throws {
        let sequence = [Int](0...100).shuffled()
        let async = try await sequence.stream.unique().sequence
        XCTAssertEqual(Set(sequence), Set(async))
        
        let sequenceWithRepeat = [Int](0...100).shuffled() + [Int](0...100).shuffled()
        let asyncWithRepeat = try await sequenceWithRepeat.stream.unique().sequence
        XCTAssertEqual(Set(sequenceWithRepeat), Set(asyncWithRepeat))
    }
    
    func testCompactMap() async throws {
        let sequence = [Int](0...100).shuffled()
        let stream = try await sequence.stream.compactMap({ $0 % 2 == 0 ? nil : $0 }).sequence
        XCTAssertEqual(sequence.compactMap({ $0 % 2 == 0 ? nil : $0 }), stream)
    }
    
    func testFlatMap() async throws {
        let sequence = [Int](0...100).shuffled()
        let stream = try await sequence.stream.flatMap({ (0...$0).stream }).sequence
        XCTAssertEqual(sequence.flatMap({ (0...$0) }), stream)
    }
    
    func testForEach() async throws {
        let sequence = [Int](0...100).shuffled()
        let buffer = UnsafeMutableBufferPointer<Int>.allocate(capacity: sequence.count)
        try await sequence.stream.forEach { index, element in
            buffer[index] = element
        }
        XCTAssertEqual(sequence, Array(buffer))
    }
    
    func testSerialized() async throws {
        let sequence1 = [Int](0...100).shuffled()
        let sequence2 = [Int](0...100).shuffled()
        
        let stream = sequence1.stream + sequence2.stream
        let sequenceFromStream = try await stream.sequence
        XCTAssertEqual(sequence1 + sequence2, sequenceFromStream)
    }
    
    func testCompact() async throws {
        let sequence = ([Int](1...100) + [Int?](repeating: nil, count: 100)).shuffled()
        
        let stream = try await sequence.stream.map({ $0 }).compacted().sequence
        XCTAssertEqual(sequence.compactMap({ $0 }), stream)
    }
    
//    func testCancel() async throws {
//        
//        
//        let task = Task {
//            do {
//                let date = Date()
//                let stream = await [Int](1...1000).stream.map(heavyWork).map({ $0 }).async.map({ $0 })
//                print(date.distance(to: Date()))
//                
//                            for _ in 0...1000 {
//                                //                await Task.yield()
//                                heavyWork(i: 0)
//                            }
//                
//                for try await element in stream {
//                    print(">>", element)
//                }
//            } catch {
//                print(error)
//            }
//        }
////        try await task.value
//        try await Task.sleep(for: .seconds(0.001))
//        print("will ask to cancel")
//        task.cancel()
//        try await Task.sleep(for: .seconds(10))
//    }
    
//    func testPerformance() async throws {
//        let stream = { index in
//            try await (0...index).stream.forEach { index, element in
//                
//            }
//        }
//        
//        let taskGroup = { index  in
//            await withTaskGroup(of: Int.self) { taskGroup in
//                for i in 0...index {
//                    taskGroup.addTask {
//                        i
//                    }
//                }
//            }
//        }
//        
//        var streamResults: [Duration] = []
//        var taskGroupResults: [Duration] = []
//        streamResults.reserveCapacity(1000)
//        taskGroupResults.reserveCapacity(1000)
//        
//        for i in 0..<1000 {
//            try await streamResults.append(ContinuousClock().measure {
//                try await stream(i)
//            })
//            await taskGroupResults.append(ContinuousClock().measure {
//                await taskGroup(i)
//            })
//        }
//        
//        print(streamResults.reduce(Duration(secondsComponent: 0, attosecondsComponent: 0), +) / 1000)
//        print(taskGroupResults.reduce(Duration(secondsComponent: 0, attosecondsComponent: 0), +) / 1000)
//    }
    
}


@Sendable
func heavyWork(i: Int) -> Int {
    var count = 0
    for _ in 0...1000 {
        count = max(count, SHA512.hash(data: Data(count: 4)).hashValue)
    }
    return i
}


private extension AsyncSequence {
    
    var allObjects: [Element] {
        get async throws {
            var allObjects: [Element] = []
            var iterator = self.makeAsyncIterator()
            
            while let next = try await iterator.next() {
                allObjects.append(next)
            }
            return allObjects
        }
    }
    
}
