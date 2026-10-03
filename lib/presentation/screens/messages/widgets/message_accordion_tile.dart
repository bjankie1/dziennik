import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/message_thread.dart';
import '../../../widgets/linkified_text.dart';

class MessageAccordionTile extends StatelessWidget {
  final MessageItem message;
  final String threadSubject;
  final Map<String, DriveAttachmentInfo> threadDriveAttachments;
  final bool isFirstMessage;
  final bool isExpanded;
  final bool isLoadingBody;
  final bool isSavingAllDrive;
  final Set<String> savingDriveAttachments;
  final VoidCallback onToggleExpansion;
  final void Function(String fileName, MessageItem message) onDownloadAttachment;
  final void Function(String fileName, MessageItem message) onSaveAttachmentToDrive;
  final void Function(MessageItem message) onSaveAllAttachmentsToDrive;
  final void Function(DriveAttachmentInfo info) onOpenSavedDriveAttachment;

  const MessageAccordionTile({
    super.key,
    required this.message,
    required this.threadSubject,
    required this.threadDriveAttachments,
    required this.isFirstMessage,
    required this.isExpanded,
    required this.isLoadingBody,
    required this.isSavingAllDrive,
    required this.savingDriveAttachments,
    required this.onToggleExpansion,
    required this.onDownloadAttachment,
    required this.onSaveAttachmentToDrive,
    required this.onSaveAllAttachmentsToDrive,
    required this.onOpenSavedDriveAttachment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: message.isFromMe
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.surfaceContainerHigh,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: isExpanded
          ? _buildExpandedMessage()
          : _buildCollapsedMessage(),
    );
  }

  Widget _buildCollapsedMessage() {
    return InkWell(
      onTap: onToggleExpansion,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: message.isFromMe
                  ? AppColors.primaryContainer
                  : AppColors.surfaceContainerHigh,
              child: Text(
                message.senderInitials,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: message.isFromMe
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        message.isFromMe
                            ? 'Ja (${message.senderName})'
                            : message.senderName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        DateFormat('d MMM, HH:mm', 'pl').format(message.timestamp),
                        style: const TextStyle(fontSize: 11, color: AppColors.outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.body.replaceAll('\n', ' '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.expand_more, size: 18, color: AppColors.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedMessage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggleExpansion,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: message.isFromMe
                      ? AppColors.primaryContainer
                      : AppColors.surfaceContainerHigh,
                  child: Text(
                    message.senderInitials,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: message.isFromMe
                          ? AppColors.onPrimaryContainer
                          : AppColors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.isFromMe
                            ? 'Ja (${message.senderName})'
                            : message.senderName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurface,
                        ),
                      ),
                      Text(
                        '${message.senderRole} • ${DateFormat("d MMMM yyyy, HH:mm", "pl").format(message.timestamp)}',
                        style: const TextStyle(fontSize: 11, color: AppColors.outline),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.expand_less, size: 20, color: AppColors.outline),
                  onPressed: onToggleExpansion,
                  tooltip: 'Zwiń wiadomość',
                ),
              ],
            ),
          ),
          const Divider(height: 24, thickness: 0.8),

          if (isLoadingBody &&
              !message.isFromMe &&
              isFirstMessage &&
              (message.body.trim().isEmpty ||
                  message.body.trim() == threadSubject.trim())) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Pobieranie pełnej treści wiadomości z Librusa...',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            LinkifiedSelectableText(
              message.body,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.onSurface,
              ),
            ),
            if (isLoadingBody &&
                !message.isFromMe &&
                isFirstMessage &&
                message.attachments.isEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sprawdzanie załączników w Librusie...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.8),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ],

          if (message.attachments.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildAttachmentsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachmentsSection() {
    final effectiveDriveAttachments = <String, DriveAttachmentInfo>{
      ...threadDriveAttachments,
      ...message.driveAttachments,
    };
    final hasUnsaved = message.attachments.any(
      (f) => !effectiveDriveAttachments.containsKey(f),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Załączniki (${message.attachments.length}):',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            if (message.attachments.length >= 2)
              if (hasUnsaved)
                TextButton.icon(
                  key: const ValueKey('save_all_drive_button'),
                  onPressed: isSavingAllDrive
                      ? null
                      : () => onSaveAllAttachmentsToDrive(message),
                  icon: isSavingAllDrive
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(
                          Icons.add_to_drive_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                  label: const Text(
                    'Zapisz wszystkie na Dysku',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_done_rounded,
                        size: 14,
                        color: AppColors.secondary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Zapisano wszystkie na Dysku',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: message.attachments.map((file) {
            final (iconData, iconColor) = _attachmentIconAndColor(file);
            final driveInfo = effectiveDriveAttachments[file];
            final isSavingToDrive = savingDriveAttachments.contains(
              '${message.id}::$file',
            );

            return Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: driveInfo != null
                      ? AppColors.secondary.withValues(alpha: 0.45)
                      : AppColors.surfaceContainerHigh,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: InkWell(
                      key: ValueKey('download_attachment_$file'),
                      onTap: () => onDownloadAttachment(file, message),
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(10),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(iconData, size: 18, color: iconColor),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                file,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Tooltip(
                              message: 'Pobierz na urządzenie',
                              child: Icon(
                                Icons.download_rounded,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 20,
                    color: AppColors.surfaceContainerHigh,
                  ),
                  if (isSavingToDrive)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: SizedBox(
                        key: ValueKey('drive_spinner_$file'),
                        width: 16,
                        height: 16,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    )
                  else if (driveInfo != null)
                    Tooltip(
                      message: 'Otwórz w Google Drive (${driveInfo.folderName})',
                      child: InkWell(
                        key: ValueKey('open_drive_$file'),
                        onTap: () => onOpenSavedDriveAttachment(driveInfo),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(10),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.open_in_new_rounded,
                                size: 15,
                                color: AppColors.secondary,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Otwórz w Google Drive',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Tooltip(
                      message: 'Zapisz na Dysku Google',
                      child: InkWell(
                        key: ValueKey('save_drive_$file'),
                        onTap: () => onSaveAttachmentToDrive(file, message),
                        borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(10),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          child: Icon(
                            Icons.add_to_drive_rounded,
                            size: 17,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static (IconData, Color) _attachmentIconAndColor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) {
      return (Icons.picture_as_pdf_rounded, AppColors.error);
    }
    if (lower.endsWith('.ppt') || lower.endsWith('.pptx')) {
      return (Icons.slideshow_rounded, const Color(0xFFD84315));
    }
    if (lower.endsWith('.doc') || lower.endsWith('.docx') || lower.endsWith('.odt')) {
      return (Icons.description_rounded, const Color(0xFF1565C0));
    }
    if (lower.endsWith('.xls') || lower.endsWith('.xlsx') || lower.endsWith('.csv')) {
      return (Icons.table_chart_rounded, const Color(0xFF2E7D32));
    }
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp')) {
      return (Icons.image_rounded, const Color(0xFF6A1B9A));
    }
    if (lower.endsWith('.zip') || lower.endsWith('.rar') || lower.endsWith('.7z')) {
      return (Icons.folder_zip_rounded, const Color(0xFFF57F17));
    }
    return (Icons.attach_file_rounded, AppColors.primary);
  }
}
