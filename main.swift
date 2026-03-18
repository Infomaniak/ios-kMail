import Foundation

let stream = AsyncStream { continuation in
    for i in 1...9 {
        continuation.yield(i)
    }

    continuation.finish()
}

Task {
    for await item in stream {
        print("1. \(item)")
    }
}

Task {
    for await item in stream {
        print("2. \(item)")
    }
}

Task {
    for await item in stream {
        print("3. \(item)")
    }
}

try? await Task.sleep(for: .seconds(1))
