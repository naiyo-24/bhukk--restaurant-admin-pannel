// screens/menu/widgets/dish_card.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/menu/dish_model.dart';
import '../../../controller/menu/menu_controller.dart' as menu;
import 'dish_form.dart';

class DishCard extends StatelessWidget {
  final Dish dish;
  const DishCard({super.key, required this.dish});

  @override
  Widget build(BuildContext context) {
  final controller = Get.find<menu.MenuController>();
    // helper: modern styled delete confirmation dialog
    Future<void> confirmDelete(BuildContext ctx) async {
      final confirmed = await showDialog<bool>(
        context: ctx,
        barrierDismissible: true,
        builder: (dctx) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 6,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(color: Theme.of(ctx).colorScheme.error.withAlpha((0.08 * 255).toInt()), shape: BoxShape.circle),
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.delete_outline, color: Theme.of(ctx).colorScheme.error, size: 22),
                    ),
                    const SizedBox(height: 10),
                    Text('Delete dish', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(ctx).textTheme.bodyLarge?.color)),
                    const SizedBox(height: 6),
                    Text('Are you sure you want to delete "${dish.name}"? This action cannot be undone.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Theme.of(ctx).textTheme.bodyMedium?.color)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), minimumSize: const Size(64, 36)),
                          onPressed: () => Navigator.of(dctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), minimumSize: const Size(76, 36), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          onPressed: () => Navigator.of(dctx).pop(true),
                          child: const Text('Delete', style: TextStyle(color: Colors.white, fontSize: 14)),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          );
        },
      );

      if (confirmed == true) {
        controller.deleteDish(dish.id);
      }
    }
    return LayoutBuilder(builder: (context, constraints) {
      // consider a card 'narrow' at a slightly larger width to prevent image clipping in grid tiles
      final narrow = constraints.maxWidth < 420;
      // available height (fallback if infinite)
      final availableHeight = constraints.maxHeight.isFinite ? constraints.maxHeight : 320.0;
      // compute image sizes but keep them modest so the card body (tags/text) remains visible
      // top image should be prominent but not overpower the card; side image smaller for compact cards
      final imageTopHeight = (availableHeight * 0.45).clamp(90.0, 140.0);
      final imageSideSize = (availableHeight * 0.33).clamp(64.0, 120.0);

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 6.0),
    child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {},
            child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
              child: narrow
                  ? SizedBox(
          // constrain the vertical column to the available card height to avoid overflow
          height: (availableHeight - 12).clamp(160.0, availableHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                        // image on top
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: dish.images.isNotEmpty
                              ? Image.network(dish.images.first, width: double.infinity, height: imageTopHeight, fit: BoxFit.cover,
                                  errorBuilder: (context, _, __) => Container(height: imageTopHeight, color: Colors.grey[200], child: const Icon(Icons.broken_image)))
                              : Container(height: imageTopHeight, color: Colors.grey[200], child: const Icon(Icons.image)),
                        ),
        const SizedBox(height: 8),
        Text(dish.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Row(children: [Text(dish.category, style: TextStyle(color: Theme.of(context).colorScheme.primary)), const SizedBox(width: 8), Text('₹${dish.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600))]),
        const SizedBox(height: 6),
                        // Ensure tags don't push card beyond available space: use Expanded so tags wrap inside remaining space
                        Expanded(
                          child: Align(
                            alignment: Alignment.topLeft,
            child: Wrap(spacing: 8, runSpacing: 6, children: dish.tags.map((t) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Text(t, style: const TextStyle(fontSize: 11)))).toList()),
                          ),
                        ),
        const SizedBox(height: 6),
                        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                          PopupMenuButton<String>(
                            onSelected: (v) {
                              if (v == 'edit') {
                                showDialog(
                                  context: context,
                                  builder: (_) => Dialog(
                                        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        child: ConstrainedBox(
                                          constraints: const BoxConstraints(maxWidth: 560),
                                          child: DishForm(editDish: dish),
                                        ),
                                      ));
                              }
                              if (v == 'delete') confirmDelete(context);
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          )
                        ])
                      ],
                    )
                  )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dish image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: dish.images.isNotEmpty
                              ? Image.network(dish.images.first, width: imageSideSize, height: imageSideSize, fit: BoxFit.cover,
                                  errorBuilder: (context, _, __) => Container(width: imageSideSize, height: imageSideSize, color: Colors.grey[200], child: const Icon(Icons.broken_image)))
                              : Container(width: imageSideSize, height: imageSideSize, color: Colors.grey[200], child: const Icon(Icons.image)),
                        ),
        const SizedBox(width: 10),
                        // Dish info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
          Text(dish.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(dish.category, style: TextStyle(color: Theme.of(context).colorScheme.primary)),
          const SizedBox(height: 6),
          Text('₹${dish.price.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
                              // Make tags wrap but not increase height excessively
          Wrap(spacing: 8, runSpacing: 6, children: dish.tags.map((t) => Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4), decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)), child: Text(t, style: const TextStyle(fontSize: 11)))).toList()),
                            ],
                          ),
                        ),
                        // compact actions aligned to top-right
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (v) async {
                                if (v == 'edit') {
                                  showDialog(
                                    context: context,
                                    builder: (_) => Dialog(
                                          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                          child: ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 560),
                                            child: DishForm(editDish: dish),
                                          ),
                                        ));
                                }
                                if (v == 'delete') await confirmDelete(context);
                              },
                              itemBuilder: (_) => [
                                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                const PopupMenuItem(value: 'delete', child: Text('Delete')),
                              ],
                            )
                          ],
                        )
                      ],
                    ),
            ),
          ),
        ),
      );
    });
  }
}
