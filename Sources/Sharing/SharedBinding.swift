#if canImport(SwiftUI)
  import PerceptionCore
  import SwiftUI

  extension Binding {
    /// Creates a binding from a shared reference.
    ///
    /// Useful for binding shared state to a SwiftUI control.
    ///
    /// ```swift
    /// @Shared var count: Int
    /// // ...
    /// Stepper("\(count)", value: Binding($count))
    /// ```
    ///
    /// - Parameter base: A shared reference to a value.
    @MainActor
    public init(_ base: Shared<Value>) {
      guard
        let reference = base.reference as? any MutableReference & Observable
      else {
        #if os(Android)
          func open(_ reference: some MutableReference<Value>) -> Binding<Value> {
            return Binding(
              get: { reference.wrappedValue },
              set: { newValue in
                reference.withLock { $0 = newValue }
              }
            )
          }
          self = open(base.reference)
          return
        #else
          fatalError("Reference does not conform to Observable")
        #endif
      }
      func open<V>(_ reference: some MutableReference<V> & Observable) -> Binding<Value> {
        @SwiftUI.Bindable var reference = reference
        return $reference._wrappedValue as! Binding<Value>
      }
      self = open(reference)
    }
  }

  extension MutableReference {
    fileprivate var _wrappedValue: Value {
      get { wrappedValue }
      set { withLock { $0 = newValue } }
    }
  }
#endif
