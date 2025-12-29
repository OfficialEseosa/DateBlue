import 'dart:io';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// Screen to preview and confirm images before sending
class ImagePreviewScreen extends StatefulWidget {
  final List<File> images;
  final Function(List<File>) onSend;

  const ImagePreviewScreen({
    super.key,
    required this.images,
    required this.onSend,
  });

  @override
  State<ImagePreviewScreen> createState() => _ImagePreviewScreenState();
}

class _ImagePreviewScreenState extends State<ImagePreviewScreen> {
  late List<File> _selectedImages;
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _selectedImages = List.from(widget.images);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _removeImage(int index) {
    if (_selectedImages.length == 1) {
      Navigator.pop(context);
      return;
    }
    
    setState(() {
      _selectedImages.removeAt(index);
      if (_currentIndex >= _selectedImages.length) {
        _currentIndex = _selectedImages.length - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _selectedImages.length > 1
              ? '${_currentIndex + 1} of ${_selectedImages.length}'
              : 'Preview',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          if (_selectedImages.length > 1)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white),
              onPressed: () => _removeImage(_currentIndex),
            ),
        ],
      ),
      body: Column(
        children: [
          // Main image preview
          Expanded(
            child: _selectedImages.length == 1
                ? _buildSingleImage(_selectedImages[0])
                : PageView.builder(
                    controller: _pageController,
                    itemCount: _selectedImages.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return _buildSingleImage(_selectedImages[index]);
                    },
                  ),
          ),

          // Thumbnail strip for multiple images
          if (_selectedImages.length > 1)
            Container(
              height: 80,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _selectedImages.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _currentIndex;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? AppColors.gsuBlue : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.file(
                          _selectedImages[index],
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // Send button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onSend(_selectedImages);
                  },
                  icon: const Icon(Icons.send),
                  label: Text(
                    _selectedImages.length == 1
                        ? 'Send Photo'
                        : 'Send ${_selectedImages.length} Photos',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gsuBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleImage(File image) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.file(
          image,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
