#if canImport(CloudKit)
  import CloudKit

  /// Structured data for logging sync events with all necessary details
  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  public struct SyncEventLogData: Sendable {
    public let databaseScope: String
    public let eventType: String
    public let details: Details
    
    public init(databaseScope: String, eventType: String, details: Details) {
      self.databaseScope = databaseScope
      self.eventType = eventType
      self.details = details
    }
    
    public enum Details: Sendable {
      case stateUpdate
      case accountChange(changeType: AccountChangeType)
      case fetchedDatabaseChanges(
        modifications: [(zoneName: String, ownerName: String)],
        deletions: [(zoneName: String, ownerName: String, reason: String)]
      )
      case fetchedRecordZoneChanges(
        modificationsByType: [String: Int],  // recordType -> count
        deletionsByType: [String: Int]       // recordType -> count
      )
      case sentDatabaseChanges(
        savedZones: [(zoneName: String, ownerName: String)],
        failedZoneSaves: [(zoneName: String, ownerName: String, errorCode: String)],
        deletedZoneNames: [String],
        failedZoneDeletes: [(zoneName: String, errorCode: String)]
      )
      case sentRecordZoneChanges(
        savedRecordsByType: [String: Int],
        failedRecordSavesByZone: [String: Int],
        deletedRecordCount: Int,
        failedRecordDeleteCount: Int
      )
      case willFetchChanges
      case willFetchRecordZoneChanges(zoneName: String)
      case didFetchChanges
      case didFetchRecordZoneChanges(zoneName: String, ownerName: String, errorCode: String?)
      case willSendChanges(reason: String)
      case didSendChanges(reason: String)
    }
    
    public enum AccountChangeType: Sendable {
      case signIn(userID: String, zoneName: String, ownerName: String)
      case signOut(userID: String, zoneName: String, ownerName: String)
      case switchAccounts(
        previousUser: (userID: String, zoneName: String, ownerName: String),
        currentUser: (userID: String, zoneName: String, ownerName: String)
      )
      case unknown
    }
  }
#endif