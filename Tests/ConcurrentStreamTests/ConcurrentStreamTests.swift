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
    
    func testCompactMap() async throws {
        let sequence = [Int](0...100).shuffled()
        let compactMap = try await sequence.stream.compactMap({ $0 % 2 == 0 ? nil : $0 }).sequence
        let mapCompact = try await sequence.stream.map({ $0 % 2 == 0 ? nil : $0 }).compacted().sequence
        let compactSequence = sequence.compactMap({ $0 % 2 == 0 ? nil : $0  })
        
        XCTAssertEqual(compactMap, mapCompact)
        XCTAssertEqual(compactMap, compactSequence)
    }
    
    func testsUniqueSequence() async throws {
        let sequence = [Int](0...100).shuffled()
        let async = try await sequence.stream.unique().sequence
        XCTAssertEqual(Set(sequence), Set(async))
        
        let sequenceWithRepeat = [Int](0...100).shuffled() + [Int](0...100).shuffled()
        let asyncWithRepeat = try await sequenceWithRepeat.stream.unique().sequence
        XCTAssertEqual(Set(sequenceWithRepeat), Set(asyncWithRepeat))
    }
    
    func testFlatMap() async throws {
        let sequence = [Int](0...100).shuffled()
        let stream = try await sequence.stream.flatMap({ (0...$0).stream }).sequence
        XCTAssertEqual(sequence.flatMap({ (0...$0) }), stream)
        
        let stream2 = try await sequence.stream.flatMap({ (0...$0) }).sequence
        XCTAssertEqual(sequence.flatMap({ (0...$0) }), stream2)
    }
    
    func testForEach() async throws {
        let sequence = [Int](0...100).shuffled()
        let buffer = UnsafeMutablePointer<Int>.allocate(capacity: sequence.count)
        try await sequence.stream.forEach { index, element in
            (buffer + index).initialize(to: element)
        }
        
        XCTAssertEqual(sequence, Array(UnsafeMutableBufferPointer(start: buffer, count: sequence.count)))
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
    
    func testFilters() async throws {
        let sequence = [Int](0...100).shuffled().filter({ $0.isMultiple(of: 2) })
        let stream = try await sequence.stream.filter({ $0.isMultiple(of: 2) }).sequence
        XCTAssertEqual(sequence, stream)
    }
    
    func testNSEnumerator() async throws {
        let sequence = [Int](0...100).shuffled()
        let enumerator = NSArray(array: sequence).objectEnumerator()
        let stream = try await NSArray(array: sequence).objectEnumerator().stream(of: Int.self).sequence
        XCTAssertEqual((enumerator.allObjects as! [Int]), stream)
    }
    
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
