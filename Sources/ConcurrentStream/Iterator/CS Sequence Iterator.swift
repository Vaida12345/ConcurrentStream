//
//  ConcurrentStream Sequence Iterator.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


private struct ConcurrentStreamSequenceIterator<Iterator>: ConcurrentStreamIterator where Iterator: IteratorProtocol {
    
    private var iterator: Iterator
    
    var isRawIterator: Bool { true }
    
    
    fileprivate mutating func next() async -> Element? {
        self.iterator.next()
    }
    
    fileprivate func cancel() {
        // does nothing
    }
    
    
    fileprivate init(iterator: Iterator) {
        self.iterator = iterator
    }
    
    
    fileprivate typealias Element = Iterator.Element
    
}


extension Sequence {
    
    /// Creates a stream from an async sequence.
    ///
    /// - Complexity: O(*1*).
    public var stream: some ConcurrentStream<Element> {
        ConcurrentStreamSequence(iterator: ConcurrentStreamSequenceIterator(iterator: self.makeIterator()))
    }
    
}
