
import Foundation
import ConcurrentStream

let date = Date()
let stream = await (0...1000000).stream.map { $0 }
let _ = await stream.sequence
print(date.distance(to: Date()))


let groupDate = Date()
await withTaskGroup(of: Int.self) { taskGroup in
    for i in 0..<1000000 {
        taskGroup.addTask {
            i
        }
    }
    
    var sequence: [Int] = []
    while let next = await taskGroup.next() {
        sequence.append(next)
    }
}
print(groupDate.distance(to: Date()))
