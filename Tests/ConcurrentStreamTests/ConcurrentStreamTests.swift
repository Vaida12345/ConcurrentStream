
import Foundation
@testable import ConcurrentStream

#if canImport(Testing)
import Testing

private extension Tag {
    
    @Tag static var conversion: Self
    
    @Tag static var mapping: Self
    
    @Tag static var lightweightOperations: Self
    
    @Tag static var operations: Self
    
}

@Suite("Concurrent Stream")
struct ConcurrentStreamTests {
    
    @Test("Sequence", .tags(.conversion))
    func testSequence() async throws {
        let sequence = [Int](0...100).shuffled()
        let stream = await sequence.stream.sequence
        #expect(sequence == stream)
    }
    
    @Test("AsyncSequence", .tags(.conversion, .mapping))
    @available(macOS 15, *)
    func testsResultingAsyncSequence() async throws {
        let sequence = [Int](0...100).shuffled()
        let async = try await Task {
            await sequence.stream.map({ $0 }).async
        }.value.allObjects
        #expect(sequence == async)
    }
    
    @Test("AsyncSequence", .tags(.conversion))
    @available(macOS 15, *)
    func testsAsyncSequence() async throws {
        let sequence = [Int](0...100).shuffled()
        let async = await sequence.stream.async.stream.sequence
        #expect(sequence == async)
    }
    
    @Test("CompactMap", .tags(.mapping))
    func testCompactMap() async throws {
        let sequence = [Int](0...100).shuffled()
        let compactMap = await sequence.stream.compactMap({ $0 % 2 == 0 ? nil : $0 }).sequence
        let mapCompact = await sequence.stream.map({ $0 % 2 == 0 ? nil : $0 }).compacted().sequence
        let compactSequence = sequence.compactMap({ $0 % 2 == 0 ? nil : $0  })
        
        #expect(compactMap == mapCompact)
        #expect(compactMap == compactSequence)
    }
    
    @Test("Unique", .tags(.lightweightOperations))
    func testsUniqueSequence() async throws {
        let sequence = [Int](0...100).shuffled()
        let async = await sequence.stream.unique().sequence
        #expect(Set(sequence) == Set(async))
        
        let sequenceWithRepeat = [Int](0...100).shuffled() + [Int](0...100).shuffled()
        let asyncWithRepeat = await sequenceWithRepeat.stream.unique().sequence
        #expect(Set(sequenceWithRepeat) == Set(asyncWithRepeat))
    }
    
    @Test("FlatMap", .tags(.mapping))
    func testFlatMap() async throws {
        let sequence = [Int](0...100).shuffled()
        let stream = try await sequence.stream.flatMap({ (0...$0).stream }).sequence
        #expect(sequence.flatMap({ (0...$0) }) == stream)
        
        let stream2 = try await sequence.stream.flatMap({ (0...$0) }).sequence
        #expect(sequence.flatMap({ (0...$0) }) == stream2)
    }
    
    @Test("ForEach", .tags(.operations))
    func testForEach() async throws {
        let sequence = [Int](0...100).shuffled()
        let buffer = UnsafeMutablePointer<Int>.allocate(capacity: sequence.count)
        try await sequence.stream.forEach { index, element in
            (buffer + index).initialize(to: element)
        }
        
        #expect(sequence == Array(UnsafeMutableBufferPointer(start: buffer, count: sequence.count)))
    }
    
    @Test("Stream Addition")
    func testSerialized() async throws {
        let sequence1 = [Int](0...100).shuffled()
        let sequence2 = [Int](0...100).shuffled()
        
        let stream = sequence1.stream + sequence2.stream
        let sequenceFromStream = try await stream.sequence
        #expect(sequence1 + sequence2 == sequenceFromStream)
    }
    
    @Test("Compact", .tags(.lightweightOperations))
    func testCompact() async throws {
        let sequence = ([Int](1...100) + [Int?](repeating: nil, count: 100)).shuffled()
        
        let stream = await sequence.stream.map({ $0 }).compacted().sequence
        #expect(sequence.compactMap({ $0 }) == stream)
    }
    
    @Test("Filter", .tags(.lightweightOperations))
    func testFilters() async throws {
        let sequence = [Int](0...100).shuffled().filter({ $0.isMultiple(of: 2) })
        let stream = try await sequence.stream.filter({ $0.isMultiple(of: 2) }).sequence
        #expect(sequence == stream)
    }
    
    @Test("NSEnumerator", .tags(.conversion))
    func testNSEnumerator() async throws {
        let sequence = [Int](0...100).shuffled()
        let enumerator = NSArray(array: sequence).objectEnumerator()
        let stream = await NSArray(array: sequence).objectEnumerator().stream(of: Int.self).sequence
        #expect((enumerator.allObjects as! [Int]) == stream)
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

enum TestError: Error {
    case example
}
#endif
