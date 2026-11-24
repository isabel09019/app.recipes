import Foundation
import SwiftData

@Model
final class Categoria {
    @Attribute(.unique) var id: String
    var nome: String
    var icone: String

    @Relationship(deleteRule: .nullify, inverse: \Receita.categorias)
    var receitas: [Receita] = []

    init(id: String, nome: String, icone: String = "fork.knife") {
        self.id = id
        self.nome = nome
        self.icone = icone
    }
}
