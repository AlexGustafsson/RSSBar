import SwiftData
import SwiftUI

@ModelActor
public actor ModelActorDatabase: Database {
  public func delete(_ model: some PersistentModel) async {
    self.modelContext.delete(model)
  }

  public func insert(_ model: some PersistentModel) async {
    self.modelContext.insert(model)
  }

  public func delete<T: PersistentModel>(
    where predicate: Predicate<T>?
  ) async throws {
    try self.modelContext.delete(model: T.self, where: predicate)
  }

  public func save() async throws {
    try self.modelContext.save()
  }

  public func fetchCount<T>(_ descriptor: FetchDescriptor<T>) async throws
    -> Int
  {
    return try self.modelContext.fetchCount(descriptor)
  }

  public func fetch<T>(_ id: PersistentIdentifier, for: T.Type) async throws -> T? where T: PersistentModel {
    if let registered: T = self.modelContext.registeredModel(for: id) {
      return registered
    }

    let fetchDescriptor = FetchDescriptor<T>(
        predicate: #Predicate {
        $0.persistentModelID == id
    })

    return try self.modelContext.fetch(fetchDescriptor).first
  }

  public func fetch<T>(_ descriptor: FetchDescriptor<T>) async throws -> [T]
  where T: PersistentModel {
    return try self.modelContext.fetch(descriptor)
  }

  public func transaction(block: (_ modelContext: ModelContext) throws -> Void)
    async throws
  {
    return try self.modelContext.transaction(block: {
      try block(modelContext)
    })
  }
}
