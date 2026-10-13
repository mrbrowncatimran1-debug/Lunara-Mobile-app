import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'screens/my_habits_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/today_screen.dart';
import 'theme.dart';
import 'widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: LColors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));
  final state = AppState();
  state.load();
  runApp(LunaraApp(state: state));
}

/// Gives every screen access to [AppState] and rebuilds them when it changes.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);
  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
  static AppState read(BuildContext context) => context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

class ToastData {
  ToastData(this.title, this.body, this.onUndo);
  final String title;
  final String body;
  final VoidCallback? onUndo;
}

/// Shows the plum toast above the bottom navigation.
class Toaster {
  static final current = ValueNotifier<ToastData?>(null);
  static Timer? _timer;

  static void show(String title, String body, {VoidCallback? onUndo}) {
    _timer?.cancel();
    current.value = ToastData(title, body, onUndo);
    _timer = Timer(const Duration(seconds: 5), hide);
  }

  static void hide() {
    _timer?.cancel();
    current.value = null;
  }
}

class LunaraApp extends StatelessWidget {
  const LunaraApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: state,
      child: MaterialApp(
        title: 'Lunara',
        debugShowCheckedModeBanner: false,
        theme: buildLunaraTheme(),
        home: const HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    if (!state.loaded) {
      return const Scaffold(body: Center(child: LogoMark(size: 72)));
    }
    return Scaffold(
      backgroundColor: LColors.ivory,
      bottomNavigationBar: LBottomNav(
        index: _tab,
        onTap: (i) {
          Toaster.hide();
          setState(() => _tab = i);
        },
      ),
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: IndexedStack(
              index: _tab,
              children: [
                const TodayScreen(),
                ProgressScreen(onOpenHabits: () => setState(() => _tab = 2)),
                const MyHabitsScreen(),
              ],
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 15,
            child: ValueListenableBuilder<ToastData?>(
              valueListenable: Toaster.current,
              builder: (context, t, _) => AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0, 0.25), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: t == null
                    ? const SizedBox.shrink()
                    : LToast(
                        key: ValueKey(t),
                        title: t.title,
                        body: t.body,
                        onUndo: t.onUndo == null
                            ? null
                            : () {
                                t.onUndo!();
                                Toaster.hide();
                              },
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
