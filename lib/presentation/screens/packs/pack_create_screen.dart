import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../blocs/sticker_pack/sticker_pack_bloc.dart';

/// Screen for creating a new sticker pack.
/// User enters a name (max 128 chars per WhatsApp spec), submits,
/// and is returned to the pack list.
class PackCreateScreen extends StatefulWidget {
  const PackCreateScreen({super.key});

  @override
  State<PackCreateScreen> createState() => _PackCreateScreenState();
}

class _PackCreateScreenState extends State<PackCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);
    final name = _nameController.text.trim();

    if (!mounted) return;
    final bloc = context.read<StickerPackBloc>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      bloc.add(StickerPackCreateRequested(name));
      // Wait a moment for the create to complete, then pop
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to create pack: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Sticker Pack')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                maxLength: 128,
                decoration: const InputDecoration(
                  labelText: 'Pack name',
                  hintText: 'e.g., My Cute Cats',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Please enter a name';
                  }
                  if (trimmed.length > 128) {
                    return 'Name must be 128 characters or less';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Text(
                'You can add stickers to this pack after creating it. '
                'You need at least 3 stickers to import the pack to WhatsApp.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.secondary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Pack'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
