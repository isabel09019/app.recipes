import SwiftUI


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

        return words.allSatisfy {
            searchableText.localizedStandardContains(String($0))
        }
    }
}


enum SampleRecipes {
    static let all: [Recipe] = []
}


private enum Palette {
    static let background = Color.white
    static let paper = Color(red: 0.95, green: 0.95, blue: 0.97)
    static let orange = Color(red: 1.0, green: 0.53, blue: 0.12)
    static let paleOrange = Color(red: 1.0, green: 0.93, blue: 0.87)
    static let ink = Color.black
    static let muted = Color.gray
}


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


struct RecipeHome: View {

    @State private var selectedTab = 0
    @State private var selectedCategory: String? = nil
    @State private var searchText = ""

    @AppStorage("recipe.favoriteIDs")
    private var storedFavorites = "[]"

    private let recipes = SampleRecipes.all

    private let categories = [
        "Café da manhã",
        "Almoço",
        "Lanche",
        "Jantar",
        "Sobremesa",
        "Vegana",
        "Vegetariana"
    ]

    private var filteredRecipes: [Recipe] {
        recipes.filter { recipe in
            let matchesCategory = selectedCategory == nil || recipe.subtitle == selectedCategory
            let matchesQuery = recipe.matches(searchText)
            return matchesCategory && matchesQuery
        }
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                catalogScreen
            }
            .tabItem {
                Label("Catálogo", systemImage: "book.closed.fill")
            }
            .tag(0)

            NavigationStack {
                favoritesScreen
            }
            .tabItem {
                Label("Favoritos", systemImage: "heart.fill")
            }
            .tag(1)
        }
        .tint(Palette.orange)
    }


    private var catalogScreen: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                Text("Categorias")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 12)

               
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(categories, id: \.self) { category in
                            let isSelected = selectedCategory == category

                            Button {
                                withAnimation(.snappy) {
                                    selectedCategory = isSelected ? nil : category
                                }
                            } label: {
                                Text(category)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(isSelected ? .white : Palette.orange)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 11)
                                    .background(
                                        isSelected ? Palette.orange : Palette.paleOrange,
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .scrollClipDisabled()
                .padding(.top, 14)

                Text(selectedCategory ?? "Receitas")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(Palette.ink)
                    .padding(.top, 28)

                if filteredRecipes.isEmpty {
                    let isSearching = !searchText.trimmingCharacters(in: .whitespaces).isEmpty

                    emptyState(
                        title: isSearching ? "Nenhum resultado encontrado" : "Nenhuma receita cadastrada",
                        message: isSearching
                            ? "Tente buscar por outro nome ou ingrediente."
                            : "As receitas aparecerão aqui quando forem adicionadas.",
                        icon: isSearching ? "magnifyingglass" : "book.closed"
                    )
                    .padding(.top, 16)
                } else {
                    ForEach(filteredRecipes) { recipe in
                        recipeCard(recipe)
                            .padding(.top, 16)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background)
        .navigationTitle("Catálogo")
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Buscar receitas ou ingredientes"
        )
    }

 
    private var favoritesScreen: some View {
        let ids = FavoriteRecipes.decode(storedFavorites)
        let favorites = recipes.filter { ids.contains($0.id) }

        return ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {

                if favorites.isEmpty {
                    emptyState(
                        title: "Nenhum favorito salvo",
                        message: "Suas receitas favoritas aparecerão aqui.",
                        icon: "heart"
                    )
                    .padding(.top, 16)
                } else {
                    ForEach(favorites) { recipe in
                        recipeCard(recipe)
                            .padding(.top, 16)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.background)
        .navigationTitle("Favoritos")
    }

    
    private func recipeCard(_ recipe: Recipe) -> some View {
        HStack(spacing: 15) {
            Image(systemName: recipe.icon)
                .font(.system(size: 24))
                .foregroundStyle(Palette.orange)
                .frame(width: 60, height: 60)
                .background(
                    Palette.paleOrange,
                    in: RoundedRectangle(cornerRadius: 16)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Palette.ink)

                Text("\(recipe.subtitle) • \(recipe.minutes) min")
                    .font(.system(size: 15))
                    .foregroundStyle(Palette.muted)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(Palette.muted)
        }
        .padding(16)
        .background(
            Palette.paper,
            in: RoundedRectangle(cornerRadius: 22)
        )
    }

    
    private func emptyState(
        title: String,
        message: String,
        icon: String
    ) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(Palette.orange)

            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Palette.ink)

            Text(message)
                .font(.system(size: 15))
                .foregroundStyle(Palette.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 42)
        .padding(.horizontal, 20)
        .background(
            Palette.paper,
            in: RoundedRectangle(cornerRadius: 22)
        )
    }
}

#Preview {
    RecipeHome()
}
