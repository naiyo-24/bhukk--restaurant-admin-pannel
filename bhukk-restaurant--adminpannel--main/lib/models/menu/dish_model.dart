// models/menu/dish_model.dart
class Dish {
	final String id;
	final String name;
	final String description;
	final List<String> images;
	final double price;
	final String category;
	final List<String> tags;

	Dish({
		required this.id,
		required this.name,
		required this.description,
		required this.images,
		required this.price,
		required this.category,
		required this.tags,
	});
}
