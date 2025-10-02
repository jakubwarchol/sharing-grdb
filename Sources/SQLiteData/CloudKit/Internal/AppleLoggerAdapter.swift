#if canImport(CloudKit)
  import CloudKit
  import os

  /// An adapter that implements SyncEngineLogger using Apple's os.Logger.
  ///
  /// This adapter maintains compatibility with the existing logging implementation
  /// while conforming to the SyncEngineLogger protocol.
  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  public struct AppleLoggerAdapter: SyncEngineLogger {
    private let logger: Logger
    
    /// Creates a new Apple Logger adapter.
    ///
    /// - Parameter logger: The underlying os.Logger to use
    public init(logger: Logger) {
      self.logger = logger
    }
    
    /// Creates a new Apple Logger adapter with subsystem and category.
    ///
    /// - Parameters:
    ///   - subsystem: The subsystem for the logger
    ///   - category: The category for the logger
    public init(subsystem: String, category: String) {
      self.logger = Logger(subsystem: subsystem, category: category)
    }
    
    /// Creates a disabled logger adapter for testing.
    public static var disabled: AppleLoggerAdapter {
      AppleLoggerAdapter(logger: Logger(.disabled))
    }
    
    public func log(_ eventData: SyncEventLogData) {
      let prefix = "[\(eventData.databaseScope)] handleEvent:"
      
      switch eventData.details {
      case .stateUpdate:
        debug("\(prefix) stateUpdate")
        
      case .accountChange(let changeType):
        switch changeType {
        case .signIn(let userID, let zoneName, let ownerName):
          debug(
            """
            \(prefix) signIn
              Current user: \(userID).\(ownerName).\(zoneName)
            """
          )
        case .signOut(let userID, let zoneName, let ownerName):
          debug(
            """
            \(prefix) signOut
              Previous user: \(userID).\(ownerName).\(zoneName)
            """
          )
        case .switchAccounts(let previousUser, let currentUser):
          debug(
            """
            \(prefix) switchAccounts:
              Previous user: \(previousUser.userID).\(previousUser.ownerName).\(previousUser.zoneName)
              Current user:  \(currentUser.userID).\(currentUser.ownerName).\(currentUser.zoneName)
            """
          )
        case .unknown:
          debug("unknown")
        }
        
      case .fetchedDatabaseChanges(_, let deletions):
        let deletionsMsg =
          deletions.isEmpty
          ? "⚪️ No deletions"
          : "✅ Zones deleted (\(deletions.count)): "
            + deletions
            .map { $0.zoneName + ":" + $0.ownerName }
            .sorted()
            .joined(separator: ", ")
        debug(
          """
          \(prefix) fetchedDatabaseChanges
            \(deletionsMsg)
          """
        )
        
      case .fetchedRecordZoneChanges(let modificationsByType, let deletionsByType):
        let totalModifications = modificationsByType.values.reduce(0, +)
        let totalDeletions = deletionsByType.values.reduce(0, +)
        
        let recordTypeDeletions = deletionsByType.keys.sorted()
          .map { recordType in "\(recordType) (\(deletionsByType[recordType]!))" }
          .joined(separator: ", ")
        let deletions =
          deletionsByType.isEmpty
          ? "⚪️ No deletions" : "✅ Records deleted (\(totalDeletions)): \(recordTypeDeletions)"

        let recordTypeModifications = modificationsByType.keys.sorted()
          .map { recordType in "\(recordType) (\(modificationsByType[recordType]!))" }
          .joined(separator: ", ")
        let modifications =
          modificationsByType.isEmpty
          ? "⚪️ No modifications"
          : "✅ Records modified (\(totalModifications)): \(recordTypeModifications)"

        debug(
          """
          \(prefix) fetchedRecordZoneChanges
            \(modifications)
            \(deletions)
          """
        )
        
      case .sentDatabaseChanges(
        let savedZones,
        let failedZoneSaves,
        let deletedZoneNames,
        let failedZoneDeletes
      ):
        let savedZoneNames =
          savedZones
          .map { $0.zoneName + ":" + $0.ownerName }
          .sorted()
          .joined(separator: ", ")
        let savedZonesMsg =
          savedZones.isEmpty
          ? "⚪️ No saved zones" : "✅ Saved zones (\(savedZones.count)): \(savedZoneNames)"

        let deletedZoneNamesStr =
          deletedZoneNames
          .sorted()
          .joined(separator: ", ")
        let deletedZones =
          deletedZoneNames.isEmpty
          ? "⚪️ No deleted zones"
          : "✅ Deleted zones (\(deletedZoneNames.count)): \(deletedZoneNamesStr)"

        let failedZoneSaveNames =
          failedZoneSaves
          .map { $0.zoneName + ":" + $0.ownerName }
          .sorted()
          .joined(separator: ", ")
        let failedZoneSavesMsg =
          failedZoneSaves.isEmpty
          ? "⚪️ No failed saved zones"
          : "🛑 Failed zone saves (\(failedZoneSaves.count)): \(failedZoneSaveNames)"

        let failedZoneDeleteNames = failedZoneDeletes
          .map { $0.zoneName }
          .sorted()
          .joined(separator: ", ")
        let failedZoneDeletesMsg =
          failedZoneDeletes.isEmpty
          ? "⚪️ No failed deleted zones"
          : "🛑 Failed zone delete (\(failedZoneDeletes.count)): \(failedZoneDeleteNames)"

        debug(
          """
          \(prefix) sentDatabaseChanges
            \(savedZonesMsg)
            \(deletedZones) 
            \(failedZoneSavesMsg)
            \(failedZoneDeletesMsg)
          """
        )
        
      case .sentRecordZoneChanges(
        let savedRecordsByType,
        let failedRecordSavesByZone,
        let deletedRecordCount,
        let failedRecordDeleteCount
      ):
        let savedRecords = savedRecordsByType.keys
          .sorted()
          .map { "\($0) (\(savedRecordsByType[$0]!))" }
          .joined(separator: ", ")

        let failedRecordSaves = failedRecordSavesByZone.keys
          .sorted()
          .map { "\($0) (\(failedRecordSavesByZone[$0]!))" }
          .joined(separator: ", ")

        debug(
          """
          \(prefix) sentRecordZoneChanges
            \(savedRecordsByType.isEmpty ? "⚪️ No records saved" : "✅ Saved records: \(savedRecords)")
            \(deletedRecordCount == 0 ? "⚪️ No records deleted" : "✅ Deleted records (\(deletedRecordCount))")
            \(failedRecordSavesByZone.isEmpty ? "⚪️ No records failed save" : "🛑 Records failed save: \(failedRecordSaves)")
            \(failedRecordDeleteCount == 0 ? "⚪️ No records failed delete" : "🛑 Records failed delete (\(failedRecordDeleteCount))")
          """
        )
        
      case .willFetchChanges:
        debug("\(prefix) willFetchChanges")
        
      case .willFetchRecordZoneChanges(let zoneName):
        debug("\(prefix) willFetchRecordZoneChanges: \(zoneName)")
        
      case .didFetchRecordZoneChanges(let zoneName, let ownerName, let errorCode):
        let error = errorCode.map { "\n  ❌ \($0)" } ?? ""
        debug(
          """
          \(prefix) didFetchRecordZoneChanges
            ✅ Zone: \(zoneName):\(ownerName)\(error)
          """
        )
        
      case .didFetchChanges:
        debug("\(prefix) didFetchChanges")
        
      case .willSendChanges(let reason):
        debug("\(prefix) willSendChanges: \(reason)")
        
      case .didSendChanges(let reason):
        debug("\(prefix) didSendChanges: \(reason)")
      }
    }
    
    public func debug(_ message: String) {
      // Apple's Logger requires string interpolation for its OSLogMessage type
      logger.debug("\(message)")
    }
    
    public func trace(_ message: String) {
      logger.trace("\(message)")
    }
    
    public func warning(_ message: String) {
      logger.warning("\(message)")
    }
    
    public func error(_ message: String) {
      logger.error("\(message)")
    }
  }
#endif