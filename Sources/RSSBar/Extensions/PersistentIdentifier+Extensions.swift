import CoreTransferable
import SwiftData
import UniformTypeIdentifiers


extension PersistentIdentifier: @retroactive Transferable {
  public static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .persistentIdentifier)
  }
}

extension UTType {
  public static var persistentIdentifier: UTType {
    UTType(exportedAs: "private.persistentIdentifier")
  }
}

extension PersistentIdentifier {
  func description() -> String {
    return String(describing: self)
  }
}
