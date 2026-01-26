#if canImport(Combine)
  import Combine
  import Foundation
#elseif canImport(OpenCombine)
  import OpenCombine
  import Foundation
#endif

#if canImport(Combine) || canImport(OpenCombine)
  final class PassthroughRelay<Output>: Subject {
    typealias Failure = Never

    private let lock = NSLock()
    private var _upstreams: [any Subscription] = []
    private var _downstreams = ContiguousArray<RelaySubscription>()

    init() {}

    deinit {
      for subscription in _upstreams {
        subscription.cancel()
      }
    }

    func receive(subscriber: some Subscriber<Output, Never>) {
      let subscription = RelaySubscription(upstream: self, downstream: subscriber)
      withLock { _downstreams.append(subscription) }
      subscriber.receive(subscription: subscription)
    }

    func send(_ value: Output) {
      for subscription in withLock({ _downstreams }) {
        subscription.receive(value)
      }
    }

    func send(completion: Subscribers.Completion<Never>) {
      let subscriptions = withLock {
        let subscriptions = _downstreams
        _downstreams.removeAll()
        return subscriptions
      }
      for subscription in subscriptions {
        subscription.receive(completion: completion)
      }
    }

    func send(subscription: any Subscription) {
      withLock { _upstreams.append(subscription) }
      subscription.request(.unlimited)
    }

    private func remove(_ subscription: RelaySubscription) {
      withLock {
        guard let index = _downstreams.firstIndex(of: subscription)
        else { return }
        _downstreams.remove(at: index)
      }
    }

    fileprivate final class RelaySubscription: Subscription, Equatable {
      private var demand = Subscribers.Demand.none
      private var downstream: (any Subscriber<Output, Never>)?
      private let lock = NSLock()
      private var upstream: PassthroughRelay?

      init(upstream: PassthroughRelay, downstream: any Subscriber<Output, Never>) {
        self.upstream = upstream
        self.downstream = downstream
      }

      deinit {}

      func cancel() {
        withLock {
          downstream = nil
          upstream?.remove(self)
          upstream = nil
        }
      }

      func receive(_ value: Output) {
        lock.lock()
        guard let downstream else {
          lock.unlock()
          return
        }

        switch demand {
        case .unlimited:
          lock.unlock()
          // NB: Adding to unlimited demand has no effect and can be ignored.
          _ = downstream.receive(value)

        case .none:
          lock.unlock()

        default:
          demand -= 1
          lock.unlock()
          let moreDemand = downstream.receive(value)
          withLock { demand += moreDemand }
        }
      }

      func receive(completion: Subscribers.Completion<Never>) {
        withLock {
          downstream?.receive(completion: completion)
          downstream = nil
          upstream = nil
        }
      }

      func request(_ demand: Subscribers.Demand) {
        precondition(demand > 0, "Demand must be greater than zero")
        lock.lock()
        defer { lock.unlock() }
        guard case .some = downstream else { return }
        self.demand += demand
        guard let upstream else { return }
        let subscriptions = upstream.withLock { upstream._upstreams }
        for subscription in subscriptions {
          subscription.request(.unlimited)
        }
      }

      static func == (lhs: RelaySubscription, rhs: RelaySubscription) -> Bool {
        lhs === rhs
      }

      private func withLock<R>(_ body: () throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try body()
      }
    }
  
    private func withLock<R>(_ body: () throws -> R) rethrows -> R {
      lock.lock()
      defer { lock.unlock() }
      return try body()
    }
  }
#endif
