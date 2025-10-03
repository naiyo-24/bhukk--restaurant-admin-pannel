// screens/menu/widgets/filter_bar.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../controller/menu/menu_controller.dart' as menu;

class FilterBar extends StatelessWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context) {
  final controller = Get.find<menu.MenuController>();
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 700;
      return Wrap(
        runSpacing: 10,
        spacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Category dropdown with modern style
          SizedBox(
            width: isNarrow ? constraints.maxWidth : 180,
            child: Obx(() => DropdownButtonFormField<String>(
                  initialValue: controller.selectedCategory.value.isEmpty ? null : controller.selectedCategory.value,
                  hint: const Text('Category'),
                  items: ['Starters', 'Main Course', 'Desserts', 'Drinks']
                      .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                      .toList(),
                  onChanged: (val) => controller.setCategory(val ?? ''),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )),
          ),

          // Sort dropdown
          SizedBox(
            width: isNarrow ? (constraints.maxWidth / 2 - 20) : 160,
            child: Obx(() => DropdownButtonFormField<String>(
                  initialValue: controller.sortBy.value,
                  items: ['name', 'price']
                      .map((sort) => DropdownMenuItem(value: sort, child: Text('Sort by ${sort[0].toUpperCase()}${sort.substring(1)}')))
                      .toList(),
                  onChanged: (val) => controller.setSortBy(val ?? 'name'),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                )),
          ),

          // Search field - expands on wide screens
          SizedBox(
            width: isNarrow ? constraints.maxWidth : 360,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search dishes...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onChanged: controller.setSearchQuery,
            ),
          ),
        ],
      );
    });
  }
}
