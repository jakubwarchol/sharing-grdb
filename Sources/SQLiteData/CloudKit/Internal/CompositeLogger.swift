#if canImport(CloudKit)
  import CloudKit

  /// A logger that forwards all logging calls to multiple underlying loggers.
  ///
  /// This allows you to combine different logging implementations, such as
  /// Apple's Logger with a custom Sentry logger.
  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  public struct CompositeLogger: SyncEngineLogger {
    private let loggers: [any SyncEngineLogger]
    
    /// Creates a composite logger from any number of loggers.
    ///
    /// - Parameter loggers: The loggers to forward calls to
    public init(_ loggers: any SyncEngineLogger...) {
      self.loggers = loggers
    }
    
    /// Creates a composite logger from an array of loggers.
    ///
    /// - Parameter loggers: The array of loggers to forward calls to
    public init(loggers: [any SyncEngineLogger]) {
      self.loggers = loggers
    }
    
    public func log(_ eventData: SyncEventLogData) {
      for logger in loggers {
        logger.log(eventData)
      }
    }
    
    public func debug(_ message: String) {
      for logger in loggers {
        logger.debug(message)
      }
    }
    
    public func trace(_ message: String) {
      for logger in loggers {
        logger.trace(message)
      }
    }
    
    public func warning(_ message: String) {
      for logger in loggers {
        logger.warning(message)
      }
    }
    
    public func error(_ message: String) {
      for logger in loggers {
        logger.error(message)
      }
    }
  }
#endif