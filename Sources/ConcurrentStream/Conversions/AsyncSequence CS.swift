//
//  AsyncSequence From ConcurrentStream.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


/// An async sequence made from a concurrent stream.
public struct AsyncSequenceFromConcurrentStream<Stream>: AsyncSequence where Stream: ConcurrentStream {
    
    private var iterator: Stream.Iterator
    
    
    public func makeAsyncIterator() -> Stream.Iterator {
        iterator
    }
    
    
    @usableFromInline
    internal init(stream: Stream) async {
        self.iterator = await stream.makeAsyncIterator(sorted: true)
    }
    
    
    public typealias Element = Stream.Element
    
}


extension ConcurrentStream {
    
    /// Converts the async stream to sequence.
    ///
    /// Unlike ``sequence``, the overhead is kept minimum, this operation involves only passing values, without the need for calculating anything.
    ///
    /// - Note: Work is dispatched on return.
    ///
    /// - Complexity: O(*1*).
    @inlinable
    public var async: AsyncSequenceFromConcurrentStream<Self> {
        get async {
            await AsyncSequenceFromConcurrentStream(stream: self)
        }
    }
    
}
