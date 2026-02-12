// Copyright 2025-present 650 Industries. All rights reserved.

internal import jsi
internal import ExpoModulesJSI_Cxx

public final class JavaScriptValue: JavaScriptType, Equatable, Escapable, Error {
  internal weak let runtime: JavaScriptRuntime?
  internal let pointee: facebook.jsi.Value

  /**
   Initializer from the existing JSI value.
   */
  internal init(_ runtime: JavaScriptRuntime?, _ pointee: consuming facebook.jsi.Value) {
    self.runtime = runtime
    self.pointee = pointee
  }

  /**
   Copy initializer from the existing JSI value.
   */
  internal init(_ runtime: JavaScriptRuntime, _ pointee: borrowing facebook.jsi.Value) {
    self.runtime = runtime
    self.pointee = facebook.jsi.Value(runtime.pointee, pointee)
  }

  /**
   Creates a boolean JS value.
   */
  public init(_ runtime: JavaScriptRuntime, _ bool: Bool) {
    self.runtime = runtime
    self.pointee = facebook.jsi.Value(bool)
  }

  /**
   Creates a JS value from a JS representable.
   */
  public init(_ runtime: JavaScriptRuntime, _ value: JSRepresentable) {
    self.runtime = runtime
    self.pointee = value.toJSValue(in: runtime).toJSIValue(in: runtime.pointee)
  }

  /**
   Creates a JS value from a JSI representable.
   */
  internal init(_ runtime: JavaScriptRuntime, _ value: JSIRepresentable) {
    self.runtime = runtime
    self.pointee = value.toJSIValue(in: runtime.pointee)
  }

  /**
   Copies the value.
   */
  public func copy() -> JavaScriptValue {
    if let runtime {
      return JavaScriptValue(runtime, facebook.jsi.Value(runtime.pointee, pointee))
    }
    // Some simple value kinds do not require the runtime.
    switch kind {
    case .undefined:
      return .undefined()
    case .null:
      return .null()
    case .bool:
      return .init(nil, facebook.jsi.Value(getBool()))
    case .number:
      return .init(nil, facebook.jsi.Value(getDouble()))
    default:
      FatalError.runtimeLost()
    }
  }

  public func isUndefined() -> Bool {
    return pointee.isUndefined()
  }

  public func isNull() -> Bool {
    return pointee.isNull()
  }

  public func isBool() -> Bool {
    return pointee.isBool()
  }

  public func isNumber() -> Bool {
    return pointee.isNumber()
  }

  public func isString() -> Bool {
    return pointee.isString()
  }

  public func isSymbol() -> Bool {
    return pointee.isSymbol()
  }

  public func isObject() -> Bool {
    return pointee.isObject()
  }

  public func isArray() -> Bool {
    guard let jsiRuntime = runtime?.pointee else {
      FatalError.runtimeLost()
    }
    return pointee.isObject() && pointee.getObject(jsiRuntime).isArray(jsiRuntime)
  }

  public func isFunction() -> Bool {
    guard let jsiRuntime = runtime?.pointee else {
      FatalError.runtimeLost()
    }
    return pointee.isObject() && pointee.getObject(jsiRuntime).isFunction(jsiRuntime)
  }

  public func isTypedArray() -> Bool {
    guard let jsiRuntime = runtime?.pointee else {
      FatalError.runtimeLost()
    }
    return pointee.isObject() && expo.isTypedArray(jsiRuntime, pointee.getObject(jsiRuntime))
  }

  /**
   Checks whether the value is an instance of a global class of the given name.
   For example `value.is("Promise")` checks whether the value is a promise.
   */
  public func `is`(_ typeName: String) -> Bool {
    guard let runtime else {
      FatalError.runtimeLost()
    }
    return isObject() && getObject().instanceOf(runtime.global().getPropertyAsFunction(typeName))
  }

  public func getAny() -> Any {
    if isUndefined() || isNull() {
      return Any?.none as Any
    }
    if isBool() {
      return getBool()
    }
    if isNumber() {
      return getDouble()
    }
    if isString() {
      return getString()
    }
    if let object = isObject() ? getObject() : nil {
      if let array = object.isArray() ? object.getArray() : nil {
        let size = array.size
        var result = [Any]()

        result.reserveCapacity(size)

        for index in 0..<size {
          result.append((try? array.getValue(atIndex: index).getAny()) as Any)
        }
        return result
      }
      if object.isFunction() {
        fatalError("Unimplemented")
      }
      var result = [String: Any]()

      for propertyName in object.getPropertyNames() {
        let property = object.getProperty(propertyName)
        result[propertyName] = property.getAny()
      }
      return result
    }
    fatalError("Unsupported value kind: \(kind)")
  }

  /**
   Returns the value as a boolean, or asserts if not a boolean.
   */
  public func getBool() -> Bool {
    assert(isBool(), "Value is not a boolean")
    return pointee.getBool()
  }

  /**
   Returns the value as an integer, or asserts if not a number.
   */
  public func getInt() -> Int {
    assert(isNumber(), "Value is not a number")
    return Int(pointee.getNumber())
  }

  /**
   Returns the value as a double, or asserts if not a number.
   */
  public func getDouble() -> Double {
    assert(isNumber(), "Value is not a number")
    return pointee.getNumber()
  }

  /**
   Returns the value as a string, or asserts if not a string.
   */
  public func getString() -> String {
    guard let jsiRuntime = runtime?.pointee else {
      FatalError.runtimeLost()
    }
    assert(isString(), "Value is not a string")
    return String(pointee.getString(jsiRuntime).utf16(jsiRuntime))
  }

  /**
   Returns the value as an object, or asserts if not an object.
   */
  public func getObject() -> JavaScriptObject {
    guard let runtime else {
      FatalError.runtimeLost()
    }
    assert(isObject(), "Value is not an object")
    return JavaScriptObject(runtime, pointee.getObject(runtime.pointee))
  }

  /**
   Returns the value as an array, or asserts if not an array.
   */
  public func getArray() -> JavaScriptArray {
    guard let runtime else {
      FatalError.runtimeLost()
    }
    assert(isArray(), "Value is not an array")
    return JavaScriptArray(runtime, pointee.getObject(runtime.pointee).getArray(runtime.pointee))
  }

  /**
   Returns the value as a function, or asserts if not a function.
   */
  public func getFunction() -> JavaScriptFunction {
    guard let runtime else {
      FatalError.runtimeLost()
    }
    assert(isFunction(), "Value is not a function")
    return JavaScriptFunction(runtime, pointee.getObject(runtime.pointee).getFunction(runtime.pointee))
  }

  /**
   Returns the value as a typed array, or asserts if it is not a typed array.
   */
  public func getTypedArray() -> JavaScriptTypedArray {
    guard let runtime else {
      FatalError.runtimeLost()
    }
    assert(isTypedArray(), "Value is not a typed array")
    return JavaScriptTypedArray(runtime, expo.TypedArray(runtime.pointee, pointee.getObject(runtime.pointee)))
  }

  /**
   Returns the value as a promise, or asserts if it is not a promise.
   */
  @JavaScriptActor
  public func getPromise() throws -> JavaScriptPromise {
    guard let runtime else {
      FatalError.runtimeLost()
    }
    assert(self.is("Promise"), "Value is not a promise")
    return JavaScriptPromise(runtime, getObject())
  }

  /**
   Returns a string representing the value. Same as calling `toString()` in JS.
   */
  public func toString() -> String {
    guard let jsiRuntime = runtime?.pointee else {
      FatalError.runtimeLost()
    }
    return String(pointee.toString(jsiRuntime).utf16(jsiRuntime))
  }

  /**
   Converts the JavaScript value to a JSON string representation.

   This method is equivalent to calling `JSON.stringify()` in JavaScript with this value
   as the first argument. It serializes the value into a JSON-formatted string, with
   optional control over the serialization process through the replacer and space parameters.

   - Parameters:
     - replacer: An optional function or array that alters the behavior of the stringification process.
       - If a function: Called for each property, receiving the key and value as arguments.
       - If an array: Only properties whose names are in the array will be included in the result.
       - If `nil`: All properties are included.
     - space: An optional string or number that controls the indentation and spacing in the output.
       - If a number: Indicates the number of spaces to use for indentation (clamped to 10).
       - If a string: Used as the indentation string (truncated to 10 characters).
       - If `nil`: No whitespace is added, resulting in compact output.

   - Returns: A JSON string representation of the value, or `nil` if the value cannot be
     serialized (e.g., functions, symbols, or undefined values in object properties).

   - Throws: An error if the serialization fails (e.g., circular references, or if a
     replacer function throws an error).

   ## Examples
   ```swift
   let runtime = JavaScriptRuntime()

   // Simple value
   let number = JavaScriptValue(runtime, 42)
   try number.jsonStringify() // "42"

   // Object with pretty printing
   let obj = runtime.eval("({ name: 'Alice', age: 30 })")
   try obj.jsonStringify(space: JavaScriptValue(runtime, 2))
   // Returns:
   // {
   //   "name": "Alice",
   //   "age": 30
   // }

   // Using a replacer to filter properties
   let replacer = runtime.eval("['name']") // Only include 'name' property
   try obj.jsonStringify(replacer: replacer) // {"name":"Alice"}

   // Undefined returns nil
   let undefined = JavaScriptValue.undefined()
   try undefined.jsonStringify() // nil
   ```

   - Note: For simple values (undefined, null, boolean, number) that don't have an associated
     runtime, this method can still produce a JSON representation without invoking JavaScript's
     `JSON.stringify()`.

   - SeeAlso: [MDN: JSON.stringify()](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/JSON/stringify)
   */
  public func jsonStringify(replacer: JavaScriptValue? = nil, space: JavaScriptValue? = nil) throws -> String? {
    guard let runtime else {
      // Some types do not need the runtime. Handle them before crashing due to missing runtime.
      switch kind {
      case .undefined:
        return nil
      case .null:
        return "null"
      case .bool:
        return getBool() ? "true" : "false"
      case .number:
        return String(getDouble())
      default:
        FatalError.runtimeLost()
      }
    }
    let value = try runtime
      .global()
      .getPropertyAsObject("JSON")
      .getPropertyAsFunction("stringify")
      .call(arguments: self, replacer, space)
    return value.isString() ? value.getString() : nil
  }

  // MARK: - JavaScriptType

  public func asValue() -> JavaScriptValue {
    // We need to copy the value as `self` would be borrowed
    return copy()
  }

  internal func asJSIValue() -> facebook.jsi.Value {
    if let runtime {
      return facebook.jsi.Value(runtime.pointee, pointee)
    }
    // Some simple value kinds do not require the runtime.
    switch kind {
    case .undefined:
      return facebook.jsi.Value.undefined()
    case .null:
      return facebook.jsi.Value.null()
    case .bool:
      return facebook.jsi.Value(getBool())
    case .number:
      return facebook.jsi.Value(getDouble())
    default:
      FatalError.runtimeLost()
    }
  }

  // MARK: - Kind

  public enum Kind: String {
    case undefined
    case null
    case bool
    case number
    case symbol
    case string
    case function
    case object
  }

  public var kind: Kind {
    // TODO: Make it a stored property, but computed on demand.
    // This feels like a better way to check value's type.
    switch true {
    case isUndefined():
      return .undefined
    case isNull():
      return .null
    case isBool():
      return .bool
    case isNumber():
      return .number
    case isSymbol():
      return .symbol
    case isString():
      return .string
    case isFunction():
      return .function
    default:
      return .object
    }
  }

  // MARK: - Equality

  /**
   Tests whether two values are strictly equal, according to https://262.ecma-international.org/11.0/#sec-strict-equality-comparison
   */
  public func isEqual(to another: JavaScriptValue) -> Bool {
    if let jsiRuntime = runtime?.pointee ?? another.runtime?.pointee {
      return facebook.jsi.Value.strictEquals(jsiRuntime, pointee, another.pointee)
    }
    // Some types don't have to be tied to any runtime. Since `strictEquals` needs a runtime, we need to handle this case ourselves.
    let thisKind = kind
    if thisKind != another.kind {
      return false
    }
    switch thisKind {
    case .undefined, .null:
      return true
    case .number:
      return getDouble() == another.getDouble()
    case .bool:
      return getBool() == another.getBool()
    default:
      return false
    }
  }

  /**
   Same as `isEqual(to:)`.
   */
  public static func == (lhs: JavaScriptValue, rhs: JavaScriptValue) -> Bool {
    return lhs.isEqual(to: rhs)
  }

  /**
   Negates the result of `isEqual(to:)`.
   */
  public static func != (lhs: JavaScriptValue, rhs: JavaScriptValue) -> Bool {
    return !lhs.isEqual(to: rhs)
  }

  // MARK: - Runtime-free initializers

  /**
   This is a lightweight way to create an undefined value that can be used in contexts
   where a runtime is not available or needed. The resulting value can be passed to
   JavaScript functions or used in comparisons.
   */
  public static func undefined() -> JavaScriptValue {
    return JavaScriptValue(nil, facebook.jsi.Value.undefined())
  }

  /**
   This is a lightweight way to create a null value that can be used in contexts
   where a runtime is not available or needed. The resulting value represents
   JavaScript's `null`, which is distinct from `undefined`.
   */
  public static func null() -> JavaScriptValue {
    return JavaScriptValue(nil, facebook.jsi.Value.null())
  }

  /**
   This is a lightweight way to create a boolean true value that can be used in contexts
   where a runtime is not available or needed.
   */
  public static func `true`() -> JavaScriptValue {
    return JavaScriptValue(nil, facebook.jsi.Value(true))
  }

  /**
   This is a lightweight way to create a boolean false value that can be used in contexts
   where a runtime is not available or needed.
   */
  public static func `false`() -> JavaScriptValue {
    return JavaScriptValue(nil, facebook.jsi.Value(false))
  }

  /**
   This is a lightweight way to create a numeric value that can be used in contexts
   where a runtime is not available or needed. JavaScript numbers are represented
   as double-precision floating-point values following the IEEE 754 standard.
   */
  public static func number(_ number: Double) -> JavaScriptValue {
    return JavaScriptValue(nil, facebook.jsi.Value(number))
  }

  public static func representing(value: JSRepresentable, in runtime: JavaScriptRuntime) -> JavaScriptValue {
    return value.toJSValue(in: runtime)
  }

  @available(*, deprecated, renamed: "representing(value:in:)")
  public static func from(_ value: Any, runtime: JavaScriptRuntime) -> JavaScriptValue {
    if let value = value as? JSRepresentable {
      return value.toJSValue(in: runtime)
    }
    return .undefined()
  }
}

extension JavaScriptValue: JSRepresentable {
  public static func fromJSValue(_ value: JavaScriptValue) -> JavaScriptValue {
    return value.copy()
  }

  public func toJSValue(in runtime: JavaScriptRuntime) -> JavaScriptValue {
    // `self` is borrowed, so we need to do a copy here
    return self.copy()
  }
}

extension JavaScriptValue: JSIRepresentable {
  static func fromJSIValue(_ value: borrowing facebook.jsi.Value, in runtime: facebook.jsi.Runtime) -> JavaScriptValue {
    fatalError("Unimplemented")
  }

  func toJSIValue(in runtime: facebook.jsi.Runtime) -> facebook.jsi.Value {
    return facebook.jsi.Value(runtime, pointee)
  }
}
