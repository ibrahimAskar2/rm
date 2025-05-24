
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    title: 'استعلامات المواد',
    theme: ThemeData(primarySwatch: Colors.blue),
    home: ProductInquiryScreen(),
  ));
}

class ProductInquiryScreen extends StatefulWidget {
  @override
  _ProductInquiryScreenState createState() => _ProductInquiryScreenState();
}

class _ProductInquiryScreenState extends State<ProductInquiryScreen> {
  final TextEditingController _controller = TextEditingController();
  String searchResult = '';

  void search() {
    setState(() {
      searchResult = _controller.text.isEmpty ? '' : 'نتائج البحث عن: ${_controller.text}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text('استعلامات المواد')),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _controller,
                decoration: InputDecoration(
                  labelText: 'ابحث عن المادة',
                  suffixIcon: IconButton(
                    icon: Icon(Icons.search),
                    onPressed: search,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(searchResult, style: TextStyle(fontSize: 18)),
            ],
          ),
        ),
      ),
    );
  }
}
