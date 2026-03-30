import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';

import 'models/app_settings.dart';
import 'models/client.dart';
import 'models/payment_record.dart';
import 'models/project.dart';
import 'models/work_session.dart';
import 'providers/data_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/timer_provider.dart';
import 'screens/onboarding_screen.dart';
import 'screens/client_detail_screen.dart';
import 'screens/client_list_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/finance_screen.dart';
import 'screens/project_detail_screen.dart';
import 'screens/settings_screen.dart';
import 'services/notification_service.dart';
import 'services/notification_scheduler.dart';
import 'seed_data.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(WorkSessionAdapter());
  Hive.registerAdapter(PaymentRecordAdapter());
  Hive.registerAdapter(ProjectAdapter());
  Hive.registerAdapter(ClientAdapter());

  final settingsBox = await Hive.openBox('settings');
  final clientsBox = await Hive.openBox('clients');
  final notificationService = NotificationService();
  await notificationService.init();

  seedIfNeeded(settingsBox, clientsBox);

  final settings = settingsBox.get('app') as AppSettings?;
  final showOnboarding = settings == null || !settings.onboardingDone;

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.light,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider(settingsBox)),
        ChangeNotifierProvider(
          create: (context) {
            final sp = context.read<SettingsProvider>();
            final dp = DataProvider(clientsBox, sp);
            
            // Wire the notification reschedule callback
            sp.onNotifPrefChanged = () async {
              try {
                final scheduler = NotificationScheduler();
                await scheduler.rescheduleAll(
                  clients: dp.clients,
                  settings: sp.settings,
                );
              } catch (_) {
                // Silent fail
              }
            };
            
            return dp;
          },
        ),
        ChangeNotifierProvider(create: (_) => TimerProvider()),
      ],
      child: FreelanceHubApp(showOnboarding: showOnboarding),
    ),
  );
}

class FreelanceHubApp extends StatelessWidget {
  const FreelanceHubApp({super.key, required this.showOnboarding});

  final bool showOnboarding;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreelanceHub',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: showOnboarding ? const OnboardingScreen() : const MainShell(),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  final GlobalKey<NavigatorState> _clientsNavigatorKey =
      GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        final handled = _handleBack();
        if (!handled) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            DashboardScreen(
              onOpenClient: _openClientFromOutside,
              onOpenProject: _openProjectFromOutside,
            ),
            Navigator(
              key: _clientsNavigatorKey,
              onGenerateRoute: (settings) {
                if (settings.name == '/client') {
                  final clientId = settings.arguments as String;
                  return CupertinoPageRoute(
                    settings: settings,
                    builder: (_) => ClientDetailScreen(clientId: clientId),
                  );
                }
                if (settings.name == '/project') {
                  final args = settings.arguments as Map<String, String>;
                  return CupertinoPageRoute(
                    settings: settings,
                    builder: (_) => ProjectDetailScreen(
                      clientId: args['clientId']!,
                      projectId: args['projectId']!,
                    ),
                  );
                }
                return CupertinoPageRoute(
                    settings: settings,
                    builder: (_) => const ClientListScreen());
              },
            ),
            const FinanceScreen(),
            const SettingsScreen(),
          ],
        ),
        bottomNavigationBar: _BottomNav(
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
        ),
      ),
    );
  }

  bool _handleBack() {
    if (_selectedIndex == 1) {
      final nav = _clientsNavigatorKey.currentState;
      if (nav != null && nav.canPop()) {
        nav.pop();
        return true;
      }
    }
    return false;
  }

  void _openClientFromOutside(String clientId) {
    setState(() => _selectedIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clientsNavigatorKey.currentState
          ?.pushNamed('/client', arguments: clientId);
    });
  }

  void _openProjectFromOutside(String clientId, String projectId) {
    setState(() => _selectedIndex = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _clientsNavigatorKey.currentState?.pushNamed(
        '/project',
        arguments: {'clientId': clientId, 'projectId': projectId},
      );
    });
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    Widget navIcon(IconData icon, bool active) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? kBlack : kTextMuted),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? kLime : Colors.transparent,
              shape: BoxShape.circle,
            ),
          ),
        ],
      );
    }

    return Container(
      decoration: const BoxDecoration(
        color: kWhite,
        border: Border(top: BorderSide(color: kBorder, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        items: [
          BottomNavigationBarItem(
            icon: navIcon(Icons.dashboard_outlined, currentIndex == 0),
            label: 'DASHBOARD',
          ),
          BottomNavigationBarItem(
            icon: navIcon(Icons.people_outline, currentIndex == 1),
            label: 'CLIENTS',
          ),
          BottomNavigationBarItem(
            icon: navIcon(Icons.bar_chart_outlined, currentIndex == 2),
            label: 'FINANCE',
          ),
          BottomNavigationBarItem(
            icon: navIcon(Icons.settings_outlined, currentIndex == 3),
            label: 'SETTINGS',
          ),
        ],
      ),
    );
  }
}
