import 'package:flutter/material.dart';

import '../models/win.dart';
import '../theme/app_colors.dart';

/// What the user entered, handed back to whoever pushed this screen.
/// Trimming and blank-to-null normalization for [description] happen in
/// [WinRepository.add]/[WinRepository.update], not here, so that logic
/// lives in one place regardless of whether this was an add or an edit.
class AddWinResult {
  const AddWinResult({required this.title, this.description});

  final String title;
  final String? description;
}

/// Also doubles as the edit screen: pass [existingWin] to pre-fill the
/// fields with a win's current title/description. The caller decides
/// whether the returned [AddWinResult] should create a new win or update
/// an existing one — this screen just collects the form input either way.
class AddWinScreen extends StatefulWidget {
  const AddWinScreen({super.key, this.existingWin});

  final Win? existingWin;

  bool get isEditing => existingWin != null;

  @override
  State<AddWinScreen> createState() => _AddWinScreenState();
}

class _AddWinScreenState extends State<AddWinScreen> {
  late final _titleController = TextEditingController(text: widget.existingWin?.title ?? '');
  late final _descriptionController = TextEditingController(text: widget.existingWin?.description ?? '');

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;
    Navigator.of(context).pop(
      AddWinResult(title: title, description: _descriptionController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: AppColors.muted),
                  ),
                  Text(
                    widget.isEditing ? 'EDIT STAR' : 'NEW STAR',
                    style: const TextStyle(
                      fontSize: 12,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'What did you get through?',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'In a few words',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                style: const TextStyle(color: AppColors.text, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'E.g. I held on after a rejection and kept going',
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Details (optional)',
                style: TextStyle(fontSize: 13, color: AppColors.muted),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionController,
                minLines: 4,
                maxLines: 6,
                style: const TextStyle(color: AppColors.text, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'What made this moment hard, and how you got through it',
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _titleController,
                  builder: (context, value, child) {
                    final canSave = value.text.trim().isNotEmpty;
                    return ElevatedButton(
                      onPressed: canSave ? _save : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.onGold,
                        disabledBackgroundColor: AppColors.nightBorder,
                        disabledForegroundColor: AppColors.muted,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        widget.isEditing ? 'Save changes' : 'Light this star',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
