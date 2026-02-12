// Copyright 2025-present 650 Industries. All rights reserved.

import Testing
import ExpoModulesJSI

@Suite
@JavaScriptActor
struct JavaScriptArrayTests {
  let runtime = JavaScriptRuntime()

  // MARK: - Basic Array Creation and Access

  @Test
  func `create array from JavaScript`() throws {
    let array = try runtime.eval("[1, 2, 3, 4, 5]").getArray()
    #expect(array.size == 5)
  }

  @Test
  func `access empty array`() throws {
    let array = try runtime.eval("[]").getArray()
    #expect(array.size == 0)
  }

  @Test
  func `array with mixed types`() throws {
    let array = try runtime.eval("[1, 'hello', true, null, { key: 'value' }]").getArray()
    #expect(array.size == 5)
    #expect(try array.getValue(atIndex: 0).getInt() == 1)
    #expect(try array.getValue(atIndex: 1).getString() == "hello")
    #expect(try array.getValue(atIndex: 2).getBool() == true)
    #expect(try array.getValue(atIndex: 3).isNull() == true)
    #expect(try array.getValue(atIndex: 4).isObject() == true)
  }

  // MARK: - Size Property Tests

  @Test
  func `size of array with elements`() throws {
    let array = try runtime.eval("[10, 20, 30]").getArray()
    #expect(array.size == 3)
  }

  @Test
  func `size of single element array`() throws {
    let array = try runtime.eval("[42]").getArray()
    #expect(array.size == 1)
  }

  @Test
  func `size of large array`() throws {
    let array = try runtime.eval("Array(1000).fill(0)").getArray()
    #expect(array.size == 1000)
  }

  // MARK: - getValue(atIndex:) Tests

  @Test
  func `get value at valid index`() throws {
    let array = try runtime.eval("['a', 'b', 'c']").getArray()
    #expect(try array.getValue(atIndex: 0).getString() == "a")
    #expect(try array.getValue(atIndex: 1).getString() == "b")
    #expect(try array.getValue(atIndex: 2).getString() == "c")
  }

  @Test
  func `get first element`() throws {
    let array = try runtime.eval("[100, 200, 300]").getArray()
    #expect(try array.getValue(atIndex: 0).getInt() == 100)
  }

  @Test
  func `get last element`() throws {
    let array = try runtime.eval("[1, 2, 3, 4, 5]").getArray()
    #expect(try array.getValue(atIndex: 4).getInt() == 5)
  }

  @Test
  func `get value at negative index throws`() throws {
    let array = try runtime.eval("[1, 2, 3]").getArray()
    #expect(throws: JavaScriptArray.Errors.indexOutOfRange(index: -1, size: 3)) {
      try array.getValue(atIndex: -1)
    }
  }

  @Test
  func `get value at out of range index throws`() throws {
    let array = try runtime.eval("[1, 2, 3]").getArray()
    #expect(throws: JavaScriptArray.Errors.indexOutOfRange(index: 5, size: 3)) {
      try array.getValue(atIndex: 5)
    }
  }

  @Test
  func `get value at size index throws`() throws {
    let array = try runtime.eval("[10, 20, 30]").getArray()
    #expect(throws: JavaScriptArray.Errors.indexOutOfRange(index: 3, size: 3)) {
      try array.getValue(atIndex: 3)
    }
  }

  @Test
  func `get value from empty array throws`() throws {
    let array = try runtime.eval("[]").getArray()
    #expect(throws: JavaScriptArray.Errors.indexOutOfRange(index: 0, size: 0)) {
      try array.getValue(atIndex: 0)
    }
  }

  // MARK: - Subscript Tests

  @Test
  func `subscript access at valid index`() throws {
    let array = try runtime.eval("[100, 200, 300]").getArray()
    #expect(try array[0].getInt() == 100)
    #expect(try array[1].getInt() == 200)
    #expect(try array[2].getInt() == 300)
  }

  @Test
  func `subscript access throws at negative index`() throws {
    let array = try runtime.eval("[1, 2, 3]").getArray()
    #expect(throws: JavaScriptArray.Errors.indexOutOfRange(index: -1, size: 3)) {
      try array[-1]
    }
  }

  @Test
  func `subscript access throws at out of range index`() throws {
    let array = try runtime.eval("['a', 'b']").getArray()
    #expect(throws: JavaScriptArray.Errors.indexOutOfRange(index: 10, size: 2)) {
      try array[10]
    }
  }

  // MARK: - Map Function Tests

  @Test
  func `map to integers`() throws {
    let array = try runtime.eval("[1, 2, 3, 4, 5]").getArray()
    let integers = array.map { $0.getInt() }
    #expect(integers == [1, 2, 3, 4, 5])
  }

  @Test
  func `map to strings`() throws {
    let array = try runtime.eval("['hello', 'world', 'test']").getArray()
    let strings = array.map { $0.getString() }
    #expect(strings == ["hello", "world", "test"])
  }

  @Test
  func `map to doubles`() throws {
    let array = try runtime.eval("[1.5, 2.5, 3.5]").getArray()
    let doubles = array.map { $0.getDouble() }
    #expect(doubles == [1.5, 2.5, 3.5])
  }

  @Test
  func `map to booleans`() throws {
    let array = try runtime.eval("[true, false, true]").getArray()
    let booleans = array.map { $0.getBool() }
    #expect(booleans == [true, false, true])
  }

  @Test
  func `map with transformation`() throws {
    let array = try runtime.eval("[1, 2, 3]").getArray()
    let doubled = array.map { $0.getInt() * 2 }
    #expect(doubled == [2, 4, 6])
  }

  @Test
  func `map empty array`() throws {
    let array = try runtime.eval("[]").getArray()
    let result = array.map { $0.getInt() }
    #expect(result.isEmpty == true)
  }

  @Test
  func `map with complex transformation`() throws {
    let array = try runtime.eval("[1, 2, 3, 4, 5]").getArray()
    let strings = array.map { "Number: \($0.getInt())" }
    #expect(strings == ["Number: 1", "Number: 2", "Number: 3", "Number: 4", "Number: 5"])
  }

  @Test
  func `map array of objects`() throws {
    let array = try runtime.eval("[{name:'Alice',age:30},{name:'Bob',age:25}]").getArray()
    let names = array.map { value in
      value.getObject().getProperty("name").getString()
    }
    #expect(names == ["Alice", "Bob"])
  }

  @Test
  func `map throws when transform throws`() throws {
    let array = try runtime.eval("[1, 'not a number', 3]").getArray()

    struct CustomError: Error {}

    #expect(throws: CustomError.self) {
      try array.map { value -> Int in
        if value.isString() {
          throw CustomError()
        }
        return value.getInt()
      }
    }
  }

  // MARK: - asValue() Tests

  @Test
  func `convert array to value`() throws {
    let array = try runtime.eval("[1, 2, 3]").getArray()
    let value = array.asValue()
    #expect(value.isArray() == true)
    #expect(value.isObject() == true)
  }

  @Test
  func `array as value is array type`() throws {
    let array = try runtime.eval("['a', 'b', 'c']").getArray()
    let value = array.asValue()
    let backToArray = value.getArray()
    #expect(backToArray.size == 3)
    #expect(try backToArray[0].getString() == "a")
  }

  @Test
  func `array as value can be passed to functions`() throws {
    let array = try runtime.eval("[1, 2, 3]").getArray()
    let stringify = runtime.global()
      .getPropertyAsObject("JSON")
      .getPropertyAsFunction("stringify")

    let json = try stringify.call(arguments: array.asValue())
    #expect(json.getString() == "[1,2,3]")
  }

  // MARK: - Iteration Tests

  @Test
  func `iterate using size`() throws {
    let array = try runtime.eval("[10, 20, 30, 40]").getArray()
    var sum = 0

    for i in 0..<array.size {
      sum += try array[i].getInt()
    }
    #expect(sum == 100)
  }

  @Test
  func `iterate and collect values`() throws {
    let array = try runtime.eval("['a', 'b', 'c', 'd']").getArray()
    var values: [String] = []

    for i in 0..<array.size {
      values.append(try array[i].getString())
    }
    #expect(values == ["a", "b", "c", "d"])
  }

  // MARK: - Edge Cases

  @Test
  func `array with undefined elements`() throws {
    let array = try runtime.eval("[undefined, undefined, undefined]").getArray()
    #expect(array.size == 3)
    #expect(try array[0].isUndefined() == true)
    #expect(try array[1].isUndefined() == true)
    #expect(try array[2].isUndefined() == true)
  }

  @Test
  func `array with null elements`() throws {
    let array = try runtime.eval("[null, null]").getArray()
    #expect(array.size == 2)
    #expect(try array[0].isNull() == true)
    #expect(try array[1].isNull() == true)
  }

  @Test
  func `nested arrays`() throws {
    let array = try runtime.eval("[[1, 2], [3, 4], [5, 6]]").getArray()
    #expect(array.size == 3)

    let firstNested = try array[0].getArray()
    #expect(firstNested.size == 2)
    #expect(try firstNested[0].getInt() == 1)
    #expect(try firstNested[1].getInt() == 2)
  }

  @Test
  func `array from Array.from()`() throws {
    let array = try runtime.eval("Array.from([1, 2, 3])").getArray()
    #expect(array.size == 3)
    #expect(try array.map { $0.getInt() } == [1, 2, 3])
  }

  @Test
  func `array from spread operator`() throws {
    let array = try runtime.eval("[...[1, 2], ...[3, 4]]").getArray()
    #expect(array.size == 4)
    #expect(try array.map { $0.getInt() } == [1, 2, 3, 4])
  }

  // MARK: - Error Description Tests

  @Test
  func `error description for out of range`() {
    let error = JavaScriptArray.Errors.indexOutOfRange(index: 5, size: 3)
    let description = error.description
    #expect(description.contains("5"))
    #expect(description.contains("3"))
    #expect(description.contains("0..<3"))
  }

  // MARK: - Performance Tests

  @Test
  func `access all elements in large array`() throws {
    let array = try runtime.eval("Array(100).fill(42)").getArray()

    for i in 0..<array.size {
      let value = try array[i]
      #expect(value.getInt() == 42)
    }
  }

  @Test
  func `map large array`() throws {
    let array = try runtime.eval("Array(100).fill(1)").getArray()
    let result = array.map { $0.getInt() }
    #expect(result.count == 100)
    #expect(result.allSatisfy { $0 == 1 })
  }

  // MARK: - Type Checking

  @Test
  func `array is object and array`() throws {
    let arrayValue = try runtime.eval("[1, 2, 3]")
    #expect(arrayValue.isObject() == true)
    #expect(arrayValue.isArray() == true)
    #expect(arrayValue.isFunction() == false)
  }

  @Test
  func `array instanceof Array`() throws {
    let array = try runtime.eval("[1, 2, 3]").getArray()
    let arrayConstructor = runtime.global().getPropertyAsFunction("Array")
    #expect(array.asValue().getObject().instanceOf(arrayConstructor) == true)
  }
}
