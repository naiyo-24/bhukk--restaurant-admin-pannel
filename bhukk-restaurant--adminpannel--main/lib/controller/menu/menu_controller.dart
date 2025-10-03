// controller/menu/menu_controller.dart
import 'package:get/get.dart';
import '../../models/menu/dish_model.dart';

class MenuController extends GetxController {
	var dishList = <Dish>[].obs;
	var filteredList = <Dish>[].obs;
	var viewMode = 'grid'.obs;
	var searchQuery = ''.obs;
	var selectedCategory = ''.obs;
	var sortBy = 'name'.obs;

	@override
	void onInit() {
		super.onInit();
		// Sample data
		dishList.value = [
			Dish(
				id: '1',
				name: 'Paneer Tikka',
				description: 'Spicy grilled paneer cubes',
				images: ['https://via.placeholder.com/150'],
				price: 220.0,
				category: 'Starters',
				tags: ['veg', 'spicy'],
			),
			Dish(
				id: '2',
				name: 'Chicken Biryani',
				description: 'Aromatic basmati rice with chicken',
				images: ['https://via.placeholder.com/150'],
				price: 320.0,
				category: 'Main Course',
				tags: ['non-veg', 'rice'],
			),
		];
		filteredList.value = dishList;
	}

	void addDish(Dish dish) {
		dishList.add(dish);
		filterDishes();
	}

	void editDish(String id, Dish updated) {
		final idx = dishList.indexWhere((d) => d.id == id);
		if (idx != -1) {
			dishList[idx] = updated;
			filterDishes();
		}
	}

	void deleteDish(String id) {
		dishList.removeWhere((d) => d.id == id);
		filterDishes();
	}

	void filterDishes() {
		var list = dishList;
		if (selectedCategory.value.isNotEmpty) {
			list = list.where((d) => d.category == selectedCategory.value).toList().obs;
		}
		if (searchQuery.value.isNotEmpty) {
			list = list.where((d) => d.name.toLowerCase().contains(searchQuery.value.toLowerCase())).toList().obs;
		}
		if (sortBy.value == 'price') {
			list.sort((a, b) => a.price.compareTo(b.price));
		} else {
			list.sort((a, b) => a.name.compareTo(b.name));
		}
		filteredList.value = list;
	}

	void setViewMode(String mode) {
		viewMode.value = mode;
	}

	void setCategory(String category) {
		selectedCategory.value = category;
		filterDishes();
	}

	void setSortBy(String sort) {
		sortBy.value = sort;
		filterDishes();
	}

	void setSearchQuery(String query) {
		searchQuery.value = query;
		filterDishes();
	}
}
