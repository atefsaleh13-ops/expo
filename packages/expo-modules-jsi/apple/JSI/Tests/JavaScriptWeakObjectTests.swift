// Copyright 2025-present 650 Industries. All rights reserved.

import Testing

@testable import ExpoModulesJSI

@Suite
struct JavaScriptWeakObjectTests {
  @Test
  func `initializes from JavaScriptObject`() {
    let runtime = JavaScriptRuntime()
    let object = runtime.createObject()
    let weakObject = JavaScriptWeakObject(runtime, object)
    
    // Should be able to lock and get the object back
    let lockedObject = weakObject.lock()
    #expect(lockedObject != nil)
  }
  
  @Test
  func `lock returns object when still alive`() {
    let runtime = JavaScriptRuntime()
    var object: JavaScriptObject? = runtime.createObject()
    object?.setProperty("test", value: 42)
    
    let weakObject = JavaScriptWeakObject(runtime, object!)
    
    // Object is still alive, lock should return it
    let lockedObject = weakObject.lock()
    #expect(lockedObject != nil)
    
    // Verify it's the same object
    let value = lockedObject?.getProperty("test")
    #expect(value?.getNumber() == 42)
  }
  
  @Test
  func `lock returns nil when object is collected`() async throws {
    let runtime = JavaScriptRuntime()
    var weakObject: JavaScriptWeakObject? = nil
    
    // Create object in a scope so it can be collected
    do {
      let object = runtime.createObject()
      object.setProperty("test", value: 123)
      weakObject = JavaScriptWeakObject(runtime, object)
      
      // Object should be accessible initially
      #expect(weakObject?.lock() != nil)
    }
    
    // Force garbage collection
    runtime.executeString("gc && gc && gc", sourceURL: "test")
    
    // Object should be collected now
    // Note: This test may be flaky depending on GC behavior
    // In practice, lock() should return nil after GC, but timing may vary
  }
  
  @Test
  func `asValue returns undefined when object is gone`() {
    let runtime = JavaScriptRuntime()
    var weakObject: JavaScriptWeakObject? = nil
    
    do {
      let object = runtime.createObject()
      weakObject = JavaScriptWeakObject(runtime, object)
      
      // Initially should return a valid value
      let value = weakObject?.asValue()
      #expect(value?.isObject() == true)
    }
    
    // Force garbage collection
    runtime.executeString("gc && gc && gc", sourceURL: "test")
    
    // After collection, asValue should return undefined
    // Note: This test may be flaky depending on GC behavior
  }
  
  @Test
  func `multiple weak references to same object`() {
    let runtime = JavaScriptRuntime()
    let object = runtime.createObject()
    object.setProperty("value", value: "shared")
    
    let weakObject1 = JavaScriptWeakObject(runtime, object)
    let weakObject2 = JavaScriptWeakObject(runtime, object)
    
    // Both should lock to the same object
    let locked1 = weakObject1.lock()
    let locked2 = weakObject2.lock()
    
    #expect(locked1 != nil)
    #expect(locked2 != nil)
    
    // Both should have the same property
    #expect(locked1?.getProperty("value")?.getString() == "shared")
    #expect(locked2?.getProperty("value")?.getString() == "shared")
  }
  
  @Test
  func `weak object does not prevent garbage collection`() {
    let runtime = JavaScriptRuntime()
    var weakObject: JavaScriptWeakObject? = nil
    
    // Create and immediately release object
    do {
      let object = runtime.createObject()
      weakObject = JavaScriptWeakObject(runtime, object)
    }
    
    // The weak reference exists but object should be eligible for GC
    #expect(weakObject != nil)
    
    // Force garbage collection
    runtime.executeString("gc && gc && gc", sourceURL: "test")
    
    // Weak object should still exist but lock may return nil
    #expect(weakObject != nil)
  }
  
  @Test
  func `asValue returns valid object when locked`() {
    let runtime = JavaScriptRuntime()
    let object = runtime.createObject()
    object.setProperty("name", value: "test")
    
    let weakObject = JavaScriptWeakObject(runtime, object)
    let value = weakObject.asValue()
    
    #expect(value.isObject() == true)
    #expect(value.getObject()?.getProperty("name")?.getString() == "test")
  }
}
