import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';

class AddReportScreen extends StatefulWidget {
  const AddReportScreen({super.key});

  @override
  State<AddReportScreen> createState() => _AddReportScreenState();
}

class _AddReportScreenState extends State<AddReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _apiService = ApiService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _category = 'other';
  File? _mediaFile;
  Position? _currentPosition;
  bool _isLoading = false;
  bool _isLocating = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
              if (_mediaFile != null)
                ListTile(
                  leading: const Icon(Icons.delete),
                  title: const Text('Remove Photo'),
                  onTap: () => Navigator.of(context).pop(),
                ),
            ],
          ),
        );
      },
    );

    if (source == null && _mediaFile != null) {
      setState(() {
        _mediaFile = null;
      });
      return;
    }

    if (source != null) {
      try {
        final XFile? pickedFile = await _picker.pickImage(source: source);
        if (pickedFile != null) {
          setState(() {
            _mediaFile = File(pickedFile.path);
          });
        }
      } catch (e) {
        _showError("Failed to pick image: $e");
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showError('Location permissions are denied');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showError('Location permissions are permanently denied');
        return;
      }
      _currentPosition = await Geolocator.getCurrentPosition();
      setState(() {});
    } catch (e) {
      _showError("Failed to get location: $e");
    } finally {
      setState(() => _isLocating = false);
    }
  }

  void _submitReport() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await _apiService.createReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _category,
        mediaFile: _mediaFile,
        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        _showError("Failed to submit report.");
      }
    } catch (e) {
      _showError("An error occurred: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Report")),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: "Title",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: "Description",
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _category,
                      decoration: const InputDecoration(
                        labelText: "Category",
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'electrical',
                          child: Text('Electrical'),
                        ),
                        DropdownMenuItem(
                          value: 'road',
                          child: Text('Road'),
                        ),
                        DropdownMenuItem(
                          value: 'drain',
                          child: Text('Drainage'),
                        ),
                        DropdownMenuItem(
                          value: 'other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _category = value!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Media Section
                    if (_mediaFile == null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.attach_file),
                        label: const Text("Attach Media"),
                        onPressed: _pickImage,
                      )
                    else
                      Column(
                        children: [
                          Image.file(
                            _mediaFile!,
                            height: 150,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _pickImage,
                            child: const Text("Change Media"),
                          ),
                        ],
                      ),
                    const SizedBox(height: 16),
                    
                    // Location Section
                    if (_isLocating)
                      const Center(child: CircularProgressIndicator())
                    else
                      OutlinedButton.icon(
                        icon: const Icon(Icons.my_location),
                        label: const Text("Get Current Location"),
                        onPressed: _getCurrentLocation,
                      ),
                    
                    if (_currentPosition != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          "Location: ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submitReport,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("Submit Report"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}