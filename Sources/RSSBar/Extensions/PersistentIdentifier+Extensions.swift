import CoreTransferable
import SwiftData
import UniformTypeIdentifiers

extension PersistentIdentifier: Transferable {
  public static var transferRepresentation: some TransferRepresentation {
    CodableRepresentation(contentType: .persistentIdentifier)
  }
}

extension UTType {
  public static var persistentIdentifier: UTType {
    UTType(exportedAs: "private.persistentIdentifier")
  }
}

// import CoreTransferable
// import SwiftData
// import UniformTypeIdentifiers

// extension UTType {
//   public static var persistentIdentifier: UTType {
//     UTType(exportedAs: "private.persistentIdentifier")
//   }
// }

// class Wrapper: NSObject, Transferable, NSItemProviderReading, Identifiable,
//   Codable
// {
//   public var id: PersistentIdentifier

//   init(id: PersistentIdentifier) {
//     self.id = id
//   }

//   public static var transferRepresentation: some TransferRepresentation {
//     CodableRepresentation(contentType: .persistentIdentifier)
//   }

//   static func object(withItemProviderData data: Data, typeIdentifier: String)
//     throws
//     -> Self
//   {
//     Wrapper(id: PersistentIdentifier(from: data))
//   }

//   static var readableTypeIdentifiersForItemProvider: [String] {
//     [UTType.persistentIdentifier.identifier]
//   }
// }
