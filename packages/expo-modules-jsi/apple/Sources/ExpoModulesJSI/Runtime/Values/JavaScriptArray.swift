internal import jsi
internal import ExpoModulesJSI_Cxx

/**
 A Swift representation of a JavaScript array. `JavaScriptArray` provides a bridge between JavaScript arrays
 and Swift, allowing you to access and manipulate JavaScript array elements from Swift code. It maintains a reference
 to the underlying JavaScript array and provides Swift-friendly APIs for common array operations.
 */
public struct JavaScriptArray: JavaScriptType, ~Copyable {
  internal weak var runtime: JavaScriptRuntime?
  internal let pointee: facebook.jsi.Array

  internal init(_ runtime: JavaScriptRuntime, _ pointee: consuming facebook.jsi.Array) {
    self.runtime = runtime
    self.pointee = pointee
  }
  /**
   The number of elements in the JavaScript array.
   This property returns the length of the array, equivalent to accessing the `length`
   property in JavaScript. It represents the count of elements currently stored in the array.

   - Returns: The number of elements in the array as an `Int`
   - Note: This is equivalent to JavaScript's `array.length` property. In JavaScript,
     the length can be modified directly, but this Swift property is read-only.
   */
  public var size: Int {
    guard let runtime else {
      FatalError.runtimeLost()
    }
    return pointee.size(runtime.pointee)
  }
  /**
   Retrieves the value at the specified index in the array.

   - Parameter index: The zero-based index of the element to retrieve
   - Returns: The `JavaScriptValue` at the specified index
   - Throws: `JavaScriptArray.Errors.indexOutOfRange` if the index is negative or
     greater than or equal to the array's size
   */
  public func getValue(atIndex index: Int) throws -> JavaScriptValue {
    guard let runtime else {
      FatalError.runtimeLost()
    }
    guard (0..<size).contains(index) else {
      throw Errors.indexOutOfRange(index: index, size: size)
    }
    return JavaScriptValue(runtime, pointee.getValueAtIndex(runtime.pointee, index))
  }
  /**
   Accesses the value at the specified index in the array. Same as `getValue(atIndex:)`.
   */
  public subscript(index: Int) -> JavaScriptValue {
    get throws {
      return try self.getValue(atIndex: index)
    }
  }
  /**
   Transforms each element in the JavaScript array using the provided closure. This method creates a new Swift array
   by calling the transform closure on each element of the JavaScript array.
   The closure receives a `JavaScriptValue` for each element and returns a transformed value.

   - Parameter transform: A closure that accepts a `JavaScriptValue` representing an element
     from the array and returns a transformed value. The closure can throw an error, which
     will be propagated to the caller.
   - Returns: A Swift array containing the transformed elements in the same order as
     the original JavaScript array.
   - Throws: Any error thrown by the `transform` closure.
   - Note: This method uses Swift's standard `map` semantics and follows the `rethrows`
     pattern, meaning it only throws if the transform closure throws.
   */
  public func map<T>(_ transform: (_ value: JavaScriptValue) throws -> T) rethrows -> [T] {
    return try (0..<size).map { index in
      let value = try self.getValue(atIndex: index)
      return try transform(value)
    }
  }

  /**
   Converts the JavaScript array to a `JavaScriptValue`.

   - Returns: A `JavaScriptValue` representing this array
   - Note: The returned value maintains a reference to the same underlying JavaScript
     array, so modifications to the array in JavaScript will be reflected in the value.
   - SeeAlso: `JavaScriptValue.getArray()` for the inverse operation
   */
  public func asValue() -> JavaScriptValue {
    guard let runtime else {
      FatalError.runtimeLost()
    }
    return JavaScriptValue(runtime, expo.valueFromArray(runtime.pointee, pointee))
  }
  /**
   Errors that can occur when working with JavaScript arrays.
   */
  public enum Errors: Error, Equatable, CustomStringConvertible {
    /**
     The specified index is out of the array's valid range.

     - Parameters:
       - index: The invalid index that was accessed
       - size: The actual size of the array
     */
    case indexOutOfRange(index: Int, size: Int)

    public var description: String {
      switch self {
      case .indexOutOfRange(let index, let size):
        return "Index \(index) is out of range for array with size \(size). Valid range is 0..<\(size)."
      }
    }
  }
}
