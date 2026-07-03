import 'dart:io';
import 'package:dio/dio.dart';
import 'package:e_ticketing/core/constants/api_constants.dart';
import 'package:e_ticketing/core/network/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Added for ref access
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:e_ticketing/core/theme/app_colors.dart';

// Change to ConsumerStatefulWidget to access "ref"
class CreateTicketScreen extends ConsumerStatefulWidget {
  const CreateTicketScreen({super.key});

  @override
  ConsumerState<CreateTicketScreen> createState() => _CreateTicketScreenState();
}

class _CreateTicketScreenState extends ConsumerState<CreateTicketScreen> {
  // Define Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String selectedCategory = 'technical'; // Match backend enum
  String selectedPriority = 'medium';
  File? _selectedImage;
  bool _isLoading = false;

  // Validation error messages
  String? _titleError;
  String? _descError;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // Validation methods based on backend spec
  bool _validateInputs() {
    bool isValid = true;

    // Validate title
    if (_titleController.text.isEmpty) {
      _titleError = "Incident header is required";
      isValid = false;
    } else if (_titleController.text.length < 5) {
      _titleError = "Incident header at least 5 characters long";
      isValid = false;
    } else if (_titleController.text.length > 255) {
      _titleError = "Incident header must be less than 255 characters";
      isValid = false;
    } else {
      _titleError = null;
    }

    // Validate description
    if (_descController.text.isEmpty) {
      _descError = "Detailed narrative is required";
      isValid = false;
    } else if (_descController.text.length < 10) {
      _descError = "Narrative must be at least 10 characters";
      isValid = false;
    } else {
      _descError = null;
    }

    // Validate category
    final validCategories = ['billing', 'technical', 'account', 'general', 'feature_request'];
    if (!validCategories.contains(selectedCategory)) {
      isValid = false;
    }

    // Validate priority
    final validPriorities = ['low', 'medium', 'high', 'critical'];
    if (!validPriorities.contains(selectedPriority)) {
      isValid = false;
    }

    return isValid;
  }

  // Method to pick image
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }
  Future<void> _submitTicket() async {
    setState(() {
      _validateInputs();
    });

    if (_titleError != null || _descError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_titleError ?? _descError ?? "Please fix errors"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    // Use "ref" provided by ConsumerState
    final dio = ref.read(dioProvider).instance;

    try {
      List<String> attachmentIds = [];

      // 1. Upload file if selected
      if (_selectedImage != null) {
        FormData formData = FormData.fromMap({
          "file": await MultipartFile.fromFile(_selectedImage!.path, filename: "evidence.jpg"),
        });
        final uploadRes = await dio.post("${ApiConstants.baseUrl}/upload", data: formData);
        attachmentIds.add(uploadRes.data['data']['id']);
      }

      // 2. Create ticket using defined controllers
      await dio.post(ApiConstants.tickets, data: {
        "title": _titleController.text,
        "description": _descController.text,
        "category": selectedCategory,
        "priority": selectedPriority,
        "attachments": attachmentIds
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Ticket created successfully"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint("Upload failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(leading: const BackButton()),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Lodge Incident", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: colors.textPrimary)),
            Text("Official Support Registry Entry", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textMuted, letterSpacing: 2)),
            const SizedBox(height: 32),

            _buildLabel(context, "Incident Header"),
            _buildInputField(context, _titleController, "e.g., Access credentials expired", error: _titleError),
            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(child: _buildDropdown(context, "Registry Category", ['technical', 'billing', 'account', 'general', 'feature_request'], selectedCategory, (val) => setState(() => selectedCategory = val!))),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdown(context, "Risk Assessment", ['low', 'medium', 'high', 'critical'], selectedPriority, (val) => setState(() => selectedPriority = val!))),
              ],
            ),
            const SizedBox(height: 24),

            _buildLabel(context, "Detailed Narrative"),
            _buildInputField(context, _descController, "Provide a comprehensive breakdown...", maxLines: 5, error: _descError),
            const SizedBox(height: 24),

            _buildLabel(context, "Evidence Log"),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _selectedImage!,
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(child: _buildEvidenceButton(context, LucideIcons.camera, "Capture", () => _pickImage(ImageSource.camera))),
                const SizedBox(width: 16),
                Expanded(child: _buildEvidenceButton(context, LucideIcons.image, "Files", () => _pickImage(ImageSource.gallery))),
              ],
            ),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitTicket,
                icon: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(LucideIcons.send, size: 18, color: Colors.white),
                label: Text(_isLoading ? "Synchronizing..." : "Submit Record", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated helpers to use controllers and callbacks
  Widget _buildLabel(BuildContext context, String text) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textMuted, letterSpacing: 1)),
    );
  }

  Widget _buildInputField(BuildContext context, TextEditingController controller, String hint, {int maxLines = 1, String? error}) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: colors.textPrimary),
            onChanged: (_) => setState(() => _validateInputs()),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: colors.textDim),
              errorText: error,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: error != null ? colors.danger : colors.surfaceBorder,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: error != null ? colors.danger : colors.surfaceBorder,
                  width: error != null ? 2 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: error != null ? colors.danger : colors.accent,
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(BuildContext context, String label, List<String> items, String selected, ValueChanged<String?> onChanged) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context, label),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.surfaceBorder),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selected,
                isExpanded: true,
                style: TextStyle(color: colors.textPrimary),
                items: items.map((i) => DropdownMenuItem(value: i, child: Text(i.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceButton(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final colors = context.colors;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.surfaceBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.textMuted),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colors.textMuted)),
          ],
        ),
      ),
    );
  }
}
