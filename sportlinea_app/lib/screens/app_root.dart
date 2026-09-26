import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sportlinea_app/api/api_client.dart';
import 'package:sportlinea_app/api/models.dart';
import 'package:sportlinea_app/screens/pages.dart';
import 'package:sportlinea_app/theme.dart';
import 'package:sportlinea_app/widgets/ui.dart';

class AppRoot extends StatefulWidget {
  const AppRoot({super.key, this.player});
  final Player? player;

  @override
  State<AppRoot> createState() => AppRootState();
}

class AppRootState extends State<AppRoot> {
  late Player? player = widget.player;
  int tab = 0;
  Widget? overlay;
  String? overlayBack;
  HomeData? home;
  LineData? line;
  bool lineBusy = true;
  String? lineError;
  String? lineSport;
  String? lineCategory;
  int _lineSync = 0;

  @override
  void initState() {
    super.initState();
    unawaited(syncLine());
  }

  Future<String?> syncLine({bool reshuffle = false}) async {
    final sync = ++_lineSync;
    setState(() {
      lineBusy = true;
      lineError = null;
    });
    try {
      String? message;
      if (reshuffle) {
        message = await ApiClient.instance.refreshLine();
        lineSport = null;
        lineCategory = null;
      }
      final all = await ApiClient.instance.line();
      final live = all.events.where((e) => e.status == 'AcceptingBets').toList();
      if (!mounted || sync != _lineSync) return message;
      final events = live.where((e) {
        if (lineSport != null && e.sportType != lineSport) return false;
        if (lineCategory != null && e.sportCategory != lineCategory) return false;
        return true;
      }).toList();
      final newest = [...live]..sort((a, b) => b.startDate.compareTo(a.startDate));
      setState(() {
        line = LineData(
          events: events,
          sports: live.map((e) => e.sportType).toSet().toList()..sort(),
          categories: live.map((e) => e.sportCategory).toSet().toList()..sort(),
          totalActive: all.totalActive,
          selectedSport: lineSport,
          selectedCategory: lineCategory,
        );
        home = HomeData(
          lineEmpty: live.isEmpty,
          totalActive: all.totalActive,
          top: live.take(3).toList(),
          newest: newest.take(3).toList(),
        );
        lineBusy = false;
      });
      return message;
    } on ApiException catch (e) {
      if (mounted && sync == _lineSync) {
        setState(() {
          lineError = e.message;
          lineBusy = false;
        });
      }
      rethrow;
    }
  }

  Future<void> setLineSport(String? value) async {
    lineSport = value;
    await syncLine();
  }

  Future<void> setLineCategory(String? value) async {
    lineCategory = value;
    await syncLine();
  }

  Future<void> refreshMe() async {
    if (!ApiClient.instance.isLoggedIn) return;
    try {
      final me = await ApiClient.instance.me();
      if (mounted) setState(() => player = me);
    } catch (_) {}
  }

  void openOverlay(Widget page, {String? back}) => setState(() {
        overlay = page;
        overlayBack = back;
      });

  void closeOverlay() => setState(() {
        overlay = null;
        overlayBack = null;
      });

  void setPlayer(Player? value) {
    setState(() {
      player = value;
      overlay = null;
      overlayBack = null;
      tab = 0;
      home = null;
      line = null;
      lineSport = null;
      lineCategory = null;
    });
    unawaited(syncLine());
  }

  Future<void> logout() async {
    await ApiClient.instance.logout();
    setPlayer(null);
  }

  void goHome() {
    setState(() {
      tab = 0;
      overlay = null;
      overlayBack = null;
    });
  }

  void goTab(int i) {
    setState(() {
      tab = i;
      overlay = null;
      overlayBack = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final logged = player != null;
    return Scaffold(
      backgroundColor: Sl.bg,
      body: Column(
        children: [
          _TopBar(root: this),
          if (overlayBack != null)
            Container(
              width: double.infinity,
              color: const Color(0xFF0A221C),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: GestureDetector(
                onTap: closeOverlay,
                child: Text(overlayBack!, style: const TextStyle(color: Sl.accent, fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          Expanded(
            child: overlay ??
                IndexedStack(
                  index: tab,
                  children: [
                    HomePage(root: this),
                    LinePage(root: this),
                    ResultsPage(root: this),
                    RatingPage(root: this),
                    logged ? CabinetPage(root: this) : LoginPage(root: this),
                  ],
                ),
          ),
        ],
      ),
      bottomNavigationBar: _TabBar(
        index: tab,
        logged: logged,
        onSelect: goTab,
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.root});
  final AppRootState root;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Sl.primary, Sl.primaryLight]),
        border: Border(bottom: BorderSide(color: Sl.accent, width: 2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: root.goHome,
              child: const Text.rich(
                TextSpan(children: [
                  TextSpan(text: '⚽ Спорт', style: TextStyle(color: Sl.text, fontWeight: FontWeight.w800, fontSize: 15.5)),
                  TextSpan(text: 'Линия', style: TextStyle(color: Sl.accent, fontWeight: FontWeight.w800, fontSize: 15.5)),
                ]),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          if (root.player != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 132),
                  child: Text(
                    root.player!.fullName,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: Color(0xEBFFFFFF), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                HeaderLink(label: 'Выход', onTap: root.logout),
              ],
            )
          else
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HeaderLink(label: 'Вход', onTap: () => root.goTab(4)),
                HeaderLink(label: 'Регистрация', accent: true, onTap: () => root.openOverlay(RegisterPage(root: root))),
              ],
            ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar({required this.index, required this.logged, required this.onSelect});
  final int index;
  final bool logged;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('🏠', 'Главная'),
      ('📋', 'Линия'),
      ('✅', 'Итоги'),
      ('🏆', 'Рейтинг'),
      logged ? ('👤', 'Кабинет') : ('🔑', 'Войти'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: Sl.tabbar,
        border: Border(top: BorderSide(color: Sl.border)),
      ),
      padding: const EdgeInsets.only(top: 4, bottom: 6),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: InkWell(
                onTap: () => onSelect(i),
                child: Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 22,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 4),
                        decoration: BoxDecoration(
                          color: index == i ? Sl.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Text(
                        items[i].$1,
                        style: TextStyle(fontSize: 16, color: index == i ? Sl.accent : Sl.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        items[i].$2,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: index == i ? Sl.accent : Sl.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
