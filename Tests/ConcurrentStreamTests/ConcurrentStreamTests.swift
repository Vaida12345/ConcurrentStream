import XCTest
@testable import ConcurrentStream
import CryptoKit

final class ConcurrentStreamTests: XCTestCase {
    
    func testSequence() async throws {
        let sequence = [Int](0...100).shuffled()
        let stream = try await sequence.stream.sequence
        XCTAssertEqual(sequence, stream)
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
    
//    func testCancel() async throws {
//        
//        
//        let task = Task {
//            let date = Date()
//            let stream = await [Int](1...1000).stream.map(heavyWork).map({ $0 })
//            print(date.distance(to: Date()))
//            
//            try await withTaskCancellationHandler {
//                for _ in 0...10 {
//                    //                await Task.yield()
//                    heavyWork(i: 0)
//                }
//                
//                while let next = try await stream.next() {
//                    print(">>", next)
//                }
//            } onCancel: {
//                stream.cancel()
//            }
//
//        }
////        try await task.value
//        try await Task.sleep(for: .seconds(0.0001))
//        print("will ask to cancel")
////        task.cancel()
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
    for _ in 0...10000 {
        count = max(count, SHA512.hash(data: Data(count: 4)).hashValue)
    }
    return i
}
