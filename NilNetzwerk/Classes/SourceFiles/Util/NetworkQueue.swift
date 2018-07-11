import Foundation

public struct Queue<T> {
  private var array = [T?]()
  private var head = 0

  public var isEmpty: Bool {
    return count == 0
  }

  public var count: Int {
    return array.count - head
  }

  public func getAllData() -> [T?] {
    return array
  }

  public var front: T? {
    if isEmpty {
      return nil
    } else {
      return array[head]
    }
  }

  public mutating func enqueue(_ element: T) {
    array.append(element)
  }

  public mutating func dequeue() -> T? {
    guard head < array.count, let element = array[head] else { return nil }

    array[head] = nil
    head += 1

    removeUnusedEmptySpace()

    return element
  }

  // Using this instead of removeFirst to improve performance O(1) instead of O(n)
  private mutating func removeUnusedEmptySpace () {
    let percentage = Double(head)/Double(array.count)
    if array.count > 50 && percentage > 0.25 {
      array.removeFirst(head)
      head = 0
    }
  }
}
