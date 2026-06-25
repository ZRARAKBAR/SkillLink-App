import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  Future<void> init() async {
    await _fcm.requestPermission();

    String? token = await _fcm.getToken();
    print("FCM TOKEN: $token");
  }

  void listenMessages() {
    FirebaseMessaging.onMessage.listen((message) {
      print("Notification: ${message.notification?.title}");
    });
  }
}