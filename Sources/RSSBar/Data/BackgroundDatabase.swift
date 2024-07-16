import SwiftData
import SwiftUI

public final class BackgroundDatabase: Database {
  private actor DatabaseContainer {
    private let factory: @Sendable () -> any Database
    private var wrappedTask: Task<any Database, Never>?

    fileprivate init(factory: @escaping @Sendable () -> any Database) {
      self.factory = factory
    }

    fileprivate var database: any Database {
      get async {
        if let wrappedTask {
          return await wrappedTask.value
        }
        let task = Task {
          factory()
        }
        self.wrappedTask = task
        return await task.value
      }
    }
  }

  private let container: DatabaseContainer

  private var database: any Database {
    get async {
      await container.database
    }
  }

  internal init(_ factory: @Sendable @escaping () -> any Database) {
    self.container = .init(factory: factory)
  }

  convenience init(modelContainer: ModelContainer) {
    self.init {
      return ModelActorDatabase(modelContainer: modelContainer)
    }
  }

  public func insert(_ model: some PersistentModel) async {
    return await self.database.insert(model)
  }

  public func delete(_ model: some PersistentModel) async {
    return await self.database.delete(model)
  }

  public func delete<T: PersistentModel>(
    where predicate: Predicate<T>?
  ) async throws {
    return try await self.database.delete(where: predicate)
  }

  public func fetchCount<T>(_ descriptor: FetchDescriptor<T>) async throws
    -> Int
  {
    return try await self.database.fetchCount(descriptor)
  }

  public func fetch<T>(_ id: PersistentIdentifier, for modelType: T.Type) async throws -> T? where T: PersistentModel {
    return try await self.database.fetch(id, for: modelType)
  }

  public func fetch<T>(_ descriptor: FetchDescriptor<T>) async throws -> [T]
  where T: PersistentModel {
    return try await self.database.fetch(descriptor)
  }

  public func save() async throws {
    return try await self.database.save()
  }

  public func transaction(block: (_ modelContext: ModelContext) throws -> Void)
    async throws
  {
    return try await self.database.transaction(block: block)
  }
}
