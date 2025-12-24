import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../onboarding/models/media_item.dart';
import '../../onboarding/services/media_picker.dart';
import '../../onboarding/services/media_service.dart';
import '../../onboarding/widgets/media_slot_widget.dart';

class EditMediaScreen extends StatefulWidget {
  final User user;
  final Map<String, dynamic>? userData;

  const EditMediaScreen({
    super.key,
    required this.user,
    this.userData,
  });

  @override
  State<EditMediaScreen> createState() => _EditMediaScreenState();
}

class _EditMediaScreenState extends State<EditMediaScreen> {
  final List<MediaItem?> _mediaSlots = List.filled(6, null);
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadExistingMedia();
  }

  Future<void> _loadExistingMedia() async {
    if (widget.userData?['mediaUrls'] != null) {
      final List<dynamic> urls = widget.userData!['mediaUrls'];
      for (int i = 0; i < urls.length && i < 6; i++) {
        setState(() {
          _mediaSlots[i] = MediaItem(
            id: 'existing_$i',
            type: MediaType.photo,
            url: urls[i],
          );
        });
      }
    }
  }

  void _addMedia() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildMediaSourcePicker(),
    );
  }

  Widget _buildMediaSourcePicker() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Add Media',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0039A6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.photo_library,
                  color: Color(0xFF0039A6),
                ),
              ),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFromGallery();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0039A6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.camera_alt,
                  color: Color(0xFF0039A6),
                ),
              ),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFromGallery() async {
    final mediaList = await MediaPicker.pickMultipleFromGallery();
    if (mediaList.isNotEmpty) {
      setState(() {
        for (final media in mediaList) {
          final emptyIndex = _mediaSlots.indexWhere((slot) => slot == null);
          if (emptyIndex != -1) {
            _mediaSlots[emptyIndex] = media;
            _hasChanges = true;
          }
        }
      });
    }
  }

  Future<void> _takePhoto() async {
    final media = await MediaPicker.takePhoto();
    if (media != null) {
      setState(() {
        final emptyIndex = _mediaSlots.indexWhere((slot) => slot == null);
        if (emptyIndex != -1) {
          _mediaSlots[emptyIndex] = media;
          _hasChanges = true;
        }
      });
    }
  }

  Future<void> _cropImage(int index) async {
    final currentMedia = _mediaSlots[index];
    if (currentMedia?.path != null) {
      final media = await MediaPicker.cropExisting(currentMedia!.path!);
      if (media != null) {
        setState(() {
          _mediaSlots[index] = media;
          _hasChanges = true;
        });
      }
    }
  }

  void _editMedia(int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildEditOptions(index),
    );
  }

  Widget _buildEditOptions(int index) {
    final media = _mediaSlots[index];
    final bool isPhoto = media?.type == MediaType.photo;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Edit Photo',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Crop option (only for photos with local path)
            if (isPhoto && media?.path != null)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0039A6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.crop,
                    color: Color(0xFF0039A6),
                  ),
                ),
                title: const Text('Crop Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _cropImage(index);
                },
              ),
            // Delete option
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
              ),
              title: const Text('Delete', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _mediaSlots[index] = null;
                  _hasChanges = true;
                });
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMedia() async {
    final hasAtLeastOneMedia = _mediaSlots.any((item) => item != null);
    
    if (!hasAtLeastOneMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please keep at least one photo'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<String> mediaUrls = [];
      
      for (int i = 0; i < _mediaSlots.length; i++) {
        final media = _mediaSlots[i];
        if (media != null) {
          // If already has URL (existing media), keep it
          if (media.url != null && media.url!.isNotEmpty) {
            mediaUrls.add(media.url!);
          }
          // Otherwise upload new media
          else if (media.path != null) {
            final url = await MediaService.uploadMedia(media, widget.user.uid, i);
            if (url != null) {
              mediaUrls.add(url);
            }
          }
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .update({
            'mediaUrls': mediaUrls,
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photos saved!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving photos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0039A6)),
          onPressed: () => Navigator.of(context).pop(_hasChanges),
        ),
        title: const Text(
          'Edit Photos',
          style: TextStyle(
            color: Color(0xFF0039A6),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveMedia,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Save',
                      style: TextStyle(
                        color: Color(0xFF0039A6),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 3 / 4,
                ),
                itemCount: 6,
                itemBuilder: (context, index) {
                  final media = _mediaSlots[index];
                  final isFirstItem = index == 0 && media != null;

                  // Only allow dragging if media exists
                  if (media != null) {
                    return LongPressDraggable<int>(
                      data: index,
                      feedback: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: (MediaQuery.of(context).size.width - 60) / 3,
                          height: ((MediaQuery.of(context).size.width - 60) / 3) * (4 / 3),
                          child: Opacity(
                            opacity: 0.7,
                            child: MediaSlotWidget(
                              media: media,
                              index: index,
                              isFirstItem: isFirstItem,
                              onEdit: () => _editMedia(index),
                            ),
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: MediaSlotWidget(
                          media: media,
                          index: index,
                          isFirstItem: isFirstItem,
                          onEdit: () => _editMedia(index),
                        ),
                      ),
                      child: DragTarget<int>(
                        onAcceptWithDetails: (details) {
                          final fromIndex = details.data;
                          setState(() {
                            final temp = _mediaSlots[fromIndex];
                            _mediaSlots[fromIndex] = _mediaSlots[index];
                            _mediaSlots[index] = temp;
                            _hasChanges = true;
                          });
                        },
                        builder: (context, candidateData, rejectedData) {
                          return MediaSlotWidget(
                            media: media,
                            index: index,
                            isFirstItem: isFirstItem,
                            onEdit: () => _editMedia(index),
                          );
                        },
                      ),
                    );
                  }

                  // Empty slot - just tappable, not draggable
                  return MediaSlotWidget(
                    media: media,
                    index: index,
                    isFirstItem: isFirstItem,
                    onTap: _addMedia,
                  );
                },
              ),
            ),
          ),
          // Info hint
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[100]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Long press and drag to reorder. First photo is your main profile picture.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
