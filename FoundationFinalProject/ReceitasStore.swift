//import Foundation
//import Observation
//import SwiftData
//
///// Busca no Notion e atualiza a cópia local usada pelas telas.
//@MainActor
//@Observable
//final class ReceitasStore {
//    private(set) var estaCarregando = false
//    private(set) var erro: String?
//
//    private let api = NotionReceitasAPI()
//
//    func atualizar(context: ModelContext) async {
//        estaCarregando = true
//        erro = nil
//        defer { estaCarregando = false }
//
//        do {
//            let remotas = try await api.buscarReceitas()
//            var receitasLocais = Dictionary(
//                uniqueKeysWithValues: try context.fetch(FetchDescriptor<Receita>()).map { ($0.id, $0) }
//            )
//            var categoriasLocais = Dictionary(
//                uniqueKeysWithValues: try context.fetch(FetchDescriptor<Categoria>()).map { (chave($0.nome), $0) }
//            )
//
//            for remota in remotas {
//                let categorias = remota.categorias.map { nome -> Categoria in
//                    let id = chave(nome)
//                    if let existente = categoriasLocais[id] { return existente }
//                    let nova = Categoria(id: id, nome: nome)
//                    context.insert(nova)
//                    categoriasLocais[id] = nova
//                    return nova
//                }
//                let campos = (
//                    descricao: remota.descricao,
//                    nutricao: remota.nutricao,
//                    ingredientes: dividirIngredientes(remota.ingredientes),
//                    categorias: categorias
//                )
//
//                if let receita = receitasLocais[remota.id] {
//                    receita.titulo = remota.titulo
//                    receita.descricao = campos.descricao
//                    receita.informacaoNutricional = campos.nutricao
//                    receita.ingredientes = campos.ingredientes
//                    receita.categorias = campos.categorias
//                } else {
//                    let receita = Receita(
//                        id: remota.id,
//                        titulo: remota.titulo,
//                        descricao: campos.descricao,
//                        informacaoNutricional: campos.nutricao,
//                        ingredientes: campos.ingredientes,
//                        categorias: campos.categorias
//                    )
//                    context.insert(receita)
//                    receitasLocais[remota.id] = receita
//                }
//            }
//            try context.save()
//        } catch {
//            erro = error.localizedDescription
//        }
//    }
//
//    private func dividirIngredientes(_ texto: String) -> [String] {
//        texto.split(whereSeparator: { $0.isNewline || $0 == ";" })
//            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
//            .filter { !$0.isEmpty }
//    }
//
//    private func chave(_ texto: String) -> String {
//        texto.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
//            .trimmingCharacters(in: .whitespacesAndNewlines)
//    }
//}
