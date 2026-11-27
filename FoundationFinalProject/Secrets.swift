import Foundation

enum Secrets {
    nonisolated static var notionToken: String {
        ProcessInfo.processInfo.environment["NOTION_TOKEN"]
            ?? ProcessInfo.processInfo.environment["BEARER_TOKEN"]
            ?? ""
    }

    nonisolated static var receitasDatabaseID: String {
        ProcessInfo.processInfo.environment["NOTION_RECEITAS_DATABASE_ID"] ?? ""
    }

    nonisolated static var categoriasDatabaseID: String {
        ProcessInfo.processInfo.environment["NOTION_CATEGORIAS_DATABASE_ID"] ?? ""
    }
}
