import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRepositoryImpl({required this.firebaseAuth, required this.firestore});

  @override
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw "حدث خطأ غير متوقع، حاول مرة أخرى";
    }
  }

  @override
  Future<UserCredential> signUp({
    required String email,
    required String password,
    required String storeName,
    required String city,
    required String address,
  }) async {
    try {
      // 1. إنشاء الحساب في Firebase Auth
      final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final String uid = credential.user!.uid;
      final DateTime now = DateTime.now();
      final DateTime trialExpiry = now.add(const Duration(days: 7));
      await firestore.collection('merchants').doc(uid).set({
        'uid': uid,
        'email': email,
        'storeName': storeName,
        'city': city,
        'address': address,
        'createdAt': FieldValue.serverTimestamp(),
        'trialEndsAt': Timestamp.fromDate(trialExpiry),
        'isSubscribed': false,
      });

      await credential.user?.updateDisplayName(storeName);

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw "فشل تسجيل الحساب، حاول مرة أخرى.";
    }
  }

  @override
  Future<void> signOut() async => await firebaseAuth.signOut();

  @override
  Future<User?> getCurrentUser() async => firebaseAuth.currentUser;

  @override
  Future<void> resetPassword(String email) async {
    try {
      await firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw "حدث خطأ أثناء إرسال رابط استعادة كلمة المرور";
    }
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        throw "تم إلغاء تسجيل الدخول";
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );
      final user = userCredential.user;

      if (user != null) {
        // Check if merchant profile exists
        final doc = await firestore.collection('merchants').doc(user.uid).get();

        if (!doc.exists) {
          final DateTime now = DateTime.now();
          final DateTime trialExpiry = now.add(const Duration(days: 7));

          await firestore.collection('merchants').doc(user.uid).set({
            'uid': user.uid,
            'email': user.email,
            'storeName': user.displayName ?? "متجري",
            'city': "غير محدد",
            'address': "غير محدد",
            'createdAt': FieldValue.serverTimestamp(),
            'trialEndsAt': Timestamp.fromDate(trialExpiry),
            'isSubscribed': false,
          });
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw "فشل تسجيل الدخول بجوجل، حاول مرة أخرى.";
    }
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return "الحساب ده مش موجود، تأكد من الإيميل.";
      case 'wrong-password':
        return "كلمة المرور غلط.";
      case 'email-already-in-use':
        return "الإيميل ده متسجل قبل كدة.";
      case 'network-request-failed':
        return "مفيش اتصال بالإنترنت، جرب تاني.";
      case 'invalid-email':
        return "صيغة الإيميل غلط.";
      case 'weak-password':
        return "كلمة المرور ضعيفة جداً.";
      default:
        return "عذراً، حصلت مشكلة في عملية الدخول.";
    }
  }
}
