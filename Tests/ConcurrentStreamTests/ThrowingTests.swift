//
//  ThrowingTests.swift
//  
//
//  Created by Vaida on 6/13/24.
//

import Foundation
@testable import ConcurrentStream

#if canImport(Testing)
import Testing

@Suite("Concurrent Stream Throwing", .tags(.throwing), .serialized)
struct ConcurrentStreamThrowingTests {
    
    @Test
    func mapThrowing() async throws {
        let stream = await (1...100).stream.map { _ in
            throw TestError.example
        }
        await #expect(throws: TestError.example) {
            try await stream.next()
        }
    }
    
    @Test
    func compactThrowing() async throws {
        let stream = await (1...100).stream.compactMap { _ in
            throw TestError.example
        }
        await #expect(throws: TestError.example) {
            try await stream.next()
        }
    }
    
    @Suite(.tags(.throwingOverload))
    struct FilterThrows {
        let stream: any ConcurrentStream<Int, any Error>
        
        let nonThrowingStream: any ConcurrentStream<Int, Never>
        
        init() async {
            self.stream = await (0...100).stream.map { i in
                if i > 50 {
                    throw TestError.example // will never execute
                } else {
                    return i
                }
            }
            
            self.nonThrowingStream = await (0...100).stream.map { i in
                i
            }
        }
        
        @Test
        func _11() async throws {
            let stream = stream.filter{ _ in throw TestError.example }
            await #expect(throws: TestError.example) {
                try await stream.next()
            }
        }
        @Test
        func _10() async throws {
            let stream = stream.filter{ $0 % 2 == 0 }
            await #expect(throws: TestError.example) {
                while let _ = try await stream.next() {
                    
                }
            }
        }
        @Test
        func _01() async throws {
            let stream = nonThrowingStream.filter{ _ in throw TestError.example }
            await #expect(throws: TestError.example) {
                try await stream.next()
            }
        }
        @Test
        func _00() async throws {
            let stream = nonThrowingStream.filter{ _ in true }
            await #expect(throws: Never.self) {
                try await stream.next()
            }
        }
    }
    
    @Suite(.tags(.throwingOverload))
    struct FlattenConcurrentStreamThrows {
        let stream: any ConcurrentStream<Int, any Error>
        
        let nonThrowingStream: any ConcurrentStream<Int, Never>
        
        init() async {
            self.stream = await (0...100).stream.map { i in
                if i > 50 {
                    throw TestError.example // will never execute
                } else {
                    return i
                }
            }
            
            self.nonThrowingStream = await (0...100).stream.map { i in
                i
            }
        }
        
        @Test
        func _111() async throws {
            let stream = await stream.flatMap { throw TestError.example; return await ($0...200).stream.throwing() }
            await #expect(throws: TestError.example) {
                try await stream.next()
            }
        }
        @Test
        func _11() async throws {
            let stream = await stream.flatMap { throw TestError.example; return ($0...200).stream }
            await #expect(throws: TestError.example) {
                try await stream.next()
            }
        }
        @Test
        func _10() async throws {
            let stream = await stream.flatMap { ($0...200).stream }
            await #expect(throws: TestError.example) {
                while let _ = try await stream.next() {
                    
                }
            }
        }
        @Test
        func _01() async throws {
            let stream = await nonThrowingStream.flatMap { throw TestError.example; return ($0...200).stream }
            await #expect(throws: TestError.example) {
                try await stream.next()
            }
        }
        @Test
        func _00() async throws {
            let stream = await nonThrowingStream.flatMap { ($0...200).stream }
            await #expect(throws: Never.self) {
                try await stream.next()
            }
        }
    }
    
    @Suite(.tags(.throwingOverload))
    struct FlattenSequenceThrows {
        let stream: any ConcurrentStream<Int, any Error>
        
        let nonThrowingStream: any ConcurrentStream<Int, Never>
        
        init() async {
            self.stream = await (0...100).stream.map { i in
                if i > 50 {
                    throw TestError.example // will never execute
                } else {
                    return i
                }
            }
            
            self.nonThrowingStream = await (0...100).stream.map { i in
                i
            }
        }
        
        @Test
        func _11() async throws {
            let stream = await stream.flatMap { throw TestError.example; return ($0...200) }
            await #expect(throws: TestError.example) {
                try await stream.next()
            }
        }
        @Test
        func _10() async throws {
            let stream = await stream.flatMap { ($0...200) }
            await #expect(throws: TestError.example) {
                while let _ = try await stream.next() {
                    
                }
            }
        }
        @Test
        func _01() async throws {
            let stream = await nonThrowingStream.flatMap { throw TestError.example; return ($0...200) }
            await #expect(throws: TestError.example) {
                try await stream.next()
            }
        }
        @Test
        func _00() async throws {
            let stream = await nonThrowingStream.flatMap { ($0...200) }
            await #expect(throws: Never.self) {
                try await stream.next()
            }
        }
    }
    
}

#endif


private extension ConcurrentStream where Element: Sendable {
    
    func throwing() async -> some ConcurrentStream<Element, any Error> {
        await self.map { _ in
            throw TestError.example
        }
    }
    
}
