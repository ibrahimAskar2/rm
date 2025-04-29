import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'dart:ui' as ui;

class ProductTemplateScreen extends StatefulWidget {
  const ProductTemplateScreen({super.key});

  @override
  State<ProductTemplateScreen> createState() => _ProductTemplateScreenState();
}

class _ProductTemplateScreenState extends State<ProductTemplateScreen> {
  final _screenshotController = ScreenshotController();
  File? _productImage;
  File? _companyLogo;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  // خيارات تخصيص القالب
  Color _backgroundColor = Colors.white;
  Color _textColor = Colors.black;
  double _fontSize = 16.0;
  String _selectedFont = 'Cairo';
  bool _showBorder = true;
  Color _borderColor = Colors.blue;
  double _borderWidth = 2.0;
  double _cornerRadius = 12.0;
  
  // خيارات إضافية
  bool _showQRCode = false;
  String _qrData = '';
  bool _showCompanyLogo = false;
  String _selectedBackground = 'none';
  double _imageOpacity = 1.0;
  double _imageBrightness = 0.0;
  double _imageContrast = 1.0;
  
  // قائمة الخطوط المتاحة
  final List<String> _availableFonts = ['Cairo', 'Arial', 'Roboto', 'Open Sans'];
  
  // قوالب الخلفيات الجاهزة
  final List<Map<String, dynamic>> _backgroundTemplates = [
    {'name': 'بدون خلفية', 'value': 'none', 'color': Colors.white},
    {'name': 'خلفية زرقاء', 'value': 'blue', 'color': Colors.blue.shade50},
    {'name': 'خلفية رمادية', 'value': 'gray', 'color': Colors.grey.shade100},
    {'name': 'خلفية وردية', 'value': 'pink', 'color': Colors.pink.shade50},
    {'name': 'خلفية خضراء', 'value': 'green', 'color': Colors.green.shade50},
  ];

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _productImage = File(image.path);
      });
    }
  }

  Future<void> _pickCompanyLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        _companyLogo = File(image.path);
      });
    }
  }

  Future<void> _saveTemplate() async {
    if (_productImage == null) return;
    
    try {
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes == null) return;
      
      // حفظ الصورة في معرض الصور
      await ImageGallerySaver.saveImage(imageBytes);
      
      // حفظ الصورة في Firebase Storage
      final storageRef = FirebaseStorage.instance.ref();
      final templateRef = storageRef.child('templates/${DateTime.now().millisecondsSinceEpoch}.png');
      await templateRef.putData(imageBytes);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حفظ القالب بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء حفظ القالب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareTemplate() async {
    if (_productImage == null) return;
    
    try {
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes == null) return;
      
      // حفظ الصورة مؤقتاً
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/template.png');
      await tempFile.writeAsBytes(imageBytes);
      
      await Share.shareXFiles(
        [XFile(tempFile.path)],
        text: '${_nameController.text}\n${_priceController.text} ريال\n${_descriptionController.text}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء مشاركة القالب: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildPreview() {
    if (_productImage == null) return const SizedBox.shrink();
    
    return Screenshot(
      controller: _screenshotController,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _selectedBackground == 'none' ? _backgroundColor : _backgroundTemplates.firstWhere((template) => template['value'] == _selectedBackground)['color'],
          borderRadius: BorderRadius.circular(_cornerRadius),
          border: _showBorder ? Border.all(
            color: _borderColor,
            width: _borderWidth,
          ) : null,
        ),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(_cornerRadius)),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.matrix([
                      _imageContrast, 0, 0, 0, 0,
                      0, _imageContrast, 0, 0, 0,
                      0, 0, _imageContrast, 0, 0,
                      0, 0, 0, _imageOpacity, 0,
                      _imageBrightness, _imageBrightness, _imageBrightness, 0, 1,
                    ]),
                    child: Image.file(
                      _productImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                if (_showCompanyLogo && _companyLogo != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.file(
                        _companyLogo!,
                        height: 40,
                        width: 40,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameController.text,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: _fontSize + 4,
                      fontWeight: FontWeight.bold,
                      fontFamily: _selectedFont,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_priceController.text} ريال',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w500,
                      fontFamily: _selectedFont,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _descriptionController.text,
                    style: TextStyle(
                      color: _textColor,
                      fontSize: _fontSize - 2,
                      fontFamily: _selectedFont,
                    ),
                  ),
                  if (_showQRCode && _qrData.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: QrImageView(
                        data: _qrData,
                        version: QrVersions.auto,
                        size: 100.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomizationOptions() {
    return ExpansionTile(
      title: const Text('خيارات تخصيص القالب'),
      children: [
        // خيارات النص
        ExpansionTile(
          title: const Text('خيارات النص'),
          children: [
            ListTile(
              title: const Text('لون النص'),
              trailing: ColorPicker(
                color: _textColor,
                onColorChanged: (color) => setState(() => _textColor = color),
              ),
            ),
            ListTile(
              title: const Text('حجم الخط'),
              trailing: Slider(
                value: _fontSize,
                min: 12,
                max: 24,
                divisions: 12,
                label: _fontSize.round().toString(),
                onChanged: (value) => setState(() => _fontSize = value),
              ),
            ),
            ListTile(
              title: const Text('نوع الخط'),
              trailing: DropdownButton<String>(
                value: _selectedFont,
                items: _availableFonts.map((font) => DropdownMenuItem(
                  value: font,
                  child: Text(font),
                )).toList(),
                onChanged: (value) => setState(() => _selectedFont = value!),
              ),
            ),
          ],
        ),
        
        // خيارات الإطار
        ExpansionTile(
          title: const Text('خيارات الإطار'),
          children: [
            SwitchListTile(
              title: const Text('إظهار الإطار'),
              value: _showBorder,
              onChanged: (value) => setState(() => _showBorder = value),
            ),
            if (_showBorder) ...[
              ListTile(
                title: const Text('لون الإطار'),
                trailing: ColorPicker(
                  color: _borderColor,
                  onColorChanged: (color) => setState(() => _borderColor = color),
                ),
              ),
              ListTile(
                title: const Text('سمك الإطار'),
                trailing: Slider(
                  value: _borderWidth,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: _borderWidth.round().toString(),
                  onChanged: (value) => setState(() => _borderWidth = value),
                ),
              ),
            ],
            ListTile(
              title: const Text('تقويس الزوايا'),
              trailing: Slider(
                value: _cornerRadius,
                min: 0,
                max: 24,
                divisions: 12,
                label: _cornerRadius.round().toString(),
                onChanged: (value) => setState(() => _cornerRadius = value),
              ),
            ),
          ],
        ),
        
        // خيارات الصورة
        ExpansionTile(
          title: const Text('خيارات الصورة'),
          children: [
            ListTile(
              title: const Text('شفافية الصورة'),
              trailing: Slider(
                value: _imageOpacity,
                min: 0.0,
                max: 1.0,
                divisions: 10,
                label: (_imageOpacity * 100).round().toString(),
                onChanged: (value) => setState(() => _imageOpacity = value),
              ),
            ),
            ListTile(
              title: const Text('سطوع الصورة'),
              trailing: Slider(
                value: _imageBrightness,
                min: -0.5,
                max: 0.5,
                divisions: 10,
                label: (_imageBrightness * 100).round().toString(),
                onChanged: (value) => setState(() => _imageBrightness = value),
              ),
            ),
            ListTile(
              title: const Text('تباين الصورة'),
              trailing: Slider(
                value: _imageContrast,
                min: 0.5,
                max: 1.5,
                divisions: 10,
                label: (_imageContrast * 100).round().toString(),
                onChanged: (value) => setState(() => _imageContrast = value),
              ),
            ),
          ],
        ),
        
        // خيارات إضافية
        ExpansionTile(
          title: const Text('خيارات إضافية'),
          children: [
            SwitchListTile(
              title: const Text('إظهار رمز QR'),
              value: _showQRCode,
              onChanged: (value) => setState(() => _showQRCode = value),
            ),
            if (_showQRCode)
              ListTile(
                title: const Text('محتوى رمز QR'),
                trailing: SizedBox(
                  width: 200,
                  child: TextField(
                    onChanged: (value) => setState(() => _qrData = value),
                    decoration: const InputDecoration(
                      hintText: 'أدخل الرابط أو النص',
                      isDense: true,
                    ),
                  ),
                ),
              ),
            SwitchListTile(
              title: const Text('إظهار شعار الشركة'),
              value: _showCompanyLogo,
              onChanged: (value) => setState(() => _showCompanyLogo = value),
            ),
            if (_showCompanyLogo)
              ListTile(
                title: const Text('اختر شعار الشركة'),
                trailing: IconButton(
                  icon: const Icon(Icons.add_photo_alternate),
                  onPressed: _pickCompanyLogo,
                ),
              ),
            ListTile(
              title: const Text('خلفية القالب'),
              trailing: DropdownButton<String>(
                value: _selectedBackground,
                items: _backgroundTemplates.map((template) => DropdownMenuItem(
                  value: template['value'],
                  child: Container(
                    width: 100,
                    height: 30,
                    decoration: BoxDecoration(
                      color: template['color'],
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text(template['name']),
                    ),
                  ),
                )).toList(),
                onChanged: (value) => setState(() => _selectedBackground = value!),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إنشاء قالب منتج'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTemplate,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareTemplate,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // صورة المنتج
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: _productImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _productImage!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 50),
                              SizedBox(height: 8),
                              Text('اضغط لإضافة صورة المنتج'),
                            ],
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
              
              // معلومات المنتج
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المنتج',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال اسم المنتج';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'السعر',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال سعر المنتج';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'وصف المنتج',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'الرجاء إدخال وصف المنتج';
                  }
                  return null;
                },
                onChanged: (value) => setState(() {}),
              ),
              const SizedBox(height: 24),
              
              // خيارات تخصيص القالب
              _buildCustomizationOptions(),
              const SizedBox(height: 24),
              
              // معاينة القالب
              if (_productImage != null) ...[
                const Text(
                  'معاينة القالب',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildPreview(),
                const SizedBox(height: 24),
              ],
              
              // زر إنشاء القالب
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate() && _productImage != null) {
                    _saveTemplate();
                  } else if (_productImage == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('الرجاء إضافة صورة للمنتج'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'إنشاء القالب',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}

class ColorPicker extends StatelessWidget {
  final Color color;
  final ValueChanged<Color> onColorChanged;

  const ColorPicker({
    super.key,
    required this.color,
    required this.onColorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('اختر اللون'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: color,
                onColorChanged: onColorChanged,
                pickerAreaHeightPercent: 0.8,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('تم'),
              ),
            ],
          ),
        );
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey),
        ),
      ),
    );
  }
} 
} 