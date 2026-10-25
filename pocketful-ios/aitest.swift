import Playgrounds
import FoundationModels

@Generable()
struct Recipe {
    @Guide(description: "The name of the recipe.")
    let name: String
    @Guide(description: "The description of the recipe.")
    let description: String
    @Guide(description: "The prep time in minutes.", .range(0...20))
    let prepTimeMinutes: Int
    @Guide(description: "List of ingredients for the recipe.")
    let ingredients: [Ingredient]
}

@Generable()
struct Ingredient {
    @Guide(description: "The name of the ingredient.")
    let name: String

    @Guide(description: "The quantity of the ingredient.")
    let quantity: Double

    @Guide(description: "The unit of measurement for the quantity (e.g., grams, tablespoons, cups).")
    let unit: Unit
}

@Generable()
enum Unit: String, Codable {
    case grams
    case kilograms
    case milliliters
    case liters
    case teaspoons
    case tablespoons
    case cups
    case pieces
    case cloves
    case slices
    case pinch
}

#Playground {
    
    let session = LanguageModelSession()
    let response = try await session.respond(to: "Suggest a tradional Pakistani recipe", generating: Recipe.self)
    
    // response.content is of type Recipe
    print(response.content)
    print(response.content.name) // name of the recipe
    print(response.content.description) // description of the recipe
    print(response.content.prepTimeMinutes)
    
    for ingredient in response.content.ingredients {
        print(ingredient.name)
        print(ingredient.quantity)
        print(ingredient.unit)
    }
}
