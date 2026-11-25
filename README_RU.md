# Snap Floater

[En](README.md) | **Ru**

Перетаскиваемая плавающая кнопка для Flutter, которая «прилипает» к заданным позициям на экране.
Управляется программно из любого места дерева виджетов через `SnapFloaterScope.of(context)`.

<p align="center">Чтобы лучше понять, как это работает, посмотрите <a href="https://pavluke.github.io/packages/?pkg=snap_floater">демо</a></p>

<div align="center">
  <a href="https://pavluke.github.io/packages/?pkg=snap_floater" 
     style="background: #10ac84; color: white; padding: 12px 24px; 
            text-decoration: none; border-radius: 6px; 
            font-weight: bold; display: inline-block;">
    Открыть демо
  </a>
</div>

## Введение

При разработке Flutter-приложений часто нужна постоянно доступная плавающая кнопка, которая
не мешает интерфейсу, может быть перемещена пользователем и может показываться или скрываться
в зависимости от состояния приложения. `SnapFloaterScope` оборачивает всё приложение один раз
и берёт на себя всё это — перетаскивание, прилипание, видимость, сохранение позиции — без
единой строки шаблонного кода в ваших экранах.

## Начало работы

Добавьте snap_floater в свой `pubspec.yaml`:

```yaml
dependencies:
  snap_floater: ^0.4.0
```

Или командой:

```bash
flutter pub add snap_floater
```

Импортируйте пакет в вашем Dart-файле:

```dart
import 'package:snap_floater/snap_floater.dart';
```

## Использование

### Базовый пример

Оберните свой `MaterialApp` в `SnapFloaterScope`. Кнопка скрывается на время выполнения
`onPressed` и снова появляется по завершении:

```dart
MaterialApp(
  home: const HomePage(),
  builder: (context, child) => SnapFloaterScope(
    onPressed: () async {
      await someAction();
    },
    child: child,
  ),
);
```

### Своя кнопка и анимация превью

```dart
MaterialApp(
  home: const HomePage(),
  builder: (context, child) => SnapFloaterScope.builder(
    builder: (context) => FancyButton(
      onPressed: () => SnapFloaterScope.of(context).runHidden(
        () => someAction(),
      ),
    ),
    previewBuilder: SnapFloaterAnimation.blur,
    child: child,
  ),
);
```

### Управление из любого места дерева

```dart
final controller = SnapFloaterScope.of(context);

controller.show();
controller.hide();
controller.snapTo(.topRight);

// Скрыть на время выполнения асинхронной работы, показать по завершении — даже если она выбросит исключение
await controller.runHidden(() async {
  await Navigator.of(context).push(...);
});
```

## Настройки

Настраивается через `SnapFloaterSettings`:

```dart
SnapFloaterScope(
  onPressed: () async {
    await someAction();
  },
  settings: const SnapFloaterSettings(
    snapAlignments: [
      .bottomRight, // начальная позиция
      .topRight,
      .bottomLeft,
      .topLeft,
    ],
    isEnabled: true,
    showPreview: true,
    storage: MyStorage(),
  ),
  child: child,
)
```

| Параметр         | По умолчанию    | Описание                                                                                                                                         |
| ---------------- | --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `snapAlignments` | `[bottomRight]` | Доступные точки прилипания. Не должен быть пустым. Первый элемент — начальная позиция. Перетаскивание отключается, если элементов меньше двух    |
| `isEnabled`      | `true`          | При `false` кнопка скрыта, `controller.isVisible` равен `false`, а `show()` не даёт эффекта                                                      |
| `showPreview`    | `true`          | Показывать превью-виджеты в точках прилипания во время перетаскивания                                                                            |
| `storage`        | `null`          | Передайте, чтобы сохранять позицию между запусками. Без него кнопка стартует с первого элемента `snapAlignments` при каждом холодном запуске     |
| `dragMode`       | `longPress`     | Как начинается перетаскивание: `longPress` — чтобы избежать случайных перетаскиваний с кликабельной кнопки, `pan` — мгновенный отклик на касание |

> **Примечание:** Сохранённые позиции, которых больше нет в `snapAlignments`, игнорируются.

> **Примечание:** `initialAlignment` устарел и игнорируется. Вместо него
> ставьте нужную начальную позицию первым элементом в `snapAlignments`.

## Анимации превью

Передайте любой статический метод из `SnapFloaterAnimation` в `previewBuilder`:

```dart
SnapFloaterScope.builder(
  previewBuilder: SnapFloaterAnimation.slide,
  ...
)
```

| Анимация                     | Описание                                             |
| ---------------------------- | ---------------------------------------------------- |
| `SnapFloaterAnimation.base`  | Мгновенно размещается, без анимации позиции          |
| `SnapFloaterAnimation.slide` | Скользит из текущей позиции перетаскивания к целевой |
| `SnapFloaterAnimation.pop`   | Перескок масштаба при появлении: `0 → 1.15 → 1.0`    |
| `SnapFloaterAnimation.blur`  | Переход от размытия к резкости при появлении         |

### Своя анимация превью

Любая функция, соответствующая `PreviewBuilder`, работает как кастомная анимация:

```dart
Widget CustomPreview(
  BuildContext context,
  Size floaterSize,
  Offset currentOffset,
  Offset targetOffset,
  bool isVisible,
  bool isNearest,
  Widget child,
) => Transform.translate(
  offset: targetOffset,
  child: AnimatedOpacity(
    duration: const Duration(milliseconds: 200),
    opacity: isVisible ? (isNearest ? .8 : .25) : 0,
    child: child,
  ),
);

SnapFloaterScope.builder(
  previewBuilder: CustomPreview.new,
  ...
)
```

## Постоянное хранилище

Реализуйте `SnapFloaterStorage`, чтобы сохранять позицию кнопки между запусками приложения:

```dart
class Storage implements SnapFloaterStorage {
  Storage(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'snap_floater_data';

  @override
  Future<SnapFloaterStorageModel?> read() async {
    final raw = _prefs.getString(_key);
    if (raw == null) return null;
    return SnapFloaterStorageModel.fromJson(jsonDecode(raw));
  }

  @override
  Future<void> write(SnapFloaterStorageModel model) =>
      _prefs.setString(_key, jsonEncode(model.toJson()));

  @override
  Future<void> clear() => _prefs.remove(_key);
}
```

Передайте реализацию через `SnapFloaterSettings`:

```dart
SnapFloaterScope(
  onPressed: () async {
    await someAction();
  },
  settings: SnapFloaterSettings(
    storage: Storage(await SharedPreferences.getInstance()),
  ),
  child: child,
)
```

## Возможности

- Прилипание к заданным точкам при отпускании после перетаскивания
- Показ / скрытие программно из любого места дерева виджетов
- Автоматическое скрытие на время асинхронного действия и автоматическое восстановление по завершении
- Своя кнопка и своя анимация превью через фабричный конструктор
- Превью-виджеты в точках прилипания во время перетаскивания
- Сохранение позиции между запусками приложения через подключаемый интерфейс хранилища
- Учитывает safe area и отступы от краёв
- Позиционируется внутри собственных границ scope (обычно — всё приложение)
- Архитектурно невозможно завести больше одной кнопки на поддерево

## Справочник API

### `SnapFloaterScope`

| Член                                                              | Описание                                                                         |
| ----------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `SnapFloaterScope({onPressed, child, ...})`                       | Стандартная фабрика — рендерит `BasicSnapFloaterButton`                          |
| `SnapFloaterScope.builder({builder, previewBuilder, child, ...})` | Своя кнопка и превью                                                             |
| `SnapFloaterScope.of(context)`                                    | Возвращает ближайший `SnapFloaterController`. Бросает исключение, если не найден |
| `SnapFloaterScope.maybeOf(context)`                               | Возвращает `null`, если не найден                                                |

### `SnapFloaterController`

| Член                | Описание                                                                                                                                   |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `alignment`         | Текущая точка прилипания                                                                                                                   |
| `isVisible`         | Видна ли кнопка сейчас                                                                                                                     |
| `isDragging`        | Активно ли сейчас перетаскивание пользователем                                                                                             |
| `show()`            | Показывает кнопку                                                                                                                          |
| `hide()`            | Скрывает кнопку                                                                                                                            |
| `snapTo(alignment)` | Прилипает к указанной точке и сохраняет изменение                                                                                          |
| `runHidden(action)` | Скрывает на время выполнения действия (синхронного или асинхронного), затем показывает снова; игнорируется, пока активно другое выполнение |

## История изменений

Список изменений доступен в файле [CHANGELOG.md](CHANGELOG.md)

## Участие в разработке

Будем рады вашему вкладу в проект. Если вы нашли баг или хотите добавить новую
функцию, но не знаете, как это исправить или реализовать, напишите в
[issues](https://github.com/pavluke/snap_floater/issues). Если вы исправили баг или
реализовали функцию, отправьте
[pull request](https://github.com/pavluke/snap_floater/pulls).

## Лицензия

MIT License — подробности в файле [LICENSE](LICENSE)
