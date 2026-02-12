/**
 Contains specialized functions that execute fatal errors that terminate the program and print the message to the console.
 */
internal struct FatalError {
  /**
   Used to stop program execution when the JS runtime is not available but required to proceed.
   */
  public static func runtimeLost() -> Never {
    fatalError("The JavaScript runtime has been deallocated")
  }
}
