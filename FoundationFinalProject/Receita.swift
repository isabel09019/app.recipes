import Foundation
import SwiftData

@Model
final class Receita {
    @Attribute(.unique) var id: String
    var titulo: String
    var descricao: String
    var informacaoNutricional: String
    var imagemURL: String?
    var tempoPreparo: Int?
    var porcoes: Int?
    var calorias: Int?
    var ingredientes: [String]
    var passosPreparo: [String]
    var isSalvo: Bool

    var categorias: [Categoria] = []

    init(
        id: String,
        titulo: String,
        descricao: String = "",
        informacaoNutricional: String = "",
        imagemURL: String? = nil,
        tempoPreparo: Int? = nil,
        porcoes: Int? = nil,
        calorias: Int? = nil,
        ingredientes: [String] = [],
        passosPreparo: [String] = [],
        isSalvo: Bool = false,
        categorias: [Categoria] = []
    ) {
        self.id = id
        self.titulo = titulo
        self.descricao = descricao
        self.informacaoNutricional = informacaoNutricional
        self.imagemURL = imagemURL
        self.tempoPreparo = tempoPreparo
        self.porcoes = porcoes
        self.calorias = calorias
        self.ingredientes = ingredientes
        self.passosPreparo = passosPreparo
        self.isSalvo = isSalvo
        self.categorias = categorias
    }
}
