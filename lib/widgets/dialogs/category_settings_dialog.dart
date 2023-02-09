import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../models/category.dart';
import '../../services/firestore_service.dart';

class CategorySettingsDialog extends StatefulWidget {
  final Iterable<Category> categories;

  const CategorySettingsDialog({Key? key, required this.categories})
      : super(key: key);

  @override
  State<CategorySettingsDialog> createState() => _CategorySettingsDialogState();
}

class _CategorySettingsDialogState extends State<CategorySettingsDialog> {
  final categoryNameController = TextEditingController();
  Category? category;

  @override
  void dispose() {
    categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        title: const Text('Category settings'),
        content: Column(
          children: [
            DropdownButton<Category?>(
              value: category,
              dropdownColor: backgroundColor,
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('None', style: TextStyle(color: white1)),
                ),
                ...widget.categories.map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(
                        c.name,
                        style: TextStyle(color: Color(c.colorValue)),
                      ),
                    ))
              ],
              onChanged: (value) {
                setState(() {
                  category = value;
                });
              },
            ),
            TextField(
              autofocus: true,
              decoration: const InputDecoration(hintText: 'New category name'),
              controller: categoryNameController,
              style: const TextStyle(color: white1),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                if (category != null &&
                    categoryNameController.text.isNotEmpty) {
                  category!.name = categoryNameController.text;
                  Provider.of<FirestoreService>(context, listen: false)
                      .updateCategory(category!);
                }
                Navigator.pop(context);
              },
              child: const Text('OK')),
          TextButton(
              onPressed: () {
                if (category != null) {
                  Provider.of<FirestoreService>(context, listen: false)
                      .deleteCategory(category!);
                }
                Navigator.pop(context);
              },
              child: const Text('Delete')),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
        ]);
  }
}