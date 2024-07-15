import SwiftData
import SwiftUI

public protocol Database {
  func insert<T>(_ model: T) async where T: PersistentModel

  func save() async throws

  func fetchCount<T>(_ descriptor: FetchDescriptor<T>) async throws -> Int
  func fetch<T>(_ id: PersistentIdentifier, for: T.Type) async throws -> T? where T: PersistentModel
  func fetch<T>(_ descriptor: FetchDescriptor<T>) async throws -> [T]
  where T: PersistentModel

  func delete<T>(_ model: T) async where T: PersistentModel
  func delete<T: PersistentModel>(
    where predicate: Predicate<T>?
  ) async throws

  func transaction(block: (_ modelContext: ModelContext) throws -> Void)
    async throws
}

extension Database {
  public func fetch<T: PersistentModel>(
    where predicate: Predicate<T>?,
    sortBy: [SortDescriptor<T>]
  ) async throws -> [T] {
    try await self.fetch(
      FetchDescriptor<T>(predicate: predicate, sortBy: sortBy))
  }

  public func fetch<T: PersistentModel>(
    _ predicate: Predicate<T>,
    sortBy: [SortDescriptor<T>] = []
  ) async throws -> [T] {
    try await self.fetch(where: predicate, sortBy: sortBy)
  }

  public func fetch<T: PersistentModel>(
    _: T.Type,
    predicate: Predicate<T>? = nil,
    sortBy: [SortDescriptor<T>] = []
  ) async throws -> [T] {
    try await self.fetch(where: predicate, sortBy: sortBy)
  }

  public func delete<T: PersistentModel>(
    model _: T.Type,
    where predicate: Predicate<T>? = nil
  ) async throws {
    try await self.delete(where: predicate)
  }
}

struct DefaultDatabase: Database {
  struct NotImplementedError: Error {
    static let instance = NotImplementedError()
  }

  static let instance = DefaultDatabase()

  func insert(_: some PersistentModel) async {
    assertionFailure("No Database Set.")
  }

  func fetchCount<T>(_ descriptor: FetchDescriptor<T>) async throws -> Int {
    assertionFailure("No Database Set.")
    throw NotImplementedError.instance
  }

  func fetch<T>(_ id: PersistentIdentifier, for: T.Type) async throws -> T? where T: PersistentModel
  {
    assertionFailure("No Database Set.")
    throw NotImplementedError.instance
  }

  func fetch<T>(_: FetchDescriptor<T>) async throws -> [T]
  where T: PersistentModel {
    assertionFailure("No Database Set.")
    throw NotImplementedError.instance
  }

  func delete(_: some PersistentModel) async {
    assertionFailure("No Database Set.")
  }

  func delete<T: PersistentModel>(
    where predicate: Predicate<T>?
  ) async throws {
    assertionFailure("No Database Set.")
  }

  func transaction(block: (_ modelContext: ModelContext) throws -> Void)
    async throws
  {
    assertionFailure("No Database Set.")
  }

  func save() async throws {
    assertionFailure("No Database Set.")
    throw NotImplementedError.instance
  }
}

private struct DatabaseKey: EnvironmentKey {
  static var defaultValue: any Database {
    DefaultDatabase.instance
  }
}

extension EnvironmentValues {
  public var database: any Database {
    get { self[DatabaseKey.self] }
    set { self[DatabaseKey.self] = newValue }
  }
}

extension Scene {
  public func database(
    _ database: any Database
  ) -> some Scene {
    self.environment(\.database, database)
  }
}

extension View {
  public func database(
    _ database: any Database
  ) -> some View {
    self.environment(\.database, database)
  }
}
