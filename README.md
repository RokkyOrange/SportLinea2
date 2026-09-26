# БК «СпортЛиния»

Курсовой проект: веб-приложение АРМ сотрудника и мобильное приложение игрока.

## Состав

- **SportLinea.Admin** — сайт букмекера и суперпользователя (ASP.NET Core), порт 5207. Здесь же REST API для мобильного клиента.
- **sportlinea_app** — мобильное приложение игрока (Flutter).
- **SportLinea.Core** — общая логика и доступ к базе.
- **Database** — SQL-скрипты.

## Требования

- .NET SDK 9
- SQL Server LocalDB (ставится вместе с Visual Studio)
- для сборки приложения: Flutter SDK

## Запуск сайта (АРМ)

```text
cd SportLinea.Admin
dotnet run --launch-profile http
```

Адрес: http://localhost:5207

При первом запуске создаются базы SportLineaDb и SportLineaAdmin, тестовые учётные записи и демонстрационные события.

## Тестовые учётные записи

| Роль | Email | Пароль |
|------|-------|--------|
| Игрок (мобильное приложение) | player@sportlinea.ru | Player123! |
| Букмекер | bookmaker@sportlinea.ru | Book123! |
| Суперпользователь | admin@sportlinea.ru | Admin123! |

Сотрудники входят на сайте АРМ. Игрок входит только в мобильном приложении.

## Мобильное приложение

```text
cd sportlinea_app
flutter pub get
flutter run
```

По умолчанию клиент обращается к http://localhost:5207 (на Android-эмуляторе — http://10.0.2.2:5207). Сайт АРМ должен быть запущен.

Сборка APK:

```text
flutter build apk --release
```

Для телефона в той же Wi-Fi, что и компьютер с АРМ, укажите адрес ПК:

```text
flutter build apk --release --dart-define=API_URL=http://АДРЕС_ПК:5207
```
