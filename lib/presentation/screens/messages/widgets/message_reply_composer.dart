import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/message_thread.dart';
import '../../../../domain/models/user_role.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/school_providers.dart';

class MessageReplyComposer extends ConsumerStatefulWidget {
  final MessageThread thread;
  final ValueChanged<MessageItem> onReplySent;

  const MessageReplyComposer({
    super.key,
    required this.thread,
    required this.onReplySent,
  });

  @override
  ConsumerState<MessageReplyComposer> createState() =>
      _MessageReplyComposerState();
}

class _MessageReplyComposerState extends ConsumerState<MessageReplyComposer> {
  bool _isReplying = false;
  bool _isSending = false;
  late List<String> _replyRecipients;
  final TextEditingController _replyController = TextEditingController();
  final FocusNode _replyFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _replyRecipients = [widget.thread.resolveSenderName()];
  }

  @override
  void didUpdateWidget(covariant MessageReplyComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldResolved = oldWidget.thread.resolveSenderName();
    final newResolved = widget.thread.resolveSenderName();
    if (newResolved != oldResolved) {
      if (_replyRecipients.isEmpty ||
          _replyRecipients.every((r) => r.trim().isEmpty) ||
          (_replyRecipients.length == 1 && _replyRecipients.first == oldResolved)) {
        _replyRecipients = [newResolved];
      }
    }
  }

  @override
  void dispose() {
    _replyController.dispose();
    _replyFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    final recipients =
        _replyRecipients.where((r) => r.trim().isNotEmpty).toList();
    if (recipients.isEmpty) {
      recipients.add(widget.thread.resolveSenderName());
    }

    setState(() => _isSending = true);

    try {
      final repo = ref.read(schoolRepositoryProvider);
      final appUser = ref.read(appUserProvider);
      final profile = await repo.getStudentProfile();

      final isStudentRole = appUser?.role == UserRole.student;
      final String senderRole = isStudentRole ? 'Uczeń' : 'Rodzic';
      final String senderName = isStudentRole
          ? (profile.name.trim().isNotEmpty ? profile.name.trim() : 'Uczeń')
          : ((appUser != null &&
                  appUser.displayName.trim().isNotEmpty &&
                  appUser.displayName.trim() != 'Użytkownik')
              ? appUser.displayName.trim()
              : 'Rodzic');
      final nameParts = senderName
          .split(RegExp(r'\s+'))
          .where((p) => p.isNotEmpty)
          .toList();
      final senderInitials = nameParts.isNotEmpty
          ? nameParts.take(2).map((p) => p[0].toUpperCase()).join()
          : 'JA';

      await repo.sendMessage(
        recipientNames: recipients,
        subject: widget.thread.subject.startsWith('Re:')
            ? widget.thread.subject
            : 'Re: ${widget.thread.subject}',
        body: text,
        replyToId: widget.thread.id,
        senderName: senderName,
        senderRole: senderRole,
      );

      final now = DateTime.now();
      final newMsg = MessageItem(
        id: 'reply_${now.millisecondsSinceEpoch}',
        senderName: senderName,
        senderRole: senderRole,
        senderInitials: senderInitials,
        timestamp: now,
        body: text,
        isFromMe: true,
      );

      if (mounted) {
        setState(() {
          _isReplying = false;
          _isSending = false;
          _replyController.clear();
        });
      }

      widget.onReplySent(newMsg);
      ref.invalidate(messagesProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Odpowiedź została wysłana do: ${recipients.join(", ")}',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSending = false);
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
    final defaultSender = widget.thread.resolveSenderName();
    final ccTeacher = widget.thread.extractCcTeacherFromBody();
    final teachers = ref.watch(
      teachersProvider.select((a) => a.value ?? const []),
    );

    if (!_isReplying) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _isReplying = true;
              if (_replyRecipients.isEmpty ||
                  _replyRecipients.every((r) => r.trim().isEmpty)) {
                _replyRecipients = [defaultSender];
              }
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _replyFocusNode.requestFocus();
            });
          },
          icon: const Icon(Icons.reply, size: 18, color: AppColors.primary),
          label: Text('Odpowiedz do $defaultSender'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            backgroundColor: AppColors.surfaceContainerLowest,
            alignment: Alignment.centerLeft,
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    final activeRecipients =
        _replyRecipients.where((r) => r.trim().isNotEmpty).toList();
    if (activeRecipients.isEmpty) {
      activeRecipients.add(defaultSender);
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.reply, size: 18, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text(
                          'Odpowiedź do:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    ...activeRecipients.map((recipient) {
                      final canRemove = activeRecipients.length > 1;
                      return Container(
                        padding: EdgeInsets.only(
                          left: 10,
                          right: canRemove ? 4 : 10,
                          top: 4,
                          bottom: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryFixed,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              recipient,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            if (canRemove) ...[
                              const SizedBox(width: 4),
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _replyRecipients.remove(recipient);
                                  });
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                    if (ccTeacher != null &&
                        !activeRecipients.any(
                          (r) =>
                              r.toLowerCase().contains(ccTeacher.toLowerCase()),
                        ))
                      ActionChip(
                        avatar: const Icon(
                          Icons.person_add_alt_1_rounded,
                          size: 14,
                          color: AppColors.secondary,
                        ),
                        label: Text(
                          '+ DW: $ccTeacher',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondary,
                          ),
                        ),
                        visualDensity: VisualDensity.compact,
                        backgroundColor:
                            AppColors.secondaryContainer.withValues(alpha: 0.5),
                        side: BorderSide(
                          color: AppColors.secondary.withValues(alpha: 0.35),
                        ),
                        onPressed: () {
                          setState(() {
                            _replyRecipients.add(ccTeacher);
                          });
                        },
                      ),
                    if (teachers.isNotEmpty)
                      PopupMenuButton<String>(
                        tooltip: 'Dodaj adresata z listy nauczycieli',
                        onSelected: (selectedName) {
                          if (!_replyRecipients.contains(selectedName)) {
                            setState(() {
                              _replyRecipients.add(selectedName);
                            });
                          }
                        },
                        itemBuilder: (context) {
                          return teachers.map((t) {
                            final label = t.subjectName.isNotEmpty
                                ? '${t.name} (${t.subjectName})'
                                : t.name;
                            return PopupMenuItem<String>(
                              value: t.name,
                              child: Text(
                                label,
                                style: const TextStyle(fontSize: 13),
                              ),
                            );
                          }).toList();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  AppColors.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 14,
                                color: AppColors.onSurfaceVariant,
                              ),
                              SizedBox(width: 2),
                              Text(
                                'Dodaj adresata',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon:
                    const Icon(Icons.close, size: 18, color: AppColors.outline),
                onPressed: () {
                  setState(() {
                    _isReplying = false;
                    _replyController.clear();
                  });
                },
                tooltip: 'Anuluj',
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _replyController,
            focusNode: _replyFocusNode,
            maxLines: 6,
            minLines: 3,
            decoration: InputDecoration(
              hintText: 'Napisz odpowiedź do: ${activeRecipients.join(", ")}...',
              hintStyle:
                  const TextStyle(fontSize: 13, color: AppColors.outline),
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.surfaceContainerHigh),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _isSending
                    ? null
                    : () {
                        setState(() {
                          _isReplying = false;
                          _replyController.clear();
                        });
                      },
                child: const Text('Anuluj'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isSending ? null : _handleSendReply,
                icon: _isSending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send, size: 16),
                label: Text(_isSending ? 'Wysyłanie...' : 'Wyślij odpowiedź'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
