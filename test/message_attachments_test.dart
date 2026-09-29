import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:edusync/domain/models/message_thread.dart';
import 'package:edusync/presentation/providers/school_providers.dart';
import 'package:edusync/data/repositories/mock_school_repository.dart';
import 'package:edusync/presentation/screens/messages/message_thread_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('pl_PL', null);
    await initializeDateFormatting('pl', null);
  });

  testWidgets(
    'MessageThreadScreen displays PDF and PPTX attachments for message 2027508',
    (tester) async {
      final thread = MessageThread(
        id: '2027508',
        senderName: 'Sobota Łukasz',
        senderInitials: 'SŁ',
        senderRole: 'Nauczyciel',
        subject: 'Informacje na temat egzaminu maturalnego',
        preview: 'Dzień dobry, przesyłam Państwu obiecaną prezentację.',
        body: 'Dzień dobry,\n\nprzesyłam Państwu obiecaną prezentację.\n\nPozdrawiam,\nŁukasz Sobota',
        timestamp: DateTime(2026, 9, 28, 9, 54),
        isUnread: false,
        attachments: const [
          'matura2027_wrzesien2026_R_U.pdf',
          'matura2027_wrzesien2026_R_U.pptx',
        ],
        attachmentUrls: const {
          'matura2027_wrzesien2026_R_U.pdf': '/wiadomosci/pobierz_zalacznik/2027508/12466101',
          'matura2027_wrzesien2026_R_U.pptx': '/wiadomosci/pobierz_zalacznik/2027508/12466102',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolRepositoryProvider.overrideWithValue(MockSchoolRepository()),
          ],
          child: MaterialApp(
            home: MessageThreadScreen(thread: thread),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Załączniki (2):'), findsOneWidget);
      expect(find.text('matura2027_wrzesien2026_R_U.pdf'), findsOneWidget);
      expect(find.text('matura2027_wrzesien2026_R_U.pptx'), findsOneWidget);
      expect(find.byIcon(Icons.picture_as_pdf_rounded), findsOneWidget);
      expect(find.byIcon(Icons.slideshow_rounded), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsNWidgets(2));
      expect(find.byTooltip('Zapisz na Dysku Google'), findsNWidgets(2));
      expect(find.text('Zapisz wszystkie na Dysku'), findsOneWidget);
    },
  );

  testWidgets(
    'MessageThreadScreen hides bulk Zapisz wszystkie na Dysku button when message has 1 attachment',
    (tester) async {
      final singleAttThread = MessageThread(
        id: '2027509',
        senderName: 'Sobota Łukasz',
        senderInitials: 'SŁ',
        senderRole: 'Nauczyciel',
        subject: 'Harmonogram',
        preview: 'Załączam plik PDF.',
        body: 'Dzień dobry,\n\nzałączam plik PDF.\n\nPozdrawiam,\nŁukasz Sobota',
        timestamp: DateTime(2026, 9, 28, 10, 0),
        isUnread: false,
        attachments: const ['harmonogram.pdf'],
        attachmentUrls: const {
          'harmonogram.pdf': '/wiadomosci/pobierz_zalacznik/2027509/1',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolRepositoryProvider.overrideWithValue(MockSchoolRepository()),
          ],
          child: MaterialApp(
            home: MessageThreadScreen(thread: singleAttThread),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Załączniki (1):'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
      expect(find.byTooltip('Zapisz na Dysku Google'), findsOneWidget);
      expect(find.text('Zapisz wszystkie na Dysku'), findsNothing);
    },
  );

  testWidgets(
    'Clicking Zapisz na Dysku Google shows spinner, saves to Mój dysk, transitions to Otwórz w Google Drive, and opens DriveFolderPickerModal via Zmień folder / Przenieś',
    (tester) async {
      final mockRepo = MockSchoolRepository();
      final thread = MessageThread(
        id: 'msg_001',
        senderName: 'Sobota Łukasz',
        senderInitials: 'SŁ',
        senderRole: 'Nauczyciel',
        subject: 'Informacje na temat egzaminu maturalnego',
        preview: 'Dzień dobry, przesyłam Państwu obiecaną prezentację.',
        body: 'Dzień dobry,\n\nprzesyłam Państwu obiecaną prezentację.\n\nPozdrawiam,\nŁukasz Sobota',
        timestamp: DateTime(2026, 9, 28, 9, 54),
        isUnread: false,
        attachments: const [
          'matura2027_wrzesien2026_R_U.pdf',
          'matura2027_wrzesien2026_R_U.pptx',
        ],
        attachmentUrls: const {
          'matura2027_wrzesien2026_R_U.pdf': '/wiadomosci/pobierz_zalacznik/msg_001/12466101',
          'matura2027_wrzesien2026_R_U.pptx': '/wiadomosci/pobierz_zalacznik/msg_001/12466102',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: MessageThreadScreen(thread: thread),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final savePdfBtn = find.byKey(
        const ValueKey('save_drive_matura2027_wrzesien2026_R_U.pdf'),
      );
      expect(savePdfBtn, findsOneWidget);

      await tester.ensureVisible(savePdfBtn);
      await tester.pumpAndSettle();
      await tester.tap(savePdfBtn);
      await tester.pump(const Duration(milliseconds: 20));

      // Verify loading spinner appears on the chip while saving (D-06)
      expect(
        find.byKey(
          const ValueKey('drive_spinner_matura2027_wrzesien2026_R_U.pdf'),
        ),
        findsOneWidget,
      );

      await tester.pumpAndSettle();

      // Verify chip transitions to 'Otwórz w Google Drive' (D-08)
      expect(find.text('Otwórz w Google Drive'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('open_drive_matura2027_wrzesien2026_R_U.pdf'),
        ),
        findsOneWidget,
      );

      // Verify SnackBar confirmation and 'Zmień folder / Przenieś' action (D-01, D-02)
      expect(
        find.textContaining('Zapisano „matura2027_wrzesien2026_R_U.pdf” w: Mój dysk'),
        findsOneWidget,
      );
      expect(find.text('Zmień folder / Przenieś'), findsOneWidget);

      // Tap 'Zmień folder / Przenieś' in SnackBar to open DriveFolderPickerModal
      await tester.tap(find.text('Zmień folder / Przenieś'));
      await tester.pumpAndSettle();

      expect(
        find.text('Zmień folder / Przenieś na Dysku Google'),
        findsOneWidget,
      );
      expect(find.text('Mój dysk (katalog główny)'), findsOneWidget);
      expect(find.text('Szkoła - Oskar'), findsOneWidget);
      expect(find.text('Matura 2027'), findsOneWidget);

      // Select 'Matura 2027' folder and confirm move
      await tester.tap(find.text('Matura 2027'));
      await tester.pump();
      await tester.tap(find.text('Przenieś tutaj'));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Przeniesiono do folderu: Matura 2027'),
        findsOneWidget,
      );
      final updatedDefault = await mockRepo.getDefaultDriveFolder();
      expect(updatedDefault.name, 'Matura 2027');
    },
  );

  testWidgets(
    'Clicking Zapisz wszystkie na Dysku saves all attachments and transitions all chips to Otwórz w Google Drive',
    (tester) async {
      final mockRepo = MockSchoolRepository();
      final thread = MessageThread(
        id: 'msg_002',
        senderName: 'Sobota Łukasz',
        senderInitials: 'SŁ',
        senderRole: 'Nauczyciel',
        subject: 'Materiały maturalne',
        preview: 'Załączniki',
        body: 'Dzień dobry,\n\nzałączam dwa pliki.\n\nPozdrawiam,\nŁukasz Sobota',
        timestamp: DateTime(2026, 9, 28, 9, 54),
        isUnread: false,
        attachments: const [
          'matura2027_wrzesien2026_R_U.pdf',
          'matura2027_wrzesien2026_R_U.pptx',
        ],
        attachmentUrls: const {
          'matura2027_wrzesien2026_R_U.pdf': '/wiadomosci/pobierz_zalacznik/msg_002/1',
          'matura2027_wrzesien2026_R_U.pptx': '/wiadomosci/pobierz_zalacznik/msg_002/2',
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            schoolRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            home: MessageThreadScreen(thread: thread),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final saveAllBtn = find.byKey(const ValueKey('save_all_drive_button'));
      expect(saveAllBtn, findsOneWidget);

      await tester.ensureVisible(saveAllBtn);
      await tester.pumpAndSettle();
      await tester.tap(saveAllBtn);
      await tester.pumpAndSettle();

      expect(find.text('Otwórz w Google Drive'), findsNWidgets(2));
      expect(find.text('Zapisano wszystkie na Dysku'), findsOneWidget);
      expect(
        find.textContaining('Zapisano 2 załączniki w: Mój dysk'),
        findsOneWidget,
      );
      expect(find.text('Zmień folder / Przenieś'), findsOneWidget);
    },
  );

  test(
    'DriveAttachmentInfo and DriveFolderOption serialize and deserialize with defaults',
    () {
      final savedAt = DateTime.utc(2026, 9, 28, 12, 30);
      final info = DriveAttachmentInfo(
        driveFileId: 'drive_123',
        webViewLink: 'https://drive.google.com/file/d/drive_123/view',
        folderId: 'folder_szkola',
        folderName: 'Szkoła',
        savedAt: savedAt,
        savedBy: 'Oskar',
      );

      final roundTrip = DriveAttachmentInfo.fromMap(info.toMap());
      expect(roundTrip.driveFileId, 'drive_123');
      expect(roundTrip.webViewLink, 'https://drive.google.com/file/d/drive_123/view');
      expect(roundTrip.folderId, 'folder_szkola');
      expect(roundTrip.folderName, 'Szkoła');
      expect(roundTrip.savedAt.toUtc(), savedAt);
      expect(roundTrip.savedBy, 'Oskar');

      final defaultInfo = DriveAttachmentInfo.fromMap({
        'driveFileId': 'drive_root',
        'webViewLink': 'https://drive.google.com/file/d/drive_root/view',
      });
      expect(defaultInfo.folderId, 'root');
      expect(defaultInfo.folderName, 'Mój dysk');
      expect(defaultInfo.savedBy, 'Rodzic');

      final folder = DriveFolderOption.fromMap({
        'id': 'f_1',
        'name': 'Matura 2027',
        'webViewLink': 'https://drive.google.com/drive/folders/f_1',
      });
      expect(folder.id, 'f_1');
      expect(folder.name, 'Matura 2027');
      expect(DriveFolderOption.rootFolder.id, 'root');
      expect(DriveFolderOption.rootFolder.name, 'Mój dysk');
    },
  );

  test(
    'MessageThread constructor and copyWith propagate driveAttachments to default MessageItem',
    () {
      final initialInfo = DriveAttachmentInfo(
        driveFileId: 'df_1',
        webViewLink: 'https://drive.google.com/file/d/df_1/view',
        savedAt: DateTime(2026, 9, 28, 10, 0),
      );
      final thread = MessageThread(
        id: '2027508',
        senderName: 'Sobota Łukasz',
        senderInitials: 'SŁ',
        senderRole: 'Nauczyciel',
        subject: 'Matura',
        preview: 'Załączniki',
        body: 'Pełna treść',
        timestamp: DateTime(2026, 9, 28, 9, 54),
        attachments: const ['matura.pdf'],
        driveAttachments: {'matura.pdf': initialInfo},
      );

      expect(thread.driveAttachments['matura.pdf']?.driveFileId, 'df_1');
      expect(thread.messages.first.driveAttachments['matura.pdf']?.driveFileId, 'df_1');

      final movedInfo = initialInfo.copyWith(
        folderId: 'folder_szkola',
        folderName: 'Szkoła',
      );
      final updatedThread = thread.copyWith(
        driveAttachments: {'matura.pdf': movedInfo},
      );
      expect(updatedThread.driveAttachments['matura.pdf']?.folderName, 'Szkoła');
      expect(updatedThread.messages.first.driveAttachments['matura.pdf']?.folderName, 'Szkoła');
    },
  );

  test(
    'MockSchoolRepository supports saving attachments to Drive, folder creation, moving, and default folder config',
    () async {
      final repo = MockSchoolRepository();
      final defaultFolder = await repo.getDefaultDriveFolder();
      expect(defaultFolder.id, 'root');
      expect(defaultFolder.name, 'Mój dysk');

      final messages = await repo.getMessages();
      final targetMsgId = messages.first.id;

      final saved = await repo.saveAttachmentToDrive(
        msgId: targetMsgId,
        attachmentName: 'matura2027.pdf',
        downloadPath: '/wiadomosci/pobierz_zalacznik/$targetMsgId/1',
        accessToken: 'mock_token',
        savedBy: 'Rodzic',
      );
      expect(saved.folderId, 'root');
      expect(saved.folderName, 'Mój dysk');
      expect(saved.webViewLink, contains('https://drive.google.com/file/d/'));

      final newFolder = await repo.createDriveFolder(
        accessToken: 'mock_token',
        folderName: 'Dokumenty szkolne',
        setAsDefault: true,
      );
      expect(newFolder.name, 'Dokumenty szkolne');
      expect((await repo.getDefaultDriveFolder()).id, newFolder.id);

      await repo.moveDriveAttachment(
        accessToken: 'mock_token',
        msgId: targetMsgId,
        attachmentNames: ['matura2027.pdf'],
        currentDriveAttachments: {'matura2027.pdf': saved},
        targetFolderId: newFolder.id,
        targetFolderName: newFolder.name,
        setAsDefault: true,
      );

      final updatedMessages = await repo.getMessages();
      final updatedMsg = updatedMessages.firstWhere((m) => m.id == targetMsgId);
      expect(updatedMsg.driveAttachments['matura2027.pdf']?.folderId, newFolder.id);
      expect(updatedMsg.driveAttachments['matura2027.pdf']?.folderName, 'Dokumenty szkolne');
    },
  );
}

