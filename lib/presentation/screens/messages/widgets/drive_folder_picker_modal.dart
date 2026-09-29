import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../domain/models/message_thread.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/school_providers.dart';

enum _DriveFolderModalMode {
  moveAttachments,
  defaultSettings,
}

class DriveFolderPickerModal extends ConsumerStatefulWidget {
  final _DriveFolderModalMode _mode;
  final String? msgId;
  final List<String> attachmentNames;
  final Map<String, DriveAttachmentInfo> currentDriveAttachments;
  final DriveFolderOption initialFolder;

  const DriveFolderPickerModal._({
    required _DriveFolderModalMode mode,
    this.msgId,
    this.attachmentNames = const [],
    this.currentDriveAttachments = const {},
    this.initialFolder = DriveFolderOption.rootFolder,
  }) : _mode = mode;

  static Future<DriveFolderOption?> showMoveDialog(
    BuildContext context, {
    required String msgId,
    required List<String> attachmentNames,
    required Map<String, DriveAttachmentInfo> currentDriveAttachments,
    required DriveFolderOption initialFolder,
  }) {
    return showDialog<DriveFolderOption>(
      context: context,
      builder: (ctx) => DriveFolderPickerModal._(
        mode: _DriveFolderModalMode.moveAttachments,
        msgId: msgId,
        attachmentNames: attachmentNames,
        currentDriveAttachments: currentDriveAttachments,
        initialFolder: initialFolder,
      ),
    );
  }

  static Future<DriveFolderOption?> showDefaultFolderSettings(
    BuildContext context,
  ) {
    return showDialog<DriveFolderOption>(
      context: context,
      builder: (ctx) => const DriveFolderPickerModal._(
        mode: _DriveFolderModalMode.defaultSettings,
      ),
    );
  }

  @override
  ConsumerState<DriveFolderPickerModal> createState() =>
      _DriveFolderPickerModalState();
}

class _DriveFolderPickerModalState
    extends ConsumerState<DriveFolderPickerModal> {
  late DriveFolderOption _selectedFolder;
  List<DriveFolderOption> _folders = const [];
  bool _isLoadingFolders = true;
  bool _isCreatingFolder = false;
  bool _isSubmitting = false;
  bool _setAsDefault = true;
  String? _errorMessage;
  final TextEditingController _newFolderController = TextEditingController();

  bool get _isMoveMode =>
      widget._mode == _DriveFolderModalMode.moveAttachments;

  @override
  void initState() {
    super.initState();
    _selectedFolder = widget.initialFolder;
    _loadFoldersAndDefault();
  }

  @override
  void dispose() {
    _newFolderController.dispose();
    super.dispose();
  }

  Future<String> _acquireToken({bool forceRefresh = false}) async {
    final authService = ref.read(firebaseAuthServiceProvider);
    if (!forceRefresh && authService.hasValidDriveAccessToken) {
      try {
        final cached = await authService.requestGoogleDriveAccessToken();
        if (cached != null && cached.isNotEmpty) return cached;
      } catch (_) {}
    }
    if (!authService.isSignedIn) {
      return 'demo_access_token';
    }
    try {
      final token = await authService.requestGoogleDriveAccessToken(
        forceRefresh: forceRefresh,
      );
      if (token != null && token.isNotEmpty) {
        return token;
      }
    } catch (_) {}
    return 'demo_access_token';
  }

  Future<void> _loadFoldersAndDefault() async {
    setState(() {
      _isLoadingFolders = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(schoolRepositoryProvider);
      final defaultFolder = await repo.getDefaultDriveFolder();
      final token = await _acquireToken();
      final fetched = await repo.listDriveFolders(accessToken: token);

      if (!mounted) return;
      final customFolders = <DriveFolderOption>[];
      final seenIds = <String>{'root'};

      for (final f in fetched) {
        if (f.id.isNotEmpty && seenIds.add(f.id)) {
          customFolders.add(f);
        }
      }

      final targetInitial = _isMoveMode ? widget.initialFolder : defaultFolder;
      if (targetInitial.id != 'root' && seenIds.add(targetInitial.id)) {
        customFolders.insert(0, targetInitial);
      }

      setState(() {
        _folders = customFolders;
        _selectedFolder = targetInitial;
        _isLoadingFolders = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingFolders = false;
        _errorMessage = 'Nie udało się pobrać listy folderów: $e';
      });
    }
  }

  Future<void> _handleCreateFolder([String? presetName]) async {
    final rawName = (presetName ?? _newFolderController.text).trim();
    if (rawName.isEmpty) {
      setState(() {
        _errorMessage = 'Podaj nazwę nowego folderu.';
      });
      return;
    }
    if (rawName.length > 120) {
      setState(() {
        _errorMessage = 'Nazwa folderu jest zbyt długa (maks. 120 znaków).';
      });
      return;
    }

    setState(() {
      _isCreatingFolder = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(schoolRepositoryProvider);
      final token = await _acquireToken();
      final created = await repo.createDriveFolder(
        accessToken: token,
        folderName: rawName,
        setAsDefault: _isMoveMode ? _setAsDefault : true,
      );
      if (!mounted) return;
      setState(() {
        _folders = [
          created,
          ..._folders.where((f) => f.id != created.id && f.id != 'root'),
        ];
        _selectedFolder = created;
        _newFolderController.clear();
        _isCreatingFolder = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isCreatingFolder = false;
        _errorMessage = 'Błąd tworzenia folderu: $e';
      });
    }
  }

  Future<void> _handleConfirm() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(schoolRepositoryProvider);
      if (_isMoveMode) {
        final token = await _acquireToken();
        await repo.moveDriveAttachment(
          accessToken: token,
          msgId: widget.msgId ?? '',
          attachmentNames: widget.attachmentNames,
          currentDriveAttachments: widget.currentDriveAttachments,
          targetFolderId: _selectedFolder.id,
          targetFolderName: _selectedFolder.name,
          setAsDefault: _setAsDefault,
        );
        if (_setAsDefault) {
          await repo.setDefaultDriveFolder(_selectedFolder);
        }
        if (!mounted) return;
        Navigator.of(context).pop(_selectedFolder);
      } else {
        await repo.setDefaultDriveFolder(_selectedFolder);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Domyślny folder Google Drive: ${_selectedFolder.name}',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(_selectedFolder);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Operacja nie powiodła się: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final allOptions = <DriveFolderOption>[
      DriveFolderOption.rootFolder,
      ..._folders,
    ];

    return Dialog(
      backgroundColor: AppColors.surfaceContainerLowest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 560),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryFixed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_to_drive_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isMoveMode
                              ? 'Zmień folder / Przenieś na Dysku Google'
                              : 'Domyślny folder Google Drive',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isMoveMode
                              ? 'Wybierz docelowy folder dla ${widget.attachmentNames.length == 1 ? "załącznika" : "${widget.attachmentNames.length} załączników"}'
                              : 'Załączniki z wiadomości będą od razu zapisywane w wybranym folderze',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    tooltip: 'Zamknij',
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'DOSTĘPNE FOLDERY NA DYSKU GOOGLE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (_isLoadingFolders)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.surfaceContainerHigh,
                            ),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < allOptions.length; i++) ...[
                                if (i > 0)
                                  const Divider(height: 1, thickness: 0.6),
                                _buildFolderOptionTile(allOptions[i]),
                              ],
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),
                      const Text(
                        'UTWÓRZ NOWY FOLDER',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.onSurfaceVariant,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _newFolderController,
                              enabled: !_isCreatingFolder && !_isSubmitting,
                              decoration: InputDecoration(
                                hintText: 'Np. Szkoła - Oskar',
                                hintStyle: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.outline,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                filled: true,
                                fillColor: AppColors.surfaceContainerLow,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(
                                    color: AppColors.surfaceContainerHigh,
                                  ),
                                ),
                              ),
                              style: const TextStyle(fontSize: 13),
                              onSubmitted: (_) => _handleCreateFolder(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.tonalIcon(
                            onPressed: (_isCreatingFolder || _isSubmitting)
                                ? null
                                : () => _handleCreateFolder(),
                            icon: _isCreatingFolder
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons.create_new_folder_rounded,
                                    size: 16,
                                  ),
                            label: const Text('Utwórz'),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          ActionChip(
                            avatar: const Icon(
                              Icons.folder_special_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            label: const Text(
                              'EduSync - Załączniki szkolne',
                              style: TextStyle(fontSize: 11),
                            ),
                            visualDensity: VisualDensity.compact,
                            onPressed: (_isCreatingFolder || _isSubmitting)
                                ? null
                                : () {
                                    _newFolderController.text =
                                        'EduSync - Załączniki szkolne';
                                  },
                          ),
                        ],
                      ),
                      if (_isMoveMode) ...[
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          value: _setAsDefault,
                          onChanged: _isSubmitting
                              ? null
                              : (val) {
                                  setState(() {
                                    _setAsDefault = val ?? true;
                                  });
                                },
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          title: const Text(
                            'Ustaw jako domyślny folder dla przyszłych załączników',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      ],
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Anuluj'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: (_isSubmitting || _isLoadingFolders)
                        ? null
                        : _handleConfirm,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(
                            _isMoveMode
                                ? Icons.drive_file_move_rounded
                                : Icons.check_rounded,
                            size: 16,
                          ),
                    label: Text(
                      _isMoveMode
                          ? 'Przenieś tutaj'
                          : 'Zapisz domyślny folder',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFolderOptionTile(DriveFolderOption option) {
    final isSelected = _selectedFolder.id == option.id;
    final isRoot = option.id == 'root';

    return InkWell(
      key: ValueKey('drive_folder_option_${option.id}'),
      onTap: _isSubmitting
          ? null
          : () {
              setState(() {
                _selectedFolder = option;
              });
            },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              isRoot ? Icons.cloud_outlined : Icons.folder_rounded,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRoot ? 'Mój dysk (katalog główny)' : option.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: AppColors.onSurface,
                    ),
                  ),
                  if (isRoot)
                    const Text(
                      'Mój dysk',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              size: 18,
              color: isSelected ? AppColors.primary : AppColors.outline,
            ),
          ],
        ),
      ),
    );
  }
}
