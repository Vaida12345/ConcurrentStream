//
//  ConcurrentStream AsyncSequence Iterator.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


private final class ConcurrentStreamAsyncSequenceIterator<Iterator>: ConcurrentStreamIterator where Iterator: AsyncIteratorProtocol {
    
    private var iterator: Iterator
    
    
    fileprivate func next() async rethrows -> Element? {
        try await self.iterator.next()
    }
    
    fileprivate func cancel() {
        // does nothing
    }
    
    
    fileprivate init(iterator: Iterator) {
        self.iterator = iterator
    }
    
    
    fileprivate typealias Element = Iterator.Element
    
}


extension AsyncSequence {
    
    /// Creates a stream from an async sequence.
    ///
    /// - Complexity: O(*1*).
    public var stream: some ConcurrentStream<Element> {
        ConcurrentStreamSequence(iterator: ConcurrentStreamAsyncSequenceIterator(iterator: self.makeAsyncIterator()))
    }
    
}
