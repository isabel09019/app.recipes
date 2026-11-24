import Foundation
import SwiftData

@Model
final class Receita {
    @Attribute(.unique) var id: String
    var titulo: String
    var imagemURL: String
    var tempoPreparo: Int
    var calorias: Int
    var ingredientes: [String]
    var passosPreparo: [String]
    var isSalvo: Bool
    
    var categoria: Categoria?
    
    init(
        id: String,
        titulo: String,
        imagemURL: String,
        tempoPreparo: Int,
        calorias: Int,
        ingredientes: [String],
        passosPreparo: [String],
        isSalvo: Bool = false,
        categoria: Categoria? = nil
    ) {
        self.id = id
        self.titulo = titulo
        self.imagemURL = imagemURL
        self.tempoPreparo = tempoPreparo
        self.calorias = calorias
        self.ingredientes = ingredientes
        self.passosPreparo = passosPreparo
        self.isSalvo = isSalvo
        self.categoria = categoria
    }
}

