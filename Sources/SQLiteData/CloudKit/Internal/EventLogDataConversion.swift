#if canImport(CloudKit)
  import CloudKit

  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  extension SyncEngine.Event {
    /// Converts a sync engine event to structured log data
    func toLogData(databaseScope: String) -> SyncEventLogData {
      switch self {
      case .stateUpdate:
        return SyncEventLogData(
          databaseScope: databaseScope,
          eventType: "stateUpdate",
          details: .stateUpdate
        )
        
      case .accountChange(let changeType):
        let accountChange: SyncEventLogData.AccountChangeType
        switch changeType {
        case .signIn(let currentUser):
          accountChange = .signIn(
            userID: currentUser.recordName,
            zoneName: currentUser.zoneID.zoneName,
            ownerName: currentUser.zoneID.ownerName
          )
        case .signOut(let previousUser):
          accountChange = .signOut(
            userID: previousUser.recordName,
            zoneName: previousUser.zoneID.zoneName,
            ownerName: previousUser.zoneID.ownerName
          )
        case .switchAccounts(let previousUser, let currentUser):
          accountChange = .switchAccounts(
            previousUser: (
              userID: previousUser.recordName,
              zoneName: previousUser.zoneID.zoneName,
              ownerName: previousUser.zoneID.ownerName
            ),
            currentUser: (
              userID: currentUser.recordName,
              zoneName: currentUser.zoneID.zoneName,
              ownerName: currentUser.zoneID.ownerName
            )
          )
        @unknown default:
          accountChange = .unknown
        }
        return SyncEventLogData(
          databaseScope: databaseScope,
          eventType: "accountChange",
          details: .accountChange(changeType: accountChange)
        )
        
      case .fetchedDatabaseChanges(let modifications, let deletions):
        return SyncEventLogData(
          databaseScope: databaseScope,
          eventType: "fetchedDatabaseChanges",
          details: .fetchedDatabaseChanges(
            modifications: modifications.map { (zoneName: $0.zoneName, ownerName: $0.ownerName) },
            deletions: deletions.map { 
              (zoneName: $0.zoneID.zoneName, ownerName: $0.zoneID.ownerName, reason: reasonString($0.reason))
            }
          )
        )
        
      case .fetchedRecordZoneChanges(let modifications, let deletions):
        let modificationsByType = Dictionary(
          grouping: modifications,
          by: \.recordType
        ).mapValues { $0.count }
        
        let deletionsByType = Dictionary(
          grouping: deletions,
          by: \.recordType
        ).mapValues { $0.count }
        
        return SyncEventLogData(
          databaseScope: databaseScope,
          eventType: "fetchedRecordZoneChanges",
          details: .fetchedRecordZoneChanges(
            modificationsByType: modificationsByType,
            deletionsByType: deletionsByType
          )
        )
        
      case .sentDatabaseChanges(
        let savedZones,
        let failedZoneSaves,
        let deletedZoneIDs,
        let failedZoneDeletes
      ):
        return SyncEventLogData(
          databaseScope: databaseScope,
          eventType: "sentDatabaseChanges",
          details: .sentDatabaseChanges(
            savedZones: savedZones.map { (zoneName: $0.zoneID.zoneName, ownerName: $0.zoneID.ownerName) },
            failedZoneSaves: failedZoneSaves.map { 
              (zoneName: $0.zone.zoneID.zoneName, ownerName: $0.zone.zoneID.ownerName, errorCode: errorCodeString($0.error))
            },
            deletedZoneNames: deletedZoneIDs.map { $0.zoneName },
            failedZoneDeletes: failedZoneDeletes.map { 
              (zoneName: $0.key.zoneName, errorCode: errorCodeString($0.value))
            }
          )
        )
        
      case .sentRecordZoneChanges(
        let savedRecords,
        let failedRecordSaves,
        let deletedRecordIDs,
        let failedRecordDeletes
      ):
        let savedRecordsByType = Dictionary(
          grouping: savedRecords,
          by: \.recordType
        ).mapValues { $0.count }
        
        let failedRecordSavesByZone = Dictionary(
          grouping: failedRecordSaves,
          by: { $0.record.recordID.zoneID.zoneName + ":" + $0.record.recordID.zoneID.ownerName }
        ).mapValues { $0.count }
        
        return SyncEventLogData(
          databaseScope: databaseScope,
          eventType: "sentRecordZoneChanges",
          details: .sentRecordZoneChanges(
            savedRecordsByType: savedRecordsByType,
            failedRecordSavesByZone: failedRecordSavesByZone,
            deletedRecordCount: deletedRecordIDs.count,
            failedRecordDeleteCount: failedRecordDeletes.count
          )
        )
        
      case .willFetchChanges:
        return SyncEventLogData(
          databaseScope: databaseScope,
          eventType: "willFetchChanges",
          details: .willFetchChanges
        )
        
      case .willFetchRecordZoneChanges(let zoneID):
        return SyncEventLogData(
          databaseScope: databaseScope,
          eventType: "willFetchRecordZoneChanges",
          details: .willFetchRecordZoneChanges(zoneName: zoneID.zoneName)
        )
        
      case .didFetchRecordZoneChanges(let zoneID, let error):
        return SyncEventLogData(
          databaseScope: databaseScope,
          eventType: "didFetchRecordZoneChanges",
          details: .didFetchRecordZoneChanges(
            zoneName: zoneID.zoneName,
            ownerName: zoneID.ownerName,
            errorCode: error.map { errorCodeString($0) }
          )
        )
        
      case .didFetchChanges:
        return SyncEventLogData(
          databaseScope: databaseScope,
          eventType: "didFetchChanges",
          details: .didFetchChanges
        )
        
      case .willSendChanges(let context):
        return SyncEventLogData(
          databaseScope: databaseScope,
          eventType: "willSendChanges",
          details: .willSendChanges(reason: context.reason.description)
        )
        
      case .didSendChanges(let context):
        return SyncEventLogData(
          databaseScope: databaseScope,
          eventType: "didSendChanges",
          details: .didSendChanges(reason: context.reason.description)
        )
        
      @unknown default:
        return SyncEventLogData(
          databaseScope: databaseScope,
          eventType: "unknown",
          details: .stateUpdate
        )
      }
    }
    
    private func reasonString(_ reason: CKDatabase.DatabaseChange.Deletion.Reason) -> String {
      switch reason {
      case .deleted: return "deleted"
      case .purged: return "purged"
      case .encryptedDataReset: return "encryptedDataReset"
      @unknown default: return "unknown"
      }
    }
    
    private func errorCodeString(_ error: CKError) -> String {
      switch error.code {
      case .internalError: return "internalError"
      case .partialFailure: return "partialFailure"
      case .networkUnavailable: return "networkUnavailable"
      case .networkFailure: return "networkFailure"
      case .badContainer: return "badContainer"
      case .serviceUnavailable: return "serviceUnavailable"
      case .requestRateLimited: return "requestRateLimited"
      case .missingEntitlement: return "missingEntitlement"
      case .notAuthenticated: return "notAuthenticated"
      case .permissionFailure: return "permissionFailure"
      case .unknownItem: return "unknownItem"
      case .invalidArguments: return "invalidArguments"
      case .resultsTruncated: return "resultsTruncated"
      case .serverRecordChanged: return "serverRecordChanged"
      case .serverRejectedRequest: return "serverRejectedRequest"
      case .assetFileNotFound: return "assetFileNotFound"
      case .assetFileModified: return "assetFileModified"
      case .incompatibleVersion: return "incompatibleVersion"
      case .constraintViolation: return "constraintViolation"
      case .operationCancelled: return "operationCancelled"
      case .changeTokenExpired: return "changeTokenExpired"
      case .batchRequestFailed: return "batchRequestFailed"
      case .zoneBusy: return "zoneBusy"
      case .badDatabase: return "badDatabase"
      case .quotaExceeded: return "quotaExceeded"
      case .zoneNotFound: return "zoneNotFound"
      case .limitExceeded: return "limitExceeded"
      case .userDeletedZone: return "userDeletedZone"
      case .tooManyParticipants: return "tooManyParticipants"
      case .alreadyShared: return "alreadyShared"
      case .referenceViolation: return "referenceViolation"
      case .managedAccountRestricted: return "managedAccountRestricted"
      case .participantMayNeedVerification: return "participantMayNeedVerification"
      case .serverResponseLost: return "serverResponseLost"
      case .assetNotAvailable: return "assetNotAvailable"
      case .accountTemporarilyUnavailable: return "accountTemporarilyUnavailable"
      @unknown default: return "unknown"
      }
    }
  }
  
  @available(iOS 17, macOS 14, tvOS 17, watchOS 10, *)
  extension CKSyncEngine.SyncReason {
    var description: String {
      switch self {
      case .scheduled: return "scheduled"
      case .manual: return "manual"
      @unknown default: return "unknown"
      }
    }
  }
#endif