
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    title: 'استعلامات المواد',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: ProductSearchScreen(),
  ));
}

class ProductSearchScreen extends StatelessWidget {
  final List<String> dummyProducts = [
    'مادة ١', 'مادة ٢', 'مادة ٣', 'مادة ٤'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('استعلامات المواد')),
      body: ListView.builder(
        itemCount: dummyProducts.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(dummyProducts[index]),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ProductDetailScreen(productName: dummyProducts[index]),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final String productName;

  const ProductDetailScreen({Key? key, required this.productName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(productName)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('تفاصيل المنتج: $productName\nالأسعار والكمية حسب الفروع...'),
      ),
    );
  }
}
