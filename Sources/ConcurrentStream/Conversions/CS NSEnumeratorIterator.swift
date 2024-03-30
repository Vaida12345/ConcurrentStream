//
//  ConcurrentStream NSEnumerator Iterator.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


import Foundation


private  final class ConcurrentStreamNSEnumeratorIterator<Element>: ConcurrentStreamIterator {
    
    private var iterator: NSEnumerator
    
    
    fileprivate func next() async -> Element? {
        self.iterator.nextObject() as? Element
    }
    
    fileprivate func cancel() {
        // does nothing
    }
    
    
    fileprivate init(iterator: NSEnumerator) {
        self.iterator = iterator
    }
    
}


extension NSEnumerator {
    
    /// Creates a stream from an async sequence.
    ///
    /// - Complexity: O(*1*).
    public func stream<Element>(of type: Element.Type) -> some ConcurrentStream<Element> {
        ConcurrentStreamSequence(iterator: ConcurrentStreamNSEnumeratorIterator(iterator: self))
    }
    
}
