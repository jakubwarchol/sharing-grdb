#if canImport(CloudKit)
  import CloudKit

  /// A protocol that defines logging capabilities for the SyncEngine.
  ///
  /// This protocol allows for injectable logging implementations, enabling
  /// custom logging solutions (like Sentry) alongside Apple's default Logger.
  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  public protocol SyncEngineLogger: Sendable {
    /// Logs a sync engine event with structured data.
    ///
    /// - Parameter eventData: The structured event data to log
    func log(_ eventData: SyncEventLogData)
    
    /// Logs a debug message.
    ///
    /// - Parameter message: The message to log at debug level
    func debug(_ message: String)
    
    /// Logs a trace message.
    ///
    /// - Parameter message: The message to log at trace level
    func trace(_ message: String)
    
    /// Logs a warning message.
    ///
    /// - Parameter message: The message to log at warning level
    func warning(_ message: String)
    
    /// Logs an error message.
    ///
    /// - Parameter message: The message to log at error level
    func error(_ message: String)
  }
#endif