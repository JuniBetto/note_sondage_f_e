import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AvatarInput extends StatefulWidget {
  final double size;
  final String? initialImageUrl;
  final File? initialImageFile;
  final Uint8List? initialImageBytes;
  final Function(File?)? onImageChanged;
  final Function(Uint8List?)? onImageBytesChanged;
  final bool editable;
  final Widget? placeholder;
  final bool showRemoveOption;
  final double borderWidth;
  final Color borderColor;

  const AvatarInput({
    Key? key,
    this.size = 120,
    this.initialImageUrl,
    this.initialImageFile,
    this.initialImageBytes,
    this.onImageChanged,
    this.onImageBytesChanged,
    this.editable = true,
    this.placeholder,
    this.showRemoveOption = true,
    this.borderWidth = 2,
    this.borderColor = Colors.grey,
  }) : super(key: key);

  @override
  _AvatarInputState createState() => _AvatarInputState();
}

class _AvatarInputState extends State<AvatarInput> {
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  final ImagePicker _imagePicker = ImagePicker();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedImage = widget.initialImageFile;
    _selectedImageBytes = widget.initialImageBytes;
  }

  Future<void> _pickImage(ImageSource source) async {
    if (!widget.editable || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // Su web, leggi i bytes
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
          });
          widget.onImageBytesChanged?.call(bytes);
        } else {
          // Su mobile, usa File
          final file = File(pickedFile.path);
          setState(() {
            _selectedImage = file;
            _selectedImageBytes = null;
          });
          widget.onImageChanged?.call(file);
        }
      }
    } catch (e) {
      debugPrint("Errore pickImage: $e");
      _showSnackbar("Errore durante la selezione dell'immagine", Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickMultiImage() async {
    try {
      final List<XFile>? images = await _imagePicker.pickMultiImage(
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (images != null && images.isNotEmpty) {
        final firstImage = images.first;
        
        if (kIsWeb) {
          final bytes = await firstImage.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
          });
          widget.onImageBytesChanged?.call(bytes);
        } else {
          final file = File(firstImage.path);
          setState(() {
            _selectedImage = file;
            _selectedImageBytes = null;
          });
          widget.onImageChanged?.call(file);
        }
      }
    } catch (e) {
      debugPrint("Errore multi-image: $e");
      _showSnackbar("Selezione multipla non supportata", Colors.orange);
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
      _selectedImageBytes = null;
    });
    widget.onImageChanged?.call(null);
    widget.onImageBytesChanged?.call(null);
  }

  void _showSnackbar(String message, [Color color = Colors.blue]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Camera option - hide on web (not supported)
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text("Scatta foto"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text("Scegli dalla galleria"),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            // Multi-selection option - hide on web
            if (!kIsWeb)
              ListTile(
                leading: const Icon(Icons.collections, color: Colors.purple),
                title: const Text("Seleziona multiple"),
                onTap: () {
                  Navigator.pop(context);
                  _pickMultiImage();
                },
              ),
            if (widget.showRemoveOption &&
                (_selectedImage != null || _selectedImageBytes != null || widget.initialImageUrl != null))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Rimuovi immagine"),
                onTap: () {
                  Navigator.pop(context);
                  _removeImage();
                },
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text("Annulla"),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    if (_isLoading) {
      return Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Web: use Image.memory with bytes
    if (_selectedImageBytes != null) {
      return ClipOval(
        child: Image.memory(
          _selectedImageBytes!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    }

    // Mobile: use Image.file
    if (_selectedImage != null && !kIsWeb) {
      return ClipOval(
        child: Image.file(
          _selectedImage!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    }

    if (widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          widget.initialImageUrl!,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return _buildPlaceholder();
          },
        ),
      );
    }

    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade200,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade300, Colors.grey.shade400],
        ),
      ),
      child:
          widget.placeholder ??
          Icon(
            Icons.person_outline,
            size: widget.size * 0.5,
            color: Colors.white,
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: widget.editable ? _showImageOptions : null,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Avatar con animazione
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: widget.borderColor,
                  width: widget.borderWidth,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: _buildAvatar(),
            ),

            // Pulsante modifica
            if (widget.editable && !_isLoading)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Theme.of(context).primaryColor,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Icon(
                    _selectedImage != null || widget.initialImageUrl != null
                        ? Icons.edit
                        : Icons.add_a_photo,
                    size: widget.size * 0.15,
                    color: Colors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
