
import Foundation
@testable import ConcurrentStream

#if canImport(Testing)
import Testing

internal extension Tag {
    
    @Tag static var conversion: Self
    
    @Tag static var mapping: Self
    
    @Tag static var lightweightOperations: Self
    
    @Tag static var operations: Self
    
    @Tag static var throwing: Self
    
    @Tag static var throwingOverload: Self
    
}

@Suite("Concurrent Stream")
struct ConcurrentStreamTests {
    
    @Test("Sequence", .tags(.conversion))
    func testSequence() async {
        let sequence = [Int](0...100).shuffled()
        let stream = try! await sequence.stream.sequence // FIXME: remove all try!
        #expect(sequence == stream)
    }
    
    @Test("AsyncSequence", .tags(.conversion, .mapping))
    @available(macOS 15, *)
    func testsResultingAsyncSequence() async {
        let sequence = [Int](0...100).shuffled()
        let async = await Task {
            try! await sequence.stream.map({ $0 }).async.allObjects
        }.value
        #expect(sequence == async)
    }
    
    @Test("AsyncSequence", .tags(.conversion))
    @available(macOS 15, *)
    func testsAsyncSequence() async {
        let sequence = [Int](0...100).shuffled()
        let async = try! await sequence.stream.async.stream.sequence
        #expect(sequence == async)
    }
    
    @Test("CompactMap", .tags(.mapping))
    func testCompactMap() async {
        let sequence = [Int](0...100).shuffled()
        let compactMap = try! await sequence.stream.compactMap({ $0 % 2 == 0 ? nil : $0 }).sequence
        let mapCompact = try! await sequence.stream.map({ $0 % 2 == 0 ? nil : $0 }).compacted().sequence
        let compactSequence = sequence.compactMap({ $0 % 2 == 0 ? nil : $0  })
        
        #expect(compactMap == mapCompact)
        #expect(compactMap == compactSequence)
    }
    
    @Test("Unique", .tags(.lightweightOperations))
    func testsUniqueSequence() async {
        let sequence = [Int](0...100).shuffled()
        let async = try! await sequence.stream.unique().sequence
        #expect(Set(sequence) == Set(async))
        
        let sequenceWithRepeat = [Int](0...100).shuffled() + [Int](0...100).shuffled()
        let asyncWithRepeat = try! await sequenceWithRepeat.stream.unique().sequence
        #expect(Set(sequenceWithRepeat) == Set(asyncWithRepeat))
    }
    
    @Test("FlatMap", .tags(.mapping))
    func testFlatMap() async {
        let sequence = [Int](0...100).shuffled()
        let stream = await sequence.stream.flatMap({ (0...$0).stream })
        #expect(try! await sequence.flatMap({ (0...$0) }) == stream.sequence)
        
        let stream2 = await sequence.stream.flatMap({ (0...$0) })
        #expect(try! await sequence.flatMap({ (0...$0) }) == stream2.sequence)
    }
    
    @Test("ForEach", .tags(.operations))
    func testForEach() async throws {
        let sequence = [Int](0...100).shuffled()
        nonisolated(unsafe)
        let buffer = UnsafeMutablePointer<Int>.allocate(capacity: sequence.count)
        try await sequence.stream.forEach { index, element in
            (buffer + index).initialize(to: element)
        }
        
        #expect(sequence == Array(UnsafeMutableBufferPointer(start: buffer, count: sequence.count)))
    }
    
    @Test("Stream Addition")
    func testSerialized() async {
        let sequence1 = [Int](0...100).shuffled()
        let sequence2 = [Int](0...100).shuffled()
        
        let stream = sequence1.stream + sequence2.stream
        let sequenceFromStream = try! await stream.sequence
        #expect(sequence1 + sequence2 == sequenceFromStream)
    }
    
    @Test("Compact", .tags(.lightweightOperations))
    func testCompact() async {
        let sequence = ([Int](1...100) + [Int?](repeating: nil, count: 100)).shuffled()
        
        let stream = try! await sequence.stream.map({ $0 }).compacted().sequence
        #expect(sequence.compactMap({ $0 }) == stream)
    }
    
    @Test("Filter", .tags(.lightweightOperations))
    func testFilters() async {
        let sequence = [Int](0...100).shuffled().filter({ $0.isMultiple(of: 2) })
        let stream = try! await sequence.stream.filter({ $0.isMultiple(of: 2) }).sequence
        #expect(sequence == stream)
    }
    
    @Test("NSEnumerator", .tags(.conversion))
    func testNSEnumerator() async {
        let sequence = [Int](0...100).shuffled()
        let enumerator = NSArray(array: sequence).objectEnumerator()
        let stream = NSArray(array: sequence).objectEnumerator().stream(of: Int.self)
        #expect(try! await (enumerator.allObjects as! [Int]) == stream.sequence)
    }
    
}

@available(macOS 15.0, *)
private extension AsyncSequence {
    
    var allObjects: [Element] {
        get async throws(Self.AsyncIterator.Failure) {
            var allObjects: [Element] = []
            var iterator = self.makeAsyncIterator()
            
            while let next = try await iterator.next(isolation: nil) {
                allObjects.append(next)
            }
            return allObjects
        }
    }
    
}
 

enum TestError: Error {
    case example
}
#endif
