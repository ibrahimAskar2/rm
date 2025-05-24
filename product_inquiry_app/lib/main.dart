import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://dktukfkitlfwpporhjsm.supabase.co', // URL الخاص بك
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRrdHVrZmtpdGxmd3Bwb3JoanNtIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc0Nzg1NjkzNSwiZXhwIjoyMDYzNDMyOTM1fQ.KXAxyAoADWgJHXD7EIr_X3grp3dTyGzR80MQ3VuLs7Y', // المفتاح العام (ضع المفتاح كاملاً هنا)
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'المنتجات',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: ProductListScreen(),
    );
  }
}

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List _products = [];
  List _filtered = [];
  bool _loading = true;

  Future<void> fetchProducts() async {
    setState(() => _loading = true);
    final response = await Supabase.instance.client
        .from('products')
        .select()
        .limit(100)
        .order('name')
        .execute();

    if (response.error == null) {
      setState(() {
        _products = response.data;
        _filtered = response.data;
        _loading = false;
      });
    } else {
      print('❌ Error: ${response.error!.message}');
    }
  }

  void search(String query) {
    final results = _products.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      return name.contains(query.toLowerCase());
    }).toList();
    setState(() => _filtered = results);
  }

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('قائمة المنتجات')),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    onChanged: search,
                    decoration: InputDecoration(
                      hintText: 'ابحث عن منتج...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final item = _filtered[index];
                      return ListTile(
                        title: Text(item['name'] ?? 'بدون اسم'),
                        subtitle: Text('السعر: ${item['regular_price']} | الكمية: ${item['quantity']}'),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
