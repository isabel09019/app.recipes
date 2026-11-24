import SwiftUI

// MARK: - Modelos e Dados
struct Recipe: Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let minutes: Int
    let servings: Int
    let ingredients: [String]
    let steps: [String]
    let icon: String
    var photoAsset: String? = nil

    func matches(_ query: String) -> Bool {
        let words = query.split(whereSeparator: { $0.isWhitespace })
        if words.isEmpty { return true }
        let searchableText = ([name, subtitle] + ingredients).joined(separator: " ")
        return words.allSatisfy { searchableText.localizedStandardContains(String($0)) }
    }
}

enum SampleRecipes {
    static let all: [Recipe] = [
        Recipe(
            id: "pao-com-ovo",
            name: "Pão com ovo",
            subtitle: "Café da manhã",
            minutes: 10,
            servings: 1,
            ingredients: [
                "1 fatia de pão integral",
                "1 ovo",
                "1 colher de chá de azeite",
                "Sal e pimenta a gosto"
            ],
            steps: [
                "Toste o pão integral dos dois lados até ficar crocante.",
                "Aqueça o azeite na frigideira. Quebre o ovo e cozinhe até a clara e a gema firmarem.",
                "Coloque o ovo sobre o pão e finalize com sal e pimenta."
            ],
            icon: "frying.pan",
            photoAsset: "PaoComOvo"
        ),
        Recipe(
            id: "iogurte-com-banana",
            name: "Iogurte com banana",
            subtitle: "Lanche",
            minutes: 5,
            servings: 1,
            ingredients: [
                "1 pote de iogurte natural",
                "1 banana",
                "2 colheres de sopa de aveia"
            ],
            steps: [
                "Corte a banana em rodelas.",
                "Coloque o iogurte em uma tigela e sirva com a banana e a aveia."
            ],
            icon: "carrot"
        ),
        Recipe(
            id: "salada-de-grao-de-bico",
            name: "Salada de grão-de-bico",
            subtitle: "Almoço",
            minutes: 15,
            servings: 2,
            ingredients: [
                "1 xícara de grão-de-bico cozido",
                "1 tomate",
                "½ pepino",
                "Azeite e limão a gosto"
            ],
            steps: [
                "Pique o tomate e o pepino.",
                "Misture com o grão-de-bico e tempere com azeite e limão."
            ],
            icon: "leaf"
        )
    ]
}

// MARK: - Paleta de Cores
private enum Palette {
    static let background = Color(red: 0.93, green: 0.96, blue: 0.88)
    static let paper = Color(red: 1, green: 0.99, blue: 0.96)
    static let orange = Color(red: 0.72, green: 0.24, blue: 0.08)
    static let paleOrange = Color(red: 1, green: 0.91, blue: 0.83)
    static let ink = Color(red: 0.15, green: 0.20, blue: 0.12)
    static let muted = Color(red: 0.34, green: 0.39, blue: 0.29)
}

// MARK: - Gerenciador de Favoritos
private enum FavoriteRecipes {
    static func decode(_ raw: String) -> Set<String> {
        guard let data = raw.data(using: .utf8),
              let array = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(array)
    }

    static func toggle(_ id: String, in raw: inout String) {
        var current = decode(raw)
        if current.contains(id) {
            current.remove(id)
        } else {
            current.insert(id)
        }
        if let data = try? JSONEncoder().encode(Array(current)),
           let encoded = String(data: data, encoding: .utf8) {
            raw = encoded
        }
    }
}

// MARK: - Tela Principal (Abas)
struct RecipeHome: View {
    private let recipes = SampleRecipes.all
    @State private var query = ""
    @AppStorage("recipe.favoriteIDs") private var storedFavorites = "[]"

    private var isSearching: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        TabView {
            NavigationStack {
                searchScreen
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Pesquisa", systemImage: "magnifyingglass") }

            NavigationStack {
                favoritesScreen
                    .toolbar(.hidden, for: .navigationBar)
            }
            .tabItem { Label("Favoritos", systemImage: "heart") }
        }
        .tint(Palette.orange)
    }

    // MARK: Tela de Pesquisa
    private var searchScreen: some View {
        let results = recipes.filter { $0.matches(query) }

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Recipe")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(Palette.orange)

                HStack(spacing: 12) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Palette.orange)
                    TextField("Receita ou ingrediente", text: $query)
                        .submitLabel(.search)
                    if !query.isEmpty {
                        Button { query = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Palette.muted)
                        }
                    }
                }
                .frame(minHeight: 52)
                .padding(.horizontal, 14)
                .background(Palette.paper, in: RoundedRectangle(cornerRadius: 14))

                Text(isSearching ? "Resultados" : "Receitas")
                    .font(.system(.title2, design: .serif).weight(.semibold))

                if results.isEmpty {
                    emptyState(
                        "Nenhuma receita encontrada",
                        "Tente buscar outro nome ou ingrediente.",
                        icon: "magnifyingglass"
                    )
                } else {
                    ForEach(results) { recipe in
                        recipeLink(recipe, featured: !isSearching && recipe.id == recipes.first?.id)
                    }
                }
            }
            .padding(22)
        }
        .scrollDismissesKeyboard(.interactively)
        .foregroundStyle(Palette.ink)
        .background(Palette.background.ignoresSafeArea())
    }

    // MARK: Tela de Favoritos
    private var favoritesScreen: some View {
        let ids = FavoriteRecipes.decode(storedFavorites)
        let favorites = recipes.filter { ids.contains($0.id) }

        return ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("Favoritos")
                    .font(.system(.largeTitle, design: .serif).weight(.bold))
                    .foregroundStyle(Palette.orange)

                if favorites.isEmpty {
                    emptyState(
                        "Nenhuma receita salva",
                        "Toque no coração de uma receita para encontrá-la aqui.",
                        icon: "heart"
                    )
                } else {
                    ForEach(favorites) { recipe in
                        recipeLink(recipe)
                    }
                }
            }
            .padding(22)
        }
        .foregroundStyle(Palette.ink)
        .background(Palette.background.ignoresSafeArea())
    }

    // MARK: Componentes Visuais
    private func recipeLink(_ recipe: Recipe, featured: Bool = false) -> some View {
        NavigationLink {
            RecipeDetail(recipe: recipe, storedFavorites: $storedFavorites)
        } label: {
            if featured {
                VStack(spacing: 0) {
                    RecipePhoto(recipe: recipe, height: 192)
                    recipeCaption(recipe)
                        .padding(16)
                }
                .background(Palette.paper, in: RoundedRectangle(cornerRadius: 18))
                .clipShape(RoundedRectangle(cornerRadius: 18))
            } else {
                HStack(spacing: 14) {
                    Image(systemName: recipe.icon)
                        .font(.title2)
                        .foregroundStyle(Palette.orange)
                        .frame(width: 52, height: 52)
                        .background(Palette.paleOrange, in: RoundedRectangle(cornerRadius: 12))

                    recipeCaption(recipe)
                }
                .padding(14)
                .background(Palette.paper, in: RoundedRectangle(cornerRadius: 16))
            }
        }
        .buttonStyle(.plain)
    }

    private func recipeCaption(_ recipe: Recipe) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.subtitle.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Palette.orange)
                Text(recipe.name)
                    .font(.system(.headline, design: .serif))
                    .foregroundStyle(Palette.ink)
                Text("\(recipe.minutes) min • \(recipe.servings) \(recipe.servings == 1 ? "porção" : "porções")")
                    .font(.subheadline)
                    .foregroundStyle(Palette.muted)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(Palette.muted)
        }
    }

    private func emptyState(_ title: String, _ message: String, icon: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundStyle(Palette.orange)
            Text(title)
                .font(.system(.headline, design: .serif))
            Text(message)
                .font(.subheadline)
