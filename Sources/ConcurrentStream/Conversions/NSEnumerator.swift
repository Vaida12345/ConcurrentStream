//
//  ConcurrentNSEnumeratorStream.swift
//  The Concurrent Stream Module
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


import Foundation


private final class ConcurrentNSEnumeratorStream<Element>: ConcurrentStream {
    
    private var iterator: NSEnumerator
    
    
    fileprivate func next() async -> Element? {
        self.iterator.nextObject() as? Element
    }
    
    nonisolated var cancel: @Sendable () -> Void {
        // do nothing
        return {}
    }
    
    
    fileprivate init(iterator: consuming NSEnumerator) {
        self.iterator = iterator
    }
    
    typealias Failure = Never
    
}


extension NSEnumerator {
    
    /// Creates a stream from an async sequence.
    ///
    /// - Important: This function would consume and deplete the enumerator.
    ///
    /// - Complexity: O(*1*).
    public consuming func stream<Element>(of type: Element.Type) -> some ConcurrentStream<Element, Never> {
        ConcurrentNSEnumeratorStream(iterator: self)
    }
    
}

