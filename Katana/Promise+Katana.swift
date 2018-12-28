//
//  Promise+Katana.swift
//  Katana
//
//  Copyright © 2018 Bending Spoons.
//  Distributed under the MIT License.
//  See the LICENSE file for more information.
//

import Foundation

/// A Promise bounded to a Store.
///
/// A StorePromise manages the output of a dispatched action,
/// allowing to dispatch other actions to the same Store with a Promise-like syntax.
public class StorePromise<Value>: Promise<Value> {
  
  private let store: AnyStore
  
  private var dispatch: PromisableStoreDispatch {
    return self.store.dispatch
  }
  
  /// Initialize a new Promise in a resolved state with given value.
  ///
  /// - Parameter value: value to set
  init(store: AnyStore, resolved value: Value) {
    self.store = store
    
    super.init(resolved: value)
  }
  
  /// Initialize a new Promise in a rejected state with a specified error
  ///
  /// - Parameter error: error to set
  init(store: AnyStore, rejected error: Error) {
    self.store = store
    
    super.init(rejected: error)
  }
  
  /// Initialize a new Promise which specify a `body` to execute in specified `context`.
  /// A `context` is a Grand Central Dispatch queue which allows you to control the QoS of the execution
  /// and the thread in which it must be executed in.
  ///
  /// - Parameters:
  ///   - context: context in which the body of the promise is executed. If `nil` global background queue is used instead
  ///   - body: body of the promise, define the code executed by the promise itself.
  init(store: AnyStore, in context: Context? = nil, token: InvalidationToken? = nil, _ body: @escaping Body) {
    self.store = store
    
    super.init(in: context, token: token, body)
  }
}

extension Promise {
  /// Returns an equivalent Promise bounded to the given Store.
  func bounded(to store: AnyStore) -> StorePromise<Value> {
    return StorePromise(store: store, { resolve, reject, status in
      self.add(in: self.context, onResolve: resolve, onReject: reject, onCancel: status.cancel)
    })
  }
}

extension StorePromise {
  @discardableResult
  public func thenDispatch(_ updater: Dispatchable) -> StorePromise<Void> {
    return self.then { _ in
      return self.dispatch(updater)
    }.bounded(to: self.store)
  }

  @discardableResult
  public func thenDispatch(_ body: @escaping ( (Value) throws -> Dispatchable) ) -> StorePromise<Void> {
    return self.then { value in
      let updater = try body(value)
      return self.dispatch(updater)
    }.bounded(to: self.store)
  }
}

