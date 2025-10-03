// screens/menu/menu_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controller/menu/menu_controller.dart' as menu;
import '../../widgets/main_scaffold.dart';
import 'package:bhukk_resturant_admin/cards/menu/filter_bar.dart';
import 'package:bhukk_resturant_admin/cards/menu/dish_card.dart';
import 'package:bhukk_resturant_admin/cards/menu/dish_form.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final menu.MenuController controller = Get.find<menu.MenuController>();

    return MainScaffold(
      title: '',
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Dish'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => Dialog(child: DishForm()),
          );
        },
      ),
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).size.width >= 1200 ? 8 : 12, 16, 12),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox.shrink(),
                      Obx(() {
                        final isGrid = controller.viewMode.value == 'grid';
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [BoxShadow(color: Colors.black.withAlpha((0.04 * 255).toInt()), blurRadius: 6)],
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () => controller.setViewMode('grid'),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isGrid ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Icon(Icons.grid_view, color: isGrid ? Colors.white : Colors.black54),
                                ),
                              ),
                              InkWell(
                                onTap: () => controller.setViewMode('list'),
                                borderRadius: BorderRadius.circular(24),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: !isGrid ? Theme.of(context).colorScheme.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                  child: Icon(Icons.list, color: !isGrid ? Colors.white : Colors.black54),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.width >= 1200 ? 8 : 12),
                  const FilterBar(),
                  SizedBox(height: MediaQuery.of(context).size.width >= 1200 ? 12 : 14),

                  Obx(() {
                    final dishes = controller.filteredList;
                    if (dishes.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 48),
                          child: Text('No dishes found.'),
                        ),
                      );
                    }

                    final isGrid = controller.viewMode.value == 'grid';

                    return AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child)),
                      child: LayoutBuilder(
                        key: ValueKey(controller.viewMode.value),
                        builder: (context, constraints) {
                          int columns;
                          final width = constraints.maxWidth;
                          if (!isGrid) {
                            columns = 1;
                          } else if (width >= 1200) {
                            columns = 4;
                          } else if (width >= 900) {
                            columns = 3;
                          } else if (width >= 600) {
                            columns = 2;
                          } else {
                            columns = 1;
                          }

                          if (isGrid) {
                            double tileHeight;
                            if (columns <= 1) {
                              tileHeight = 326;
                            } else if (columns == 2) {
                              tileHeight = 326;
                            } else if (columns == 3) {
                              tileHeight = 306;
                            } else {
                              tileHeight = 266;
                            }

                            return GridView.builder(
                              key: const ValueKey('grid'),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                mainAxisExtent: tileHeight,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: dishes.length,
                              itemBuilder: (context, i) => DishCard(dish: dishes[i]),
                            );
                          }

                          return ListView.separated(
                            key: const ValueKey('list'),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: dishes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 14),
                            itemBuilder: (context, i) => DishCard(dish: dishes[i]),
                          );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

