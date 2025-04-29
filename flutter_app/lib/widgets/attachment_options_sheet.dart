import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:developer' as developer;

class AttachmentOptionsSheet extends StatelessWidget {
  final Function(PlatformFile) onImageSelected;

  const AttachmentOptionsSheet({
    super.key,
    required this.onImageSelected,
  });

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        onImageSelected(result.files.first);
      }
    } catch (e) {
      developer.log('Error picking image: $e', name: 'AttachmentOptionsSheet');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('اختر صورة'),
            onTap: () {
              Navigator.pop(context);
              _pickImage();
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('التقط صورة'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement camera capture
            },
          ),
        ],
      ),
    );
  }
} 