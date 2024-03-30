//
//  ConcurrentStream Conditional Order Iterator.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


private  final class ConcurrentStreamConditionalOrderIterator<Stream>: ConcurrentStreamIterator where Stream: ConcurrentStream {
    
    private var iterator: any ConcurrentStreamIterator<Element>
    
    
    fileprivate func next() async rethrows -> Element? {
        try await iterator.next()
    }
    
    fileprivate func cancel() {
        iterator.cancel()
    }
    
    
    fileprivate init(ordered: Bool, stream: Stream) async {
        self.iterator = await ordered ? ConcurrentStreamOrderedIterator(stream: stream) : ConcurrentStreamShuffledIterator(stream: stream)
    }
    
    
    fileprivate typealias Element = Stream.Element
    
}


public extension ConcurrentStream {
    
    func _makeDefaultIterator(ordered: Bool) async -> some ConcurrentStreamIterator<Element> {
        await ConcurrentStreamConditionalOrderIterator(ordered: ordered, stream: self)
    }
    
}
