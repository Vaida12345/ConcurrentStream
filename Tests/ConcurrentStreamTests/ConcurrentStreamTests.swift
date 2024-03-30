import XCTest
@testable import ConcurrentStream
import CryptoKit

final class ConcurrentStreamTests: XCTestCase {
    
//    func testSequence() async throws {
//        let sequence = [Int](0...100).shuffled()
//        let stream = try await sequence.stream.sequence
//        XCTAssertEqual(sequence, stream)
//    }
//    
//    func testIterator() async throws {
//        let task = Task {
//            let sequence = [Int](0...100).shuffled()
//            let date = Date()
//            let flatten = await sequence.stream.flatMap({
//                try await Task.sleep(for: .seconds(1))
//                return [Int](0...$0).shuffled().stream
//            })
//            print(date.distance(to: Date()))
//            try await flatten.forEach { element in
//                _ = element
//            }
//            print(date.distance(to: Date()))
//        }
//        task.cancel()
//    }
    
    func testCancel() async throws {
        let date = Date()
        let stream = await [Int](1...1000).stream.map(heavyWork)
        print(date.distance(to: Date()))
        
        let task = Task {
            let iterator = await ConcurrentStreamOrderedIterator(stream: stream)
            
            try await withTaskCancellationHandler {
                for _ in 0...1000 {
                    //                await Task.yield()
                    heavyWork(i: 0)
                }
                
                while let next = try await iterator.next() {
                    print(">>", next)
                }
            } onCancel: {
                iterator.cancel()
            }

        }
//        try await task.value
        try await Task.sleep(for: .seconds(0.0001))
        print("will ask to cancel")
        task.cancel()
        try await Task.sleep(for: .seconds(10))
    }
    
}


@Sendable
func heavyWork(i: Int) -> Int {
    var count = 0
    for _ in 0...10000 {
        count = max(count, SHA512.hash(data: Data(count: 4)).hashValue)
    }
    return i
}
