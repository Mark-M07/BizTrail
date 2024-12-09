import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions =
      FirebaseFunctions.instanceFor(region: 'australia-southeast1');

  // Auth methods
  Future<UserCredential> signUpWithEmailPassword(
      String email, String password) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Firestore methods
  Future<DocumentSnapshot> getEvent(String eventName) async {
    return await _firestore.collection('events').doc(eventName).get();
  }

  Stream<DocumentSnapshot> getUserEventStream(String userId, String eventName) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('events')
        .doc(eventName)
        .snapshots();
  }

  // Cloud Functions methods
  Future<HttpsCallableResult> updateUserProfile({
    required String name,
    required String phone,
  }) async {
    final callable = _functions.httpsCallable('updateUserProfile');
    return await callable.call({
      'name': name,
      'phone': phone,
    });
  }

  Future<HttpsCallableResult> addPoints(Map<String, dynamic> data) async {
    final callable = _functions.httpsCallable('addPoints');
    return await callable.call(data);
  }

  // Analytics methods
  Future<void> logCustomEvent(
      String eventName, Map<String, Object>? parameters) async {
    await _analytics.logEvent(
      name: eventName,
      parameters: parameters,
    );
  }
}
