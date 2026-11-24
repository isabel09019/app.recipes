import Foundation

/// Campos que recebemos da API antes de salvar/converter para SwiftData.
struct ReceitaNotion: Sendable {
    let id: String
    let titulo: String
    let descricao: String
    let nutricao: String
    let ingredientes: String
    let categorias: [String]
}

actor NotionReceitasAPI {
    private let token = Secrets.notionToken
    private let databaseID = Secrets.receitasDatabaseID
    private let session = URLSession.shared

    func buscarReceitas() async throws -> [ReceitaNotion] {
        guard !token.isEmpty else { throw ErroNotion.configuracao("NOTION_TOKEN") }
        guard !databaseID.isEmpty else {
            throw ErroNotion.configuracao("NOTION_RECEITAS_DATABASE_ID")
        }

        let database = try await requisicao("databases/\(databaseID)")
        guard
            let sources = database["data_sources"] as? [[String: Any]],
            let sourceID = sources.first?["id"] as? String
        else { throw ErroNotion.dataSourceAusente }

        var receitas: [ReceitaNotion] = []
        var cursor: String?
        repeat {
            var body: [String: Any] = ["page_size": 100]
            if let cursor { body["start_cursor"] = cursor }
            let response = try await requisicao(
                "data_sources/\(sourceID)/query",
                method: "POST",
                body: body
            )
            let pages = response["results"] as? [[String: Any]] ?? []
            receitas += pages.compactMap(converter)
            cursor = response["has_more"] as? Bool == true
                ? response["next_cursor"] as? String
                : nil
        } while cursor != nil

        return receitas
    }

    private func converter(_ page: [String: Any]) -> ReceitaNotion? {
        guard
            let id = page["id"] as? String,
            let properties = page["properties"] as? [String: Any],
            let title = propriedade(["Nome", "Name"], em: properties)
        else { return nil }

        let titulo = texto(title, tipo: "title")
        guard !titulo.isEmpty else { return nil }

        let description = propriedade(["descrição", "descricao"], em: properties)
        let nutrition = propriedade(["informação nutricional", "informacao nutricional"], em: properties)
        let ingredients = propriedade(["ingredientes"], em: properties)
        let tags = propriedade(["Seleção múltipla"], em: properties)

        return ReceitaNotion(
            id: id,
            titulo: titulo,
            descricao: description.map { texto($0, tipo: "rich_text") } ?? "",
            nutricao: nutrition.map { texto($0, tipo: "rich_text") } ?? "",
            ingredientes: ingredients.map { texto($0, tipo: "rich_text") } ?? "",
            categorias: tags.map { opcoes($0, tipo: "multi_select") } ?? []
        )
    }

    private func propriedade(_ nomes: [String], em properties: [String: Any]) -> [String: Any]? {
        let chaves = Set(nomes.map(normalizar))
        guard let item = properties.first(where: { chaves.contains(normalizar($0.key)) }) else { return nil }
        return item.value as? [String: Any]
    }

    private func texto(_ property: [String: Any], tipo: String) -> String {
        (property[tipo] as? [[String: Any]] ?? []).compactMap { item in
            (item["plain_text"] as? String)
                ?? (item["text"] as? [String: Any])?["content"] as? String
        }.joined()
    }

    private func opcoes(_ property: [String: Any], tipo: String) -> [String] {
        (property[tipo] as? [[String: Any]] ?? []).compactMap { $0["name"] as? String }
    }

    private func normalizar(_ texto: String) -> String {
        texto.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func requisicao(
        _ caminho: String,
        method: String = "GET",
        body: [String: Any]? = nil
    ) async throws -> [String: Any] {
        guard let url = URL(string: "https://api.notion.com/v1/\(caminho)") else {
            throw ErroNotion.respostaInvalida
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("2026-03-11", forHTTPHeaderField: "Notion-Version")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body { request.httpBody = try JSONSerialization.data(withJSONObject: body) }

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw ErroNotion.respostaInvalida }
        guard (200..<300).contains(http.statusCode) else {
            let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            throw ErroNotion.http(http.statusCode, json?["message"] as? String)
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ErroNotion.respostaInvalida
        }
        return json
    }
}

enum ErroNotion: LocalizedError {
    case configuracao(String)
    case dataSourceAusente
    case respostaInvalida
    case http(Int, String?)

    var errorDescription: String? {
        switch self {
        case .configuracao(let chave): return "Configure \(chave) no esquema local do Xcode."
        case .dataSourceAusente: return "Não encontrei uma data source na database."
        case .respostaInvalida: return "A resposta do Notion não pôde ser lida."
        case .http(let status, let mensagem): return "Erro do Notion (\(status)): \(mensagem ?? "sem detalhes")."
        }
    }
}
