import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/calendar_browser_helper_stub.dart'
    if (dart.library.js_interop) '../../../core/utils/calendar_browser_helper_web.dart';
import '../../../domain/models/message_thread.dart';
import '../../providers/auth_providers.dart';
import '../../providers/school_providers.dart';
import 'widgets/drive_folder_picker_modal.dart';
import 'widgets/message_accordion_tile.dart';
import 'widgets/message_reply_composer.dart';
import 'widgets/message_task_banner.dart';
import 'widgets/message_thread_header_card.dart';

class MessageThreadScreen extends ConsumerStatefulWidget {
  final MessageThread thread;
  const MessageThreadScreen({super.key, required this.thread});

  @override
  ConsumerState<MessageThreadScreen> createState() => _MessageThreadScreenState();
}

class _MessageThreadScreenState extends ConsumerState<MessageThreadScreen> {
  late MessageThread _currentThread;
  final Set<String> _expandedMessageIds = {};
  final Set<String> _savingDriveAttachments = {};
  bool _isSavingAllDrive = false;
  bool _isLoadingBody = false;

  @override
  void initState() {
    super.initState();
    _currentThread = widget.thread.withNormalizedSenderName();
    if (_currentThread.messages.isNotEmpty) {
      _expandedMessageIds.add(_currentThread.messages.last.id);
    }
    if (_currentThread.isUnread) _markAsReadOnOpen();
    _fetchBodyIfNeeded();
  }

  void _showSnackBar(String message, {Color? backgroundColor, SnackBarAction? action, Duration? duration}) {
    if (!mounted) return;
    if (action != null) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      duration: duration ?? const Duration(seconds: 4),
      action: action,
    ));
  }

  Future<void> _markAsReadOnOpen() async {
    try {
      await ref.read(schoolRepositoryProvider).markMessageAsRead(_currentThread.id, isRead: true);
      if (mounted) {
        setState(() => _currentThread = _currentThread.copyWith(isUnread: false));
        ref.invalidate(messagesProvider);
      }
    } catch (_) {}
  }

  Future<void> _toggleReadStatus() async {
    final newIsUnread = !_currentThread.isUnread;
    setState(() => _currentThread = _currentThread.copyWith(isUnread: newIsUnread));
    try {
      await ref.read(schoolRepositoryProvider).markMessageAsRead(_currentThread.id, isRead: !newIsUnread);
      ref.invalidate(messagesProvider);
      _showSnackBar(
        newIsUnread ? 'Oznaczono jako nieprzeczytana' : 'Oznaczono jako przeczytana',
        duration: const Duration(seconds: 2),
      );
    } catch (_) {}
  }

  Future<void> _toggleArchiveStatus() async {
    final newIsArchived = !_currentThread.isArchived;
    setState(() {
      _currentThread = _currentThread.copyWith(
        isArchived: newIsArchived,
        isUnread: newIsArchived ? false : _currentThread.isUnread,
      );
    });
    try {
      await ref.read(schoolRepositoryProvider).archiveMessage(
        _currentThread.id,
        isArchived: newIsArchived,
      );
      ref.invalidate(messagesProvider);
      _showSnackBar(
        newIsArchived
            ? 'Wiadomość przeniesiona do archiwum'
            : 'Przywrócono wiadomość do skrzynki odbiorczej',
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Cofnij',
          onPressed: () async {
            await ref.read(schoolRepositoryProvider).archiveMessage(
              _currentThread.id,
              isArchived: !newIsArchived,
            );
            if (mounted) {
              setState(() => _currentThread = _currentThread.copyWith(isArchived: !newIsArchived));
            }
            ref.invalidate(messagesProvider);
          },
        ),
      );
    } catch (_) {}
  }

  Future<void> _fetchBodyIfNeeded({bool force = false}) async {
    if (!force && !_currentThread.needsDetailsFetch) return;
    if (mounted) setState(() => _isLoadingBody = true);
    try {
      final details = await ref.read(schoolRepositoryProvider).getMessageDetails(_currentThread.id);
      if (details != null && mounted) {
        setState(() {
          _currentThread = _currentThread.withMergedDetails(details);
          _isLoadingBody = false;
        });
        if (details.attachments.isNotEmpty) ref.invalidate(messagesProvider);
        return;
      }
    } catch (e) {
      debugPrint('Error loading full message details: $e');
    }
    if (mounted) setState(() => _isLoadingBody = false);
  }

  void _toggleMessageExpansion(String messageId) {
    setState(() {
      if (!_expandedMessageIds.remove(messageId)) _expandedMessageIds.add(messageId);
    });
  }

  Future<String?> _resolveAttachmentDownloadPath(String fileName, MessageItem message) async {
    String? path = message.attachmentUrls[fileName] ?? _currentThread.attachmentUrls[fileName];
    if (path == null || path.isEmpty) {
      try {
        final details = await ref.read(schoolRepositoryProvider).getMessageDetails(_currentThread.id);
        if (details != null) {
          path = details.attachmentUrls[fileName];
          if (mounted && details.attachmentUrls.isNotEmpty) {
            setState(() => _currentThread = _currentThread.copyWith(attachmentUrls: details.attachmentUrls));
          }
        }
      } catch (_) {}
    }
    return path;
  }

  Future<void> _downloadAttachment(String fileName, MessageItem message) async {
    final downloadPath = await _resolveAttachmentDownloadPath(fileName, message);
    if (downloadPath != null && downloadPath.isNotEmpty) {
      final url = '/api/downloadAttachment?path=${Uri.encodeComponent(downloadPath)}';
      if (!openUrlInBrowser(url)) _showSnackBar('Pobieranie załącznika: $fileName');
      return;
    }
    _showSnackBar('Załącznik „$fileName” (tryb demonstracyjny)');
  }

  Future<String?> _acquireDriveTokenOrDemo({bool forceRefresh = false}) async {
    final authService = ref.read(firebaseAuthServiceProvider);
    if (!forceRefresh && authService.hasValidDriveAccessToken) {
      return authService.requestGoogleDriveAccessToken();
    }
    if (!authService.isSignedIn) return 'demo_access_token';
    try {
      return await authService.requestGoogleDriveAccessToken(forceRefresh: forceRefresh);
    } catch (e) {
      debugPrint('OAuth token acquisition error: $e');
      return null;
    }
  }

  Future<DriveAttachmentInfo> _uploadSingleAttachmentWithRetry(
    String fileName,
    MessageItem message,
    String initialAccessToken,
  ) async {
    final repo = ref.read(schoolRepositoryProvider);
    final savedBy = (ref.read(appUserProvider)?.isStudent ?? false) ? 'Uczeń (Oskar)' : 'Rodzic';
    final resolvedPath = await _resolveAttachmentDownloadPath(fileName, message);
    final path = (resolvedPath != null && resolvedPath.isNotEmpty)
        ? resolvedPath
        : '/wiadomosci/pobierz_zalacznik/${_currentThread.id}/0';
    Future<DriveAttachmentInfo> doUpload(String token) => repo.saveAttachmentToDrive(
      msgId: _currentThread.id, attachmentName: fileName, downloadPath: path, accessToken: token, savedBy: savedBy,
    );
    try {
      return await doUpload(initialAccessToken);
    } catch (e) {
      if (e.toString().contains('UNAUTHENTICATED_DRIVE')) {
        ref.read(firebaseAuthServiceProvider).clearDriveAccessToken();
        final fresh = await _acquireDriveTokenOrDemo(forceRefresh: true);
        if (fresh != null && fresh.isNotEmpty) return await doUpload(fresh);
      }
      rethrow;
    }
  }

  Future<void> _saveAttachmentsToDrive(MessageItem message, List<String> filesToSave, {required bool isBulk}) async {
    if (filesToSave.isEmpty) return;
    if (isBulk && _isSavingAllDrive) return;
    if (!isBulk && _savingDriveAttachments.contains('${message.id}::${filesToSave.first}')) return;

    final accessToken = await _acquireDriveTokenOrDemo();
    if (accessToken == null || accessToken.isEmpty) {
      return _showSnackBar('Nie udało się uzyskać autoryzacji Google Drive. Spróbuj ponownie.', backgroundColor: AppColors.error);
    }
    if (mounted) {
      setState(() {
        if (isBulk) _isSavingAllDrive = true;
        _savingDriveAttachments.addAll(filesToSave.map((f) => '${message.id}::$f'));
      });
    }

    final savedNames = <String>[];
    DriveAttachmentInfo? lastSavedInfo;
    try {
      for (final fileName in filesToSave) {
        final info = await _uploadSingleAttachmentWithRetry(fileName, message, accessToken);
        savedNames.add(fileName);
        lastSavedInfo = info;
        if (mounted) {
          setState(() {
            _savingDriveAttachments.remove('${message.id}::$fileName');
            _currentThread = _currentThread.withSavedDriveAttachments(message.id, {fileName: info});
          });
        }
      }
      if (!mounted) return;
      if (isBulk) setState(() => _isSavingAllDrive = false);
      ref.invalidate(messagesProvider);

      if (lastSavedInfo != null && savedNames.isNotEmpty) {
        final info = lastSavedInfo;
        final text = savedNames.length == 1
            ? 'Zapisano „${savedNames.first}” w: ${info.folderName}'
            : 'Zapisano ${savedNames.length} załączniki w: ${info.folderName}';
        _showSnackBar(
          text,
          duration: const Duration(seconds: 6),
          action: SnackBarAction(
            label: 'Zmień folder / Przenieś',
            onPressed: () => _openDriveMoveModal(message, savedNames, info),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (isBulk) _isSavingAllDrive = false;
        _savingDriveAttachments.removeAll(filesToSave.map((f) => '${message.id}::$f'));
      });
      _showSnackBar(
        isBulk ? 'Błąd zapisu załączników na Google Drive: $e' : 'Błąd zapisu na Google Drive: $e',
        backgroundColor: AppColors.error,
      );
    }
  }

  Future<void> _saveAttachmentToDrive(String fileName, MessageItem message) =>
      _saveAttachmentsToDrive(message, [fileName], isBulk: false);

  Future<void> _saveAllAttachmentsToDrive(MessageItem message) =>
      _saveAttachmentsToDrive(message, _currentThread.unsavedAttachmentsFor(message), isBulk: true);

  void _openSavedDriveAttachment(DriveAttachmentInfo info) {
    final link = info.webViewLink.trim();
    if (!link.startsWith('https://drive.google.com/') && !link.startsWith('https://docs.google.com/')) {
      return _showSnackBar('Nieprawidłowy link Google Drive.', backgroundColor: AppColors.error);
    }
    if (!openUrlInBrowser(link)) _showSnackBar('Otwieranie w Google Drive (${info.folderName})');
  }

  Future<void> _openDriveMoveModal(MessageItem message, List<String> names, DriveAttachmentInfo currentInfo) async {
    final currentDriveMap = {..._currentThread.driveAttachments, ...message.driveAttachments};
    final newFolder = await DriveFolderPickerModal.showMoveDialog(
      context,
      msgId: _currentThread.id,
      attachmentNames: names,
      currentDriveAttachments: currentDriveMap,
      initialFolder: DriveFolderOption(id: currentInfo.folderId, name: currentInfo.folderName),
    );
    if (newFolder == null || !mounted) return;
    final updated = {
      for (final n in names) n: (currentDriveMap[n] ?? currentInfo).copyWith(folderId: newFolder.id, folderName: newFolder.name),
    };
    setState(() => _currentThread = _currentThread.withSavedDriveAttachments(message.id, updated));
    ref.invalidate(messagesProvider);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    _showSnackBar('Przeniesiono do folderu: ${newFolder.name}');
  }

  @override
  Widget build(BuildContext context) {
    final messages = _currentThread.messages;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => context.canPop() ? context.pop() : context.go('/wiadomosci'),
          tooltip: 'Wróć',
        ),
        title: Text(
          _currentThread.subject,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.onSurface),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          MessageAppBarTaskAction(thread: _currentThread),
          IconButton(
            key: const ValueKey('thread_archive_action_button'),
            icon: Icon(
              _currentThread.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
              color: _currentThread.isArchived ? AppColors.primary : AppColors.onSurfaceVariant,
              size: 22,
            ),
            tooltip: _currentThread.isArchived ? 'Przywróć do skrzynki' : 'Archiwizuj wiadomość',
            onPressed: _toggleArchiveStatus,
          ),
          IconButton(
            icon: Icon(
              _currentThread.isUnread ? Icons.mark_email_read_outlined : Icons.mark_email_unread_outlined,
              color: AppColors.onSurfaceVariant,
              size: 22,
            ),
            tooltip: _currentThread.isUnread ? 'Oznacz jako przeczytana' : 'Oznacz jako nieprzeczytana',
            onPressed: _toggleReadStatus,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.onSurfaceVariant, size: 22),
            tooltip: 'Odśwież wątek',
            onPressed: () {
              ref.invalidate(messagesProvider);
              _fetchBodyIfNeeded(force: true);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        children: [
          MessageThreadHeaderCard(thread: _currentThread),
          const SizedBox(height: 12),
          MessageTaskBanner(thread: _currentThread),
          const SizedBox(height: 16),
          for (int i = 0; i < messages.length; i++) ...[
            MessageAccordionTile(
              message: messages[i],
              threadSubject: _currentThread.subject,
              threadDriveAttachments: _currentThread.driveAttachments,
              isFirstMessage: i == 0,
              isExpanded: _expandedMessageIds.contains(messages[i].id),
              isLoadingBody: _isLoadingBody,
              isSavingAllDrive: _isSavingAllDrive,
              savingDriveAttachments: _savingDriveAttachments,
              onToggleExpansion: () => _toggleMessageExpansion(messages[i].id),
              onDownloadAttachment: _downloadAttachment,
              onSaveAttachmentToDrive: _saveAttachmentToDrive,
              onSaveAllAttachmentsToDrive: _saveAllAttachmentsToDrive,
              onOpenSavedDriveAttachment: _openSavedDriveAttachment,
            ),
            const SizedBox(height: 10),
          ],
          MessageReplyComposer(
            thread: _currentThread,
            onReplySent: (newMsg) => setState(() {
              _currentThread = _currentThread.copyWith(messages: [..._currentThread.messages, newMsg]);
              _expandedMessageIds.add(newMsg.id);
            }),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }
}
