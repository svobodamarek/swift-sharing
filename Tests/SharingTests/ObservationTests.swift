import Observation
import Sharing
import Testing

@MainActor
@Suite struct ObservationTests {
  @Test func nonPersistedShared() async {
    @Shared(value: 0) var count: Int
    await confirmation { confirm in
      withObservationTracking {
        _ = count
      } onChange: {
        confirm()
      }

      $count.withLock { $0 += 1 }
    }
  }

  @Test func persistedShared() async {
    @Shared(.inMemory("count")) var count = 0
    await confirmation { confirm in
      withObservationTracking {
        _ = count
      } onChange: {
        confirm()
      }

      $count.withLock { $0 += 1 }
    }
  }
}
