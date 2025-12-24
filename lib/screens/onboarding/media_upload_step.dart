import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/media_item.dart';
import 'services/media_picker.dart';
import 'services/media_service.dart';
import 'widgets/media_slot_widget.dart';
import '../../widgets/onboarding_bottom_bar.dart';

class MediaUploadStep extends StatefulWidget {
  final User user;
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onNext;
  final VoidCallback onBack;

  const MediaUploadStep({
    super.key,
    required this.user,
    required this.initialData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<MediaUploadStep> createState() => _MediaUploadStepState();
}

class _MediaUploadStepState extends State<MediaUploadStep> {
  final List<MediaItem?> _mediaSlots = List.filled(6, null);
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingMedia();
  }

  bool get _hasAtLeastOneMedia => _mediaSlots.any((item) => item != null);

  Future<void> _loadExistingMedia() async {
    if (widget.initialData['mediaUrls'] != null) {
      final List<dynamic> urls = widget.initialData['mediaUrls'];
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
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0039A6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.videocam,
                  color: Color(0xFF0039A6),
                ),
              ),
              title: const Text('Record a Video'),
              onTap: () {
                Navigator.pop(context);
                _recordVideo();
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
        }
      });
    }
  }

  Future<void> _recordVideo() async {
    final media = await MediaPicker.recordVideo();
    if (media != null) {
      setState(() {
        final emptyIndex = _mediaSlots.indexWhere((slot) => slot == null);
        if (emptyIndex != -1) {
          _mediaSlots[emptyIndex] = media;
        }
      });
    }
  }

  Future<void> _cropImage(int index) async {
    final currentMedia = _mediaSlots[index];
    if (currentMedia?.path != null) {
      final media = await MediaPicker.cropExisting(currentMedia!.path!);
      if (media != null) {
        setState(() => _mediaSlots[index] = media);
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
              'Edit Media',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // Crop option (only for photos)
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
              title: const Text('Delete'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _mediaSlots[index] = null;
                });
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAndContinue() async {
    if (!_hasAtLeastOneMedia) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one photo or video'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload media to Firebase Storage and get URLs
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

      final data = {
        'mediaUrls': mediaUrls,
        'onboardingStep': 16,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .set(data, SetOptions(merge: true));

      if (mounted) {
        widget.onNext(data);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving media: $e'),
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
    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add Photos & Videos',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0039A6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload up to 6 photos or videos',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                    child: Column(
                      children: [
                        Expanded(
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
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
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Colors.blue[700],
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Long press and drag to reorder. First photo will be your main profile picture',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.blue[700],
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        OnboardingBottomBar(
          onBack: widget.onBack,
          onContinue: _saveAndContinue,
          isLoading: _isLoading,
          canContinue: _hasAtLeastOneMedia,
        ),
      ],
    );
  }
}
