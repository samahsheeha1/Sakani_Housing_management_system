import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Import for kIsWeb
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/welcome_page.dart';
import 'services/notification_service.dart';
import 'firebase_options.dart'; // Import the generated Firebase options

// Background message handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Handling a background message: ${message.messageId}");
  print("Message Data: ${message.data}");

  // Show a local notification for the background message
  NotificationService().showNotification(
    title: message.notification?.title ?? "New Message",
    body: message.notification?.body ?? "You have a new message",
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the FirebaseOptions
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb) {
    // Configure background message handling
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Request notification permissions
    final FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get the FCM token (optional, for debugging or server-side use)
    String? token = await messaging.getToken();
    print("FCM Token: $token");
  }

  runApp(const SakniApp());
}

class SakniApp extends StatefulWidget {
  const SakniApp({super.key});

  @override
  _SakniAppState createState() => _SakniAppState();
}

class _SakniAppState extends State<SakniApp> {
  late NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();
    _notificationService.initialize(context);

    if (!kIsWeb) {
      // Listen for foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Handling a foreground message: ${message.messageId}");
        print("Message Data: ${message.data}");

        // Show a local notification for the foreground message
        _notificationService.showNotification(
          title: message.notification?.title ?? "New Message",
          body: message.notification?.body ?? "You have a new message",
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sakni',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Colors.orange.shade50,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomePage(),
      },
    );
  }
}
