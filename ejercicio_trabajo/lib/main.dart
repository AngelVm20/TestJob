import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint = (String? message, {int? wrapWidth}) {};
  if (kDebugMode) {
    WidgetsApp.debugAllowBannerOverride = false;
  }
  runApp(const MyApp());
}

class Product {
  final int id;
  final String title;

  Product({required this.id, required this.title});

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      title: json['title'],
    );
  }
}

class ProductController extends ChangeNotifier {
  List<Product> products = [];
  bool isLoading = false;
  int page = 1;

  Future<void> fetchProducts() async {
    isLoading = true;
    notifyListeners();

    final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts?_page=$page&_limit=10'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List<dynamic>;
      products.addAll(data.map((product) => Product.fromJson(product)).toList());
      page++;
    }
    isLoading = false;
    notifyListeners();
  }
}

class ProductList extends StatefulWidget {
  final List<Product> products;
  final Function() onLoadMore;

  const ProductList({
    required this.products,
    required this.onLoadMore,
  });

  @override
  _ProductListState createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        widget.onLoadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        //responsive de tamaño pantalla
        bool isSmallScreen = constraints.maxWidth < 600;
        return ListView.builder(
          controller: _scrollController,
          itemCount: widget.products.length + 1,
          itemBuilder: (context, index) {
            if (index < widget.products.length) {
              return ListTile(
                title: Text(
                  widget.products[index].title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 16.0 : 20.0,
                    fontStyle: FontStyle.italic,
                    color: Colors.black,
                  ),
                ),
              );
            } else {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }
          },
        );
      },
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ProductController productController = ProductController();

  @override
  void initState() {
    super.initState();
    productController.fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text(
            'LISTA DE PRODUCTOS',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          backgroundColor: const Color.fromARGB(255, 52, 192, 227),
          centerTitle: true,
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            return OrientationBuilder(
              builder: (context, orientation) {
                return FutureBuilder(
                  future: productController.fetchProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else {
                      return ProductList(
                        products: productController.products,
                        onLoadMore: productController.fetchProducts,
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
