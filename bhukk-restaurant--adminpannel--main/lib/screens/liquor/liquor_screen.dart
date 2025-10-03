// screens/liquor/liquor_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:convert';
import '../../controller/common/file_picker_controller.dart';
import '../../widgets/main_scaffold.dart';
import '../../theme/app_theme.dart';
import '../../controller/liquor/liquor_controller.dart';
import '../../models/liquor_model.dart';

class LiquorScreen extends StatelessWidget {
  const LiquorScreen({super.key});

  @override
  Widget build(BuildContext context) {
  // Controller is provided by the route binding; find the instance here
  final controller = Get.find<LiquorController>();

    return MainScaffold(
      title: 'Liquor',
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.cherryRed,
        onPressed: () => _openForm(context, controller),
        icon: const Icon(Icons.add),
        label: const Text('Add Liquor'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Obx(() {
                final list = controller.liquors;
                if (list.isEmpty) return const Center(child: Text('No liquors yet'));

                return LayoutBuilder(builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          // denser layout: more columns on wider screens
          final cols = w > 1200 ? 4 : (w > 900 ? 3 : (w > 600 ? 2 : 1));
                  return GridView.builder(
                    itemCount: list.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            // slightly squarer cards to fit more items
            childAspectRatio: 0.95,
                    ),
                      itemBuilder: (c, i) => LiquorCard(
                        key: ValueKey(list[i].id),
                        model: list[i],
                        controller: controller,
                        onEdit: (m) => _openForm(context, controller, existing: m),
                        onDelete: (id) => controller.deleteLiquor(id),
                      ),
                  );
                });
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _openForm(BuildContext context, LiquorController controller, {LiquorModel? existing}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: LiquorForm(existing: existing, controller: controller),
        ),
      ),
    );
  }
}

class LiquorCard extends StatelessWidget {
  final LiquorModel model;
  final LiquorController controller;
  final void Function(LiquorModel) onEdit;
  final void Function(String) onDelete;

  const LiquorCard({super.key, required this.model, required this.controller, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    Widget buildImage(String? url) {
      const imgSize = 56.0;
      if (url == null || url.trim().isEmpty) {
        return Container(width: imgSize, height: imgSize, color: Colors.grey.shade200, child: const Icon(Icons.local_bar, size: 32, color: Colors.grey));
      }

      final trimmed = url.trim();
      if (trimmed.startsWith('data:image')) {
        try {
          final comma = trimmed.indexOf(',');
          final base64Part = (comma >= 0) ? trimmed.substring(comma + 1) : trimmed.split(',').last;
          final bytes = base64Decode(base64Part);
          return Image.memory(bytes, width: imgSize, height: imgSize, fit: BoxFit.cover);
        } catch (_) {
          return Container(width: imgSize, height: imgSize, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, size: 28));
        }
      }

      if (trimmed.startsWith('http')) {
        return Image.network(
          trimmed,
          width: imgSize,
          height: imgSize,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(width: imgSize, height: imgSize, color: Colors.grey.shade200, child: const Icon(Icons.broken_image, size: 28)),
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return Container(width: imgSize, height: imgSize, alignment: Alignment.center, child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes ?? 1) : null));
          },
        );
      }

      // fallback: show placeholder
      return Container(width: imgSize, height: imgSize, color: Colors.grey.shade200, child: const Icon(Icons.local_bar, size: 32, color: Colors.grey));
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: buildImage(model.imageUrl)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(model.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text(model.type, style: TextStyle(color: Colors.grey[700])),
                      const SizedBox(height: 6),
                      Text('\$${model.price.toStringAsFixed(2)} • ${model.volumeMl} ml', style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Obx(() {
                  // Resolve availability from controller by id; fall back to model.available
                  final idx = controller.liquors.indexWhere((e) => e.id == model.id);
                  final avail = idx >= 0 ? controller.liquors[idx].available : model.available;
                  return Switch(
                    key: ValueKey('switch-${model.id}'),
                    value: avail,
                    onChanged: (v) => controller.setAvailability(model.id, v),
                    activeThumbColor: AppTheme.cherryRed,
                  );
                }),
              ],
            ),
            const SizedBox(height: 8),
            // make description take remaining space to avoid overflow
            Flexible(
              child: Text('Age: ${model.age} • Stock: ${model.quantity} • ${model.description}', maxLines: 4, overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => onEdit(model), child: const Text('Edit')),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                      title: const Text('Delete Liquor'),
                      content: Text('Delete "${model.name}"?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                        ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                      ],
                    ));
                    if (ok == true) onDelete(model.id);
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class LiquorForm extends StatefulWidget {
  final LiquorModel? existing;
  final LiquorController controller;
  const LiquorForm({super.key, this.existing, required this.controller});

  @override
  State<LiquorForm> createState() => _LiquorFormState();
}

class _LiquorFormState extends State<LiquorForm> {
  final _formKey = GlobalKey<FormState>();
  late String name;
  String type = 'Beer';
  String age = '18+';
  double price = 0.0;
  String? imageUrl;
  String description = '';
  late TextEditingController _imageCtr;
  int volumeMl = 750;
  int quantity = 0;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      name = e.name;
      type = e.type;
      age = e.age;
      price = e.price;
      imageUrl = e.imageUrl;
      description = e.description;
  volumeMl = e.volumeMl;
  quantity = e.quantity;
    } else {
      name = '';
    }
    _imageCtr = TextEditingController(text: imageUrl ?? '');
  }

  @override
  void dispose() {
    _imageCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 520,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.existing == null ? 'Add Liquor' : 'Edit Liquor', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
              onSaved: (v) => name = v!.trim(),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: type,
              items: ['Beer', 'Whiskey', 'Vodka', 'Wine', 'Others'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => type = v ?? 'Beer'),
              decoration: const InputDecoration(labelText: 'Type'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: age,
              items: ['18+', '21+'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (v) => setState(() => age = v ?? '18+'),
              decoration: const InputDecoration(labelText: 'Age Restriction'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: price == 0.0 ? '' : price.toString(),
              decoration: const InputDecoration(labelText: 'Price', prefixText: '\$'),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter a number' : null,
              onSaved: (v) => price = double.tryParse(v!) ?? 0.0,
            ),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: TextFormField(
                  initialValue: volumeMl == 0 ? '' : volumeMl.toString(),
                  decoration: const InputDecoration(labelText: 'Volume (ml)'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n <= 0) return 'Enter ml';
                    return null;
                  },
                  onSaved: (v) => volumeMl = int.tryParse(v ?? '') ?? 750,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: quantity.toString(),
                  decoration: const InputDecoration(labelText: 'Quantity in stock'),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    if (n == null || n < 0) return 'Enter qty';
                    return null;
                  },
                  onSaved: (v) => quantity = int.tryParse(v ?? '') ?? 0,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            // image placeholder picker
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                          controller: _imageCtr,
                          decoration: const InputDecoration(labelText: 'Image URL (or base64)'),
                          onSaved: (v) => imageUrl = v?.trim(),
                        ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(onPressed: _pickFile, child: const Text('Pick')),
                  ],
                ),
                const SizedBox(height: 8),
                if (imageUrl != null && imageUrl!.isNotEmpty)
                  Align(alignment: Alignment.centerLeft, child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _previewImage(imageUrl))),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
              onSaved: (v) => description = v ?? '',
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (widget.existing == null) {
      final id = DateTime.now().millisecondsSinceEpoch.toString();
  final item = LiquorModel(id: id, name: name, type: type, price: price, age: age, imageUrl: imageUrl, description: description, available: true, volumeMl: volumeMl, quantity: quantity);
      widget.controller.addLiquor(item);
    } else {
  final updated = widget.existing!.copyWith(name: name, type: type, price: price, age: age, imageUrl: imageUrl, description: description, volumeMl: volumeMl, quantity: quantity);
      widget.controller.editLiquor(widget.existing!.id, updated);
    }

    Navigator.of(context).pop();
  }

  Future<void> _pickFile() async {
    if (!Get.isRegistered<FilePickerController>()) Get.put(FilePickerController());
    final f = await FilePickerController.to.pickImage();
    if (f == null) return;
    final dataUrl = await FilePickerController.to.toDataUrl(f);
    setState(() {
      if (dataUrl != null) {
        imageUrl = dataUrl;
        _imageCtr.text = dataUrl;
      } else if (f.path.isNotEmpty) {
        imageUrl = f.path;
        _imageCtr.text = f.path;
      }
    });
  }

  Widget _previewImage(String? url) {
    if (url == null || url.trim().isEmpty) return const SizedBox.shrink();
    final trimmed = url.trim();
    if (trimmed.startsWith('data:image')) {
      try {
        final comma = trimmed.indexOf(',');
        final base64Part = (comma >= 0) ? trimmed.substring(comma + 1) : trimmed.split(',').last;
        final bytes = base64Decode(base64Part);
        return Image.memory(bytes, width: 120, height: 80, fit: BoxFit.cover);
      } catch (_) {
        return Container(width: 120, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.broken_image));
      }
    }
    if (trimmed.startsWith('http')) {
      return Image.network(trimmed, width: 120, height: 80, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(width: 120, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.broken_image)));
    }
    return Container(width: 120, height: 80, color: Colors.grey.shade200, child: const Icon(Icons.broken_image));
  }
}
