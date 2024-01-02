import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shopping_list_app/data/categories.dart';
// import 'package:shopping_list_app/models/category.dart';

import 'package:shopping_list_app/models/grocery_item.dart';
import 'package:shopping_list_app/widgets/new_items.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  var _isLoading = true;
  late Future<List<GroceryItem>> _loadedItems;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
      "shopping-list-f7e52-default-rtdb.firebaseio.com",
      "shopping-list.json",
    );

    final response = await http.get(url);

    if (response.statusCode >= 400) {
      throw Exception("Failed to fetch grocery items. Please try again later.");
    }

    if (response.body == "null") {
      setState(() {
        _isLoading = false;
      });
      return [];
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
            (catItem) => catItem.value.title == item.value["category"],
          )
          .value;
      loadedItems.add(
        GroceryItem(
          id: item.key,
          name: item.value["name"],
          quantity: item.value["quantity"],
          category: category,
        ),
      );
    }
    setState(() {
      _groceryItems = loadedItems;
      _isLoading = false;
    });
    return loadedItems;
  }

  // add item
  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => const NewItems(),
      ),
    );

 if (newItem == null) {
       return;
     }
//
   setState(() {
       _groceryItems.add(newItem);
     });
  }

  // remove item
  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });

    final url = Uri.https("shopping-list-f7e52-default-rtdb.firebaseio.com",
        "shopping-list/${item.id}.json");

    final response = await http.delete(url);

    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text("No items added yet."),
    );

    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator(),);
    }

    if (_groceryItems.isNotEmpty) {}

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Your Groceries",
          textAlign: TextAlign.start,
        ),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _loadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
              ),
            );
          }

          if (snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No grocery items added, yet!",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onBackground,
                  //fontSize: 23,
                ),
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (ctx, index) => Dismissible(
              key: ValueKey(snapshot.data![index].id),
              background: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withOpacity(0.8),
                ),
              ),
              onDismissed: (direction) {
                _removeItem(snapshot.data![index]);
              },
              child: ListTile(
                title: Text(
                  snapshot.data![index].name,
                ),
                leading: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: snapshot.data![index].category.color,
                  ),
                ),
                trailing: Text(
                  snapshot.data![index].quantity.toString(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
