#if os(Android)
  import SkipFuse

  public enum SharingDebug {
    private static let logger = Logger(subsystem: "io.ocode.androidtest", category: "TestName")

    public static func log(_ message: String = "SharingDebug log") {
      logger.info("\(message)")
    }
  }
#endif
