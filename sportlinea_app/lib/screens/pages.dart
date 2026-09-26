import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sportlinea_app/api/api_client.dart';
import 'package:sportlinea_app/api/models.dart';
import 'package:sportlinea_app/screens/app_root.dart';
import 'package:sportlinea_app/theme.dart';
import 'package:sportlinea_app/widgets/ui.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.root});
  final AppRootState root;

  @override
  Widget build(BuildContext context) {
    if (root.lineBusy && root.home == null) {
      return const Center(child: CircularProgressIndicator(color: Sl.accent));
    }
    if (root.lineError != null && root.home == null) {
      return Center(child: Text(root.lineError!, style: const TextStyle(color: Sl.danger)));
    }
    final d = root.home;
    if (d == null) return const Center(child: CircularProgressIndicator(color: Sl.accent));
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        Panel(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('БК «СпортЛиния»', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Sl.text)),
              const SizedBox(height: 6),
              const Text('Информационная система букмекерской конторы. Ставки на спорт в режиме реального времени.',
                  style: TextStyle(color: Sl.muted, fontSize: 14, height: 1.35)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 8, children: [
                GoldButton(label: 'Смотреть линию', onPressed: () => root.goTab(1)),
                if (root.player == null)
                  GoldButton(label: 'Зарегистрироваться', outlined: true, onPressed: () => root.openOverlay(RegisterPage(root: root))),
              ]),
            ],
          ),
        ),
        if (d.lineEmpty)
          Panel(
            child: Column(
              children: [
                const Text('Спортивная линия обновляется', style: TextStyle(color: Sl.accent, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 8),
                const Text('Сейчас нет доступных событий для ставок. Обновите линию, чтобы загрузить новые матчи.',
                    textAlign: TextAlign.center, style: TextStyle(color: Sl.muted)),
                const SizedBox(height: 12),
                GoldButton(
                  label: root.lineBusy ? 'Обновление…' : '🔄 Обновить линию',
                  onPressed: root.lineBusy ? null : () => _reshuffle(context),
                ),
              ],
            ),
          )
        else ...[
          if (d.top.isNotEmpty) const Text('🔥 Топ событий', style: TextStyle(color: Sl.accent, fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...d.top.map((e) => EventCard(event: e, onTap: () => root.openOverlay(EventPage(root: root, eventId: e.id), back: '← Назад к линии'))),
          if (d.newest.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('✨ Новинки месяца', style: TextStyle(color: Sl.accent, fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...d.newest.map((e) => EventCard(event: e, onTap: () => root.openOverlay(EventPage(root: root, eventId: e.id), back: '← Назад к линии'))),
          ],
        ],
        const SizedBox(height: 8),
        StatCard(value: '24/7', label: 'Круглосуточный приём ставок'),
        StatCard(value: d.lineEmpty ? '—' : 'Live', label: d.lineEmpty ? 'Линия обновляется' : 'Актуальные коэффициенты'),
        const StatCard(value: '100%', label: 'Прозрачные расчёты'),
      ],
    );
  }

  Future<void> _reshuffle(BuildContext context) async {
    try {
      final msg = await root.syncLine(reshuffle: true);
      if (context.mounted && msg != null) Sl.toast(context, msg, kind: 'success');
    } on ApiException catch (e) {
      if (context.mounted) Sl.toast(context, e.message, kind: 'error');
    }
  }
}

class LinePage extends StatelessWidget {
  const LinePage({super.key, required this.root});
  final AppRootState root;

  @override
  Widget build(BuildContext context) {
    if (root.lineBusy && root.line == null) {
      return const Center(child: CircularProgressIndicator(color: Sl.accent));
    }
    if (root.lineError != null && root.line == null) {
      return Center(child: Text(root.lineError!, style: const TextStyle(color: Sl.danger)));
    }
    final d = root.line;
    if (d == null) return const Center(child: CircularProgressIndicator(color: Sl.accent));
    final sport = root.lineSport;
    final category = root.lineCategory;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        Row(
          children: [
            const Expanded(child: PageTitle('Линия событий')),
            Text('Доступных: ${d.events.length}', style: const TextStyle(color: Sl.muted, fontSize: 13)),
          ],
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: GoldButton(
            label: root.lineBusy ? 'Обновление…' : '🔄 Обновить линию',
            onPressed: root.lineBusy ? null : () => _reshuffle(context),
          ),
        ),
        const SizedBox(height: 12),
        if (d.categories.isNotEmpty) ...[
          const Text('Категория:', style: TextStyle(color: Sl.muted, fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(children: [
            FilterChipBtn(label: 'Все', selected: category == null, onTap: () => unawaited(root.setLineCategory(null))),
            ...d.categories.map((c) => FilterChipBtn(label: c, selected: category == c, onTap: () => unawaited(root.setLineCategory(c)))),
          ]),
        ],
        if (d.sports.isNotEmpty) ...[
          const Text('Вид спорта:', style: TextStyle(color: Sl.muted, fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(children: [
            FilterChipBtn(label: 'Все', selected: sport == null, onTap: () => unawaited(root.setLineSport(null))),
            ...d.sports.map((s) => FilterChipBtn(label: s, selected: sport == s, onTap: () => unawaited(root.setLineSport(s)))),
          ]),
        ],
        const SizedBox(height: 8),
        if (d.events.isEmpty)
          const Panel(child: Text('Нажмите «Обновить линию», чтобы загрузить матчи.', textAlign: TextAlign.center, style: TextStyle(color: Sl.muted)))
        else
          ...d.events.map((e) => EventCard(event: e, onTap: () => root.openOverlay(EventPage(root: root, eventId: e.id), back: '← Назад к линии'))),
      ],
    );
  }

  Future<void> _reshuffle(BuildContext context) async {
    try {
      final msg = await root.syncLine(reshuffle: true);
      if (context.mounted && msg != null) Sl.toast(context, msg, kind: 'success');
    } on ApiException catch (e) {
      if (context.mounted) Sl.toast(context, e.message, kind: 'error');
    }
  }
}

class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key, required this.root});
  final AppRootState root;
  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  List<SportEventDto> items = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    ApiClient.instance.results().then((v) {
      if (mounted) setState(() { items = v; loading = false; });
    }).catchError((_) {
      if (mounted) setState(() => loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Sl.accent));
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        const PageTitle('Итоги матчей'),
        if (items.isEmpty)
          const Panel(child: Text('Завершённых матчей пока нет', textAlign: TextAlign.center, style: TextStyle(color: Sl.muted)))
        else
          ...items.map((e) => Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SportChip(e.sportType),
                  const SizedBox(height: 8),
                  Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(when(e.startDate), style: const TextStyle(color: Sl.muted, fontSize: 13)),
                  if (e.result != null && e.result!.isNotEmpty)
                    Text(e.result!, style: const TextStyle(color: Sl.accent, fontWeight: FontWeight.w800)),
                ]),
              )),
      ],
    );
  }
}

class RatingPage extends StatefulWidget {
  const RatingPage({super.key, required this.root});
  final AppRootState root;
  @override
  State<RatingPage> createState() => _RatingPageState();
}

class _RatingPageState extends State<RatingPage> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    ApiClient.instance.rating().then((v) {
      if (mounted) setState(() { items = v; loading = false; });
    }).catchError((_) {
      if (mounted) setState(() => loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Sl.accent));
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        const PageTitle('Общий рейтинг игроков'),
        if (items.isEmpty)
          const Panel(child: Text('Рейтинг пока пуст', textAlign: TextAlign.center, style: TextStyle(color: Sl.muted)))
        else
          ...List.generate(items.length, (i) {
            final p = items[i];
            return Panel(
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: i == 0 ? const Color(0x33F5C518) : Sl.primary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: i == 0 ? Sl.accent : Sl.border),
                    ),
                    child: Text('${i + 1}', style: TextStyle(color: i == 0 ? Sl.accent : Sl.text, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(p['playerName']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600))),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${(p['totalWinnings'] as num?)?.toStringAsFixed(0) ?? '0'} ₽', style: const TextStyle(color: Sl.accent, fontWeight: FontWeight.w800)),
                      Text('П ${p['wins']} · Пр ${p['losses']}', style: const TextStyle(color: Sl.muted, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.root});
  final AppRootState root;
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController(text: 'player@sportlinea.ru');
  final password = TextEditingController(text: 'Player123!');
  String? error;
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        const PageTitle('Вход в систему'),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 10),
              TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Пароль')),
              if (error != null) AlertBox(error!),
              const SizedBox(height: 14),
              GoldButton(
                label: busy ? 'Вход…' : 'Войти',
                onPressed: busy
                    ? null
                    : () async {
                        setState(() { busy = true; error = null; });
                        try {
                          final p = await ApiClient.instance.login(email.text, password.text);
                          widget.root.setPlayer(p);
                        } on ApiException catch (e) {
                          setState(() => error = e.message);
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => widget.root.openOverlay(RegisterPage(root: widget.root)),
                child: const Text('Нет аккаунта? Зарегистрироваться', textAlign: TextAlign.center, style: TextStyle(color: Sl.accent)),
              ),
              const SizedBox(height: 8),
              const Text('Тестовый игрок: player@sportlinea.ru / Player123!', style: TextStyle(color: Sl.muted, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key, required this.root});
  final AppRootState root;
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final email = TextEditingController();
  final last = TextEditingController();
  final first = TextEditingController();
  final patronymic = TextEditingController();
  final password = TextEditingController();
  final confirm = TextEditingController();
  String country = 'USA';
  String? error;
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        const PageTitle('Регистрация'),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 8),
              TextField(controller: last, decoration: const InputDecoration(labelText: 'Фамилия')),
              const SizedBox(height: 8),
              TextField(controller: first, decoration: const InputDecoration(labelText: 'Имя')),
              const SizedBox(height: 8),
              TextField(controller: patronymic, decoration: const InputDecoration(labelText: 'Отчество')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: country,
                dropdownColor: Sl.card,
                items: const [
                  DropdownMenuItem(value: 'USA', child: Text('США')),
                  DropdownMenuItem(value: 'Russia', child: Text('Россия')),
                ],
                onChanged: (v) => setState(() => country = v ?? 'USA'),
                decoration: const InputDecoration(labelText: 'Страна проживания'),
              ),
              const SizedBox(height: 8),
              TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Пароль')),
              const SizedBox(height: 8),
              TextField(controller: confirm, obscureText: true, decoration: const InputDecoration(labelText: 'Подтверждение пароля')),
              if (error != null) AlertBox(error!),
              const SizedBox(height: 14),
              GoldButton(
                label: busy ? 'Отправка…' : 'Зарегистрироваться',
                onPressed: busy
                    ? null
                    : () async {
                        setState(() { busy = true; error = null; });
                        try {
                          final p = await ApiClient.instance.register({
                            'email': email.text,
                            'password': password.text,
                            'confirmPassword': confirm.text,
                            'firstName': first.text,
                            'lastName': last.text,
                            'patronymic': patronymic.text,
                            'countryOfResidence': country,
                          });
                          widget.root.setPlayer(p);
                        } on ApiException catch (e) {
                          setState(() => error = e.message);
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class EventPage extends StatefulWidget {
  const EventPage({super.key, required this.root, required this.eventId});
  final AppRootState root;
  final int eventId;
  @override
  State<EventPage> createState() => _EventPageState();
}

class _EventPageState extends State<EventPage> {
  SportEventDto? event;
  double? freeBet;
  final amounts = <int, TextEditingController>{};
  final useFree = <int, bool>{};
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await ApiClient.instance.event(widget.eventId);
      setState(() {
        event = r.event;
        freeBet = r.freeBet;
        loading = false;
      });
    } on ApiException catch (e) {
      setState(() { error = e.message; loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Sl.accent));
    final e = event;
    if (e == null) return Center(child: Text(error ?? 'Нет данных', style: const TextStyle(color: Sl.danger)));
    final canBet = widget.root.player != null && e.status == 'AcceptingBets';
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 6, children: [SportChip(e.sportType), Text(e.sportCategory, style: const TextStyle(color: Sl.pending))]),
            const SizedBox(height: 8),
            PageTitle(e.title),
            Text('Начало: ${when(e.startDate)}', style: const TextStyle(color: Sl.muted)),
            Text(e.status == 'AcceptingBets' ? 'Статус: Принимает ставки' : 'Статус: ${e.status}', style: const TextStyle(color: Sl.muted)),
          ]),
        ),
        const Text('Доступные исходы', style: TextStyle(color: Sl.accent, fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (freeBet != null)
          Panel(
            gold: true,
            child: Text('🎁 Активный фрибет: ${freeBet!.toStringAsFixed(0)} ₽', style: const TextStyle(color: Sl.accent, fontWeight: FontWeight.w700)),
          ),
        if (error != null) AlertBox(error!),
        ...e.coefficients.map((c) {
          amounts.putIfAbsent(c.id, () => TextEditingController());
          useFree.putIfAbsent(c.id, () => false);
          return Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w700))),
                    Text(c.value.toStringAsFixed(2), style: const TextStyle(color: Sl.accent, fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
                if (canBet) ...[
                  const SizedBox(height: 10),
                  if (freeBet != null)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: useFree[c.id],
                      activeColor: Sl.accent,
                      title: Text('Фрибет ${freeBet!.toStringAsFixed(0)} ₽', style: const TextStyle(color: Sl.accent, fontSize: 13)),
                      onChanged: (v) => setState(() {
                        useFree[c.id] = v ?? false;
                        if (v == true) amounts[c.id]!.text = freeBet!.toStringAsFixed(0);
                      }),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: amounts[c.id],
                          keyboardType: TextInputType.number,
                          readOnly: useFree[c.id] == true,
                          decoration: const InputDecoration(labelText: 'от 100 ₽'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GoldButton(
                        label: 'Поставить',
                        onPressed: () async {
                          final amount = double.tryParse(amounts[c.id]!.text.replaceAll(',', '.'));
                          if (amount == null && useFree[c.id] != true) {
                            setState(() => error = 'Укажите сумму ставки');
                            return;
                          }
                          try {
                            final result = await ApiClient.instance.placeBet(
                              coefficientId: c.id,
                              amount: amount ?? freeBet ?? 100,
                              useFreeBet: useFree[c.id] == true,
                            );
                            if (!mounted) return;
                            final toastText = result.bonusMessage == null
                                ? result.message
                                : '${result.message}\n${result.bonusMessage}';
                            Sl.toast(
                              context,
                              toastText,
                              kind: result.isWin ? (result.bonusMessage != null ? 'bonus' : 'success') : 'error',
                            );
                            await widget.root.refreshMe();
                            await widget.root.syncLine();
                            widget.root.closeOverlay();
                          } on ApiException catch (ex) {
                            setState(() => error = ex.message);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
        if (!canBet && widget.root.player == null)
          const Text('Войдите или зарегистрируйтесь, чтобы сделать ставку.', style: TextStyle(color: Sl.muted)),
      ],
    );
  }
}

class CabinetPage extends StatefulWidget {
  const CabinetPage({super.key, required this.root});
  final AppRootState root;
  @override
  State<CabinetPage> createState() => _CabinetPageState();
}

class _CabinetPageState extends State<CabinetPage> {
  Map<String, dynamic>? data;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      data = await ApiClient.instance.profile();
      await widget.root.refreshMe();
    } on ApiException catch (e) {
      error = e.message;
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Sl.accent));
    if (data == null) return Center(child: Text(error ?? 'Нет данных', style: const TextStyle(color: Sl.danger)));
    final user = data!['user'] as Map<String, dynamic>;
    final stats = data!['stats'] as Map<String, dynamic>;
    final notes = (data!['notifications'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final balance = (user['balance'] as num?)?.toDouble() ?? 0;
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        const PageTitle('Личный кабинет'),
        Panel(
          gold: true,
          child: Column(
            children: [
              const Text('Баланс счёта', style: TextStyle(color: Sl.muted, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('${balance.toStringAsFixed(2)} ₽', style: const TextStyle(color: Sl.accent, fontSize: 28, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: GoldButton(label: '+ Пополнить', onPressed: () => widget.root.openOverlay(AmountPage(root: widget.root, deposit: true), back: '← Назад в кабинет'))),
                const SizedBox(width: 8),
                Expanded(child: GoldButton(label: '↓ Вывести', outlined: true, onPressed: () => widget.root.openOverlay(AmountPage(root: widget.root, deposit: false), back: '← Назад в кабинет'))),
              ]),
            ],
          ),
        ),
        Row(children: [
          Expanded(child: StatCard(value: '${stats['totalBets']}', label: 'Всего ставок', compact: true)),
          const SizedBox(width: 8),
          Expanded(child: StatCard(value: '${stats['pending']}', label: 'В ожидании', color: Sl.pending, compact: true)),
        ]),
        Row(children: [
          Expanded(child: StatCard(value: '${stats['wins']}', label: 'Побед', color: Sl.success, compact: true)),
          const SizedBox(width: 8),
          Expanded(child: StatCard(value: '${stats['losses']}', label: 'Поражений', color: Sl.danger, compact: true)),
        ]),
        StatCard(value: '${(stats['totalWinnings'] as num?)?.toStringAsFixed(0) ?? '0'} ₽', label: 'Сумма выигрышей', compact: true),
        Wrap(spacing: 6, runSpacing: 6, children: [
          GoldButton(label: 'История ставок', outlined: true, onPressed: () => widget.root.openOverlay(BetsPage(root: widget.root), back: '← Назад в кабинет')),
          GoldButton(label: 'Бонусы', outlined: true, onPressed: () => widget.root.openOverlay(BonusesPage(root: widget.root), back: '← Назад в кабинет')),
          GoldButton(label: 'Уведомления', outlined: true, onPressed: () => widget.root.openOverlay(NotesPage(root: widget.root), back: '← Назад в кабинет')),
          GoldButton(label: 'Профиль', outlined: true, onPressed: () => widget.root.openOverlay(EditProfilePage(root: widget.root, user: user), back: '← Назад в кабинет')),
        ]),
        const SizedBox(height: 12),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Данные профиля', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            Text('ФИО: ${user['fullName']}'),
            Text('Email: ${user['email']}'),
            Text('Страна проживания: ${user['countryName'] ?? user['countryOfResidence']}'),
          ]),
        ),
        if (notes.isNotEmpty) ...[
          const Text('Последние уведомления', style: TextStyle(color: Sl.accent, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...notes.map(notificationFromMap),
        ],
      ],
    );
  }
}

class AmountPage extends StatefulWidget {
  const AmountPage({super.key, required this.root, required this.deposit});
  final AppRootState root;
  final bool deposit;
  @override
  State<AmountPage> createState() => _AmountPageState();
}

class _AmountPageState extends State<AmountPage> {
  final amount = TextEditingController();
  String? error;
  bool busy = false;
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        PageTitle(widget.deposit ? 'Пополнение счёта' : 'Вывод средств'),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(controller: amount, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: widget.deposit ? 'от 1 000 ₽' : 'от 2 000 ₽')),
            if (error != null) AlertBox(error!),
            const SizedBox(height: 12),
            GoldButton(
              label: busy ? 'Отправка…' : (widget.deposit ? 'Пополнить' : 'Вывести'),
              onPressed: busy
                  ? null
                  : () async {
                      final v = double.tryParse(amount.text.replaceAll(',', '.'));
                      if (v == null) { setState(() => error = 'Укажите сумму'); return; }
                      setState(() { busy = true; error = null; });
                      try {
                        final msg = widget.deposit ? await ApiClient.instance.deposit(v) : await ApiClient.instance.withdraw(v);
                        if (!mounted) return;
                        Sl.toast(context, msg, kind: widget.deposit ? 'success' : 'warning');
                        await widget.root.refreshMe();
                        widget.root.closeOverlay();
                      } on ApiException catch (e) {
                        setState(() => error = e.message);
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
            ),
          ]),
        ),
      ],
    );
  }
}

class BetsPage extends StatefulWidget {
  const BetsPage({super.key, required this.root});
  final AppRootState root;
  @override
  State<BetsPage> createState() => _BetsPageState();
}

class _BetsPageState extends State<BetsPage> {
  List<BetDto> items = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    ApiClient.instance.bets().then((v) {
      if (mounted) setState(() { items = v; loading = false; });
    }).catchError((_) {
      if (mounted) setState(() => loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Sl.accent));
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        const PageTitle('История ставок'),
        if (items.isEmpty)
          const Panel(child: Text('Ставок не найдено', textAlign: TextAlign.center, style: TextStyle(color: Sl.muted)))
        else
          ...items.map((b) => Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Text(b.eventTitle, style: const TextStyle(fontWeight: FontWeight.w700))),
                      StatusBadge(b.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(b.outcome, style: const TextStyle(color: Sl.accent)),
                  Text('${when(b.createdAt)} · ${b.amount.toStringAsFixed(0)} ₽ × ${b.coefficient.toStringAsFixed(2)}',
                      style: const TextStyle(color: Sl.muted, fontSize: 13)),
                ]),
              )),
      ],
    );
  }
}

class BonusesPage extends StatefulWidget {
  const BonusesPage({super.key, required this.root});
  final AppRootState root;
  @override
  State<BonusesPage> createState() => _BonusesPageState();
}

class _BonusesPageState extends State<BonusesPage> {
  Map<String, dynamic>? data;
  bool loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      data = await ApiClient.instance.bonuses();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Sl.accent));
    final items = (data?['items'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        const PageTitle('Бонусы и акции'),
        Panel(child: Text('До следующего фрибета: ${data?['betsUntilNext'] ?? '—'} ставок', style: const TextStyle(color: Sl.muted))),
        if (items.isEmpty)
          const Panel(child: Text('У вас пока нет бонусов.', textAlign: TextAlign.center, style: TextStyle(color: Sl.muted)))
        else
          ...items.map((b) => Panel(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(b['description']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(b['status']?.toString() ?? '', style: const TextStyle(color: Sl.muted, fontSize: 13)),
                  if (b['canActivate'] == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GoldButton(
                        label: 'Активировать',
                        onPressed: () async {
                          try {
                            final msg = await ApiClient.instance.activateBonus((b['id'] as num).toInt());
                            if (mounted) Sl.toast(context, msg, kind: 'bonus');
                            _load();
                          } on ApiException catch (e) {
                            if (mounted) Sl.toast(context, e.message, kind: 'error');
                          }
                        },
                      ),
                    ),
                ]),
              )),
      ],
    );
  }
}

class NotesPage extends StatefulWidget {
  const NotesPage({super.key, required this.root});
  final AppRootState root;
  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<Map<String, dynamic>> items = [];
  bool loading = true;
  @override
  void initState() {
    super.initState();
    ApiClient.instance.notifications().then((v) {
      if (mounted) setState(() { items = v; loading = false; });
    }).catchError((_) {
      if (mounted) setState(() => loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator(color: Sl.accent));
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        const PageTitle('Уведомления'),
        if (items.isEmpty)
          const Panel(child: Text('Нет уведомлений', textAlign: TextAlign.center, style: TextStyle(color: Sl.muted)))
        else
          ...items.map(notificationFromMap),
      ],
    );
  }
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key, required this.root, required this.user});
  final AppRootState root;
  final Map<String, dynamic> user;
  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final first = TextEditingController(text: widget.user['firstName']?.toString());
  late final last = TextEditingController(text: widget.user['lastName']?.toString());
  late final patronymic = TextEditingController(text: widget.user['patronymic']?.toString() ?? '');
  late String country = widget.user['countryOfResidence']?.toString() == 'Russia' ? 'Russia' : 'USA';
  final password = TextEditingController();
  String? error;
  bool busy = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
      children: [
        const PageTitle('Редактирование профиля'),
        Panel(
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(controller: last, decoration: const InputDecoration(labelText: 'Фамилия')),
            const SizedBox(height: 8),
            TextField(controller: first, decoration: const InputDecoration(labelText: 'Имя')),
            const SizedBox(height: 8),
            TextField(controller: patronymic, decoration: const InputDecoration(labelText: 'Отчество')),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: country,
              dropdownColor: Sl.card,
              items: const [
                DropdownMenuItem(value: 'USA', child: Text('США')),
                DropdownMenuItem(value: 'Russia', child: Text('Россия')),
              ],
              onChanged: (v) => setState(() => country = v ?? 'USA'),
              decoration: const InputDecoration(labelText: 'Страна проживания'),
            ),
            const SizedBox(height: 8),
            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Новый пароль (необязательно)')),
            if (error != null) AlertBox(error!),
            const SizedBox(height: 12),
            GoldButton(
              label: busy ? 'Сохранение…' : 'Сохранить',
              onPressed: busy
                  ? null
                  : () async {
                      setState(() { busy = true; error = null; });
                      try {
                        final msg = await ApiClient.instance.editProfile({
                          'firstName': first.text,
                          'lastName': last.text,
                          'patronymic': patronymic.text,
                          'countryOfResidence': country,
                          'newPassword': password.text.isEmpty ? null : password.text,
                        });
                        if (!mounted) return;
                        Sl.toast(context, msg, kind: 'success');
                        await widget.root.refreshMe();
                        widget.root.closeOverlay();
                      } on ApiException catch (e) {
                        setState(() => error = e.message);
                      } finally {
                        if (mounted) setState(() => busy = false);
                      }
                    },
            ),
          ]),
        ),
      ],
    );
  }
}
