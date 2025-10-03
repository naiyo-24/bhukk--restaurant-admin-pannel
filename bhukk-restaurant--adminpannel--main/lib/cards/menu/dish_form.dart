// cards/menu/dish_form.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../models/menu/dish_model.dart';
import '../../../controller/menu/menu_controller.dart' as menu;
import '../../../controller/common/file_picker_controller.dart';

class DishForm extends StatefulWidget {
  final Dish? editDish;
  const DishForm({super.key, this.editDish});

  @override
  State<DishForm> createState() => _DishFormState();
}

class _DishFormState extends State<DishForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController nameController;
  late TextEditingController descController;
  late TextEditingController priceController;
  late TextEditingController tagsController;
  String category = '';
  List<String> images = [];
  List<String> tags = [];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.editDish?.name ?? '');
    descController = TextEditingController(text: widget.editDish?.description ?? '');
    priceController = TextEditingController(text: widget.editDish?.price.toString() ?? '');
    tagsController = TextEditingController(text: widget.editDish?.tags.join(', ') ?? '');
    category = widget.editDish?.category ?? '';
    images = widget.editDish?.images ?? [];
    tags = widget.editDish?.tags ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<menu.MenuController>();
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(child: Text(widget.editDish == null ? 'Add Dish' : 'Edit Dish', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700))),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close)),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: nameController,
                decoration: _inputDecoration('Name'),
                validator: (v) => v == null || v.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: descController,
                decoration: _inputDecoration('Description'),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Enter description' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: priceController,
                      decoration: _inputDecoration('Price'),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || double.tryParse(v) == null ? 'Enter valid price' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: category.isEmpty ? null : category,
                      decoration: _inputDecoration('Category'),
                      items: ['Starters', 'Main Course', 'Desserts', 'Drinks']
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (val) => setState(() => category = val ?? ''),
                      validator: (v) => v == null || v.isEmpty ? 'Select category' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: tagsController,
                decoration: _inputDecoration('Tags (comma separated)'),
                onChanged: (v) => setState(() => tags = v.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.image),
                    label: const Text('Add Image'),
                    onPressed: () async {
                      if (!Get.isRegistered<FilePickerController>()) Get.put(FilePickerController());
                      final xf = await FilePickerController.to.pickImage();
                      if (xf == null) return;
                      final dataUrl = await FilePickerController.to.toDataUrl(xf);
                      if (dataUrl != null) {
                        setState(() => images.add(dataUrl));
                        return;
                      }
                      // fallback to native path where available
                      if (xf.path.isNotEmpty) {
                        setState(() => images.add(xf.path));
                        return;
                      }
                      // fallback placeholder
                      setState(() => images.add('https://via.placeholder.com/150'));
                    },
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: images.map((img) => Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Stack(
                              alignment: Alignment.topRight,
                              children: [
                                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(img, width: 56, height: 56, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(width: 56, height: 56, color: Colors.grey[200], child: const Icon(Icons.broken_image, size: 18)))),
                                Positioned(
                                  right: -6,
                                  top: -6,
                                  child: IconButton(
                                    iconSize: 16,
                                    padding: EdgeInsets.zero,
                                    color: Theme.of(context).colorScheme.error,
                                    onPressed: () => setState(() => images.remove(img)),
                                    icon: const Icon(Icons.close),
                                  ),
                                )
                              ],
                            ),
                          )).toList()),
                    ),
                  )
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        final dish = Dish(
                          id: widget.editDish?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
                          name: nameController.text,
                          description: descController.text,
                          images: images,
                          price: double.parse(priceController.text),
                          category: category,
                          tags: tags,
                        );
                        if (widget.editDish == null) {
                          controller.addDish(dish);
                        } else {
                          controller.editDish(dish.id, dish);
                        }
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    );
  }
}
