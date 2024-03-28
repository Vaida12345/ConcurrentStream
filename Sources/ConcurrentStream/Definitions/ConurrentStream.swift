//
//  ConcurrentStream.swift
//  The Stratum Module - Concurrent Stream
//
//  Created by Vaida on 6/1/23.
//  Copyright © 2019 - 2024 Vaida. All rights reserved.
//


// Documentation in DocC.
@rethrows
public protocol ConcurrentStream<Element> {
    
    func returns<T>(handler: (_ results: ResultSequence) async throws -> T) async rethrows -> T
    
    
    associatedtype Element: Sendable
    
    associatedtype ResultSequence: AsyncSequence where ResultSequence.Element.Type == (ConcurrentStreamIndex, Element).Type
    
    
}
