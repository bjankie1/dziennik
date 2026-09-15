import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../domain/models/teacher_contact.dart';
import '../../providers/school_providers.dart';

class NewMessageScreen extends ConsumerStatefulWidget {
  const NewMessageScreen({super.key});

  @override
  ConsumerState<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends ConsumerState<NewMessageScreen> {
  final List<TeacherContact> _selectedRecipients = [];
  final TextEditingController _recipientSearchController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isSending = false;
  List<TeacherContact> _filteredSuggestions = [];
  bool _showSuggestions = false;

  @override
  void dispose() {
    _recipientSearchController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query, List<TeacherContact> allTeachers) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredSuggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    final filtered = allTeachers.where((t) {
      final isAlreadySelected = _selectedRecipients.any((r) => r.id == t.id);
      return !isAlreadySelected && t.matches(query);
    }).toList();

    setState(() {
      _filteredSuggestions = filtered;
      _showSuggestions = true;
    });
  }

  void _addRecipient(TeacherContact teacher) {
    setState(() {
      _selectedRecipients.add(teacher);
      _recipientSearchController.clear();
      _filteredSuggestions = [];
      _showSuggestions = false;
    });
    _searchFocusNode.requestFocus();
  }

  void _removeRecipient(TeacherContact teacher) {
    setState(() {
      _selectedRecipients.removeWhere((r) => r.id == teacher.id);
    });
  }

  Future<void> _handleSend() async {
    if (_selectedRecipients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wybierz co najmniej jednego nauczyciela jako odbiorcę'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final subject = _subjectController.text.trim();
    if (subject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wpisz temat wiadomości'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Wpisz treść wiadomości'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final repo = ref.read(schoolRepositoryProvider);
      final recipientNames = _selectedRecipients.map((r) => r.name).toList();

      await repo.sendMessage(
        recipientNames: recipientNames,
        subject: subject,
        body: body,
      );

      ref.invalidate(messagesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wiadomość została pomyślnie wysłana'),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd wysyłania: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final teachersAsync = ref.watch(teachersProvider);
    final allTeachers = teachersAsync.value ?? [];

    final canSend = _selectedRecipients.isNotEmpty &&
        _subjectController.text.trim().isNotEmpty &&
        _bodyController.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Zamknij',
        ),
        title: const Text(
          'Nowa wiadomość',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _isSending ? null : _handleSend,
              icon: _isSending
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send, size: 16),
              label: Text(_isSending ? 'Wysyłanie...' : 'Wyślij'),
              style: FilledButton.styleFrom(
                backgroundColor: canSend ? AppColors.primary : AppColors.outlineVariant,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () {
          setState(() => _showSuggestions = false);
          FocusScope.of(context).unfocus();
        },
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          children: [
            // 1. Recipients Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceContainerHigh),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Do:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _recipientSearchController,
                          focusNode: _searchFocusNode,
                          onChanged: (val) {
                            setState(() {});
                            _onSearchChanged(val, allTeachers);
                          },
                          decoration: InputDecoration(
                            hintText: _selectedRecipients.isEmpty
                                ? 'Wpisz nazwisko lub przedmiot (np. chemia)...'
                                : 'Dodaj kolejnego nauczyciela...',
                            hintStyle: const TextStyle(fontSize: 13, color: AppColors.outline),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Selected Chips
                  if (_selectedRecipients.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: _selectedRecipients.map((teacher) {
                        return InputChip(
                          avatar: CircleAvatar(
                            backgroundColor: AppColors.primary,
                            child: Text(
                              teacher.initials,
                              style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          label: Text(
                            '${teacher.name} (${teacher.subjectName})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          backgroundColor: AppColors.surfaceContainerHigh,
                          deleteIconColor: AppColors.onSurfaceVariant,
                          onDeleted: () => _removeRecipient(teacher),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        );
                      }).toList(),
                    ),
                  ],

                  // Autocomplete dropdown
                  if (_showSuggestions && _filteredSuggestions.isNotEmpty) ...[
                    const Divider(height: 16),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _filteredSuggestions.length,
                        itemBuilder: (context, idx) {
                          final t = _filteredSuggestions[idx];
                          return ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.primaryContainer,
                              child: Text(
                                t.initials,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.onPrimaryContainer,
                                ),
                              ),
                            ),
                            title: Text(
                              t.name,
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${t.subjectName} • ${t.role}',
                              style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                            ),
                            trailing: const Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
                            onTap: () => _addRecipient(t),
                          );
                        },
                      ),
                    ),
                  ] else if (_showSuggestions && _recipientSearchController.text.trim().isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'Nie znaleziono nauczyciela o podanym nazwisku lub przedmiocie.',
                        style: TextStyle(fontSize: 12, color: AppColors.outline),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. Subject Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceContainerHigh),
              ),
              child: Row(
                children: [
                  const Text(
                    'Temat:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _subjectController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Temat wiadomości',
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.outline),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Body Section
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceContainerHigh),
              ),
              child: TextField(
                controller: _bodyController,
                onChanged: (_) => setState(() {}),
                minLines: 8,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Napisz treść wiadomości do nauczyciela...\nMożesz podać powód, pytanie o sprawdzian lub poprosić o materiały.',
                  hintStyle: TextStyle(fontSize: 13, color: AppColors.outline, height: 1.4),
                  border: InputBorder.none,
                ),
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
            const SizedBox(height: 16),

            // Quick Tips
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Wskazówka: Możesz wybrać wielu nauczycieli naraz. Wiadomość zostanie wysłana bezpośrednio do systemu Librus.',
                      style: TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
