import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../firebase_options.dart';

class FirebaseAuthService {
  static const String googleDriveFileScope = 'https://www.googleapis.com/auth/drive.file';
  static String? _cachedDriveAccessToken;
  static DateTime? _driveTokenExpiry;

  bool get hasValidDriveAccessToken {
    if (_cachedDriveAccessToken == null || _cachedDriveAccessToken!.isEmpty) {
      return false;
    }
    if (_driveTokenExpiry == null) return false;
    return DateTime.now().isBefore(_driveTokenExpiry!);
  }

  void clearDriveAccessToken() {
    _cachedDriveAccessToken = null;
    _driveTokenExpiry = null;
  }

  void clearDriveAccessTokenCache() => clearDriveAccessToken();

  FirebaseAuth? get _auth {
    try {
      if (Firebase.apps.isNotEmpty) {
        return FirebaseAuth.instance;
      }
      return null;
    } catch (e) {
      debugPrint('FirebaseAuth.instance unavailable: $e');
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    final auth = _auth;
    if (auth == null) {
      return Stream.value(null);
    }
    try {
      return auth.authStateChanges();
    } catch (e) {
      debugPrint('Error accessing authStateChanges: $e');
      return Stream.value(null);
    }
  }

  User? get currentUser => _auth?.currentUser;

  bool get isSignedIn => _auth?.currentUser != null;

  Future<UserCredential?> signInWithGoogle() async {
    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        debugPrint('Late Firebase initialization failed: $e');
      }
    }

    final auth = _auth;
    if (auth == null) {
      throw Exception(
        'Usługa logowania Google wymaga aktywacji w Firebase Console dla projektu "lepsza-szkola" (sekcja Authentication -> Rozpocznij -> Google). '
        'Możesz od razu skorzystać z aplikacji klikając przycisk "Wejdź w trybie demo (bez logowania)" poniżej.',
      );
    }

    try {
      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        return await auth.signInWithPopup(provider);
      } else {
        final provider = GoogleAuthProvider();
        return await auth.signInWithProvider(provider);
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  Future<String?> requestGoogleDriveAccessToken({bool forceRefresh = false}) async {
    if (!forceRefresh && hasValidDriveAccessToken) {
      return _cachedDriveAccessToken;
    }

    if (Firebase.apps.isEmpty) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        debugPrint('Late Firebase initialization failed: $e');
      }
    }

    final auth = _auth;
    if (auth == null) {
      throw Exception('Usługa Firebase Auth nie jest zainicjalizowana.');
    }

    final provider = GoogleAuthProvider();
    provider.addScope('email');
    provider.addScope('profile');
    provider.addScope(googleDriveFileScope);
    if (forceRefresh) {
      provider.setCustomParameters({'prompt': 'consent'});
    }

    UserCredential userCredential;
    final current = auth.currentUser;
    if (kIsWeb) {
      if (current != null && !current.isAnonymous) {
        try {
          userCredential = await current.reauthenticateWithPopup(provider);
        } catch (_) {
          userCredential = await auth.signInWithPopup(provider);
        }
      } else {
        userCredential = await auth.signInWithPopup(provider);
      }
    } else {
      userCredential = await auth.signInWithProvider(provider);
    }

    final oauthCred = userCredential.credential as OAuthCredential?;
    final token = oauthCred?.accessToken;
    if (token != null && token.isNotEmpty) {
      _cachedDriveAccessToken = token;
      _driveTokenExpiry = DateTime.now().add(const Duration(minutes: 50));
    }
    return token;
  }

  Future<UserCredential?> signInDemo() async {
    final auth = _auth;
    if (auth == null) return null;
    try {
      return await auth.signInAnonymously();
    } catch (e) {
      debugPrint('Demo anonymous auth warning: $e');
      return null;
    }
  }

  Future<void> signOut() async {
    clearDriveAccessToken();
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Sign-Out error: $e');
    }
  }
}


