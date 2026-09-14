import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

typedef CatalogNavigationAction = void Function();

class CatalogPlatformAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CatalogPlatformAppBar({
    required this.title,
    this.dataVersionLabel,
    this.onShowInformation,
    this.informationAccessibilityLabel,
    super.key,
  });

  final String title;
  final String? dataVersionLabel;
  final CatalogNavigationAction? onShowInformation;
  final String? informationAccessibilityLabel;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (!isIOS) {
      return AppBar(
        key: const ValueKey('android-expressive-top-navigation'),
        title: Text(title),
        actions: <Widget>[
          if (dataVersionLabel != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ActionChip(
                visualDensity: VisualDensity.compact,
                onPressed: onShowInformation,
                label: Text(dataVersionLabel!),
              ),
            ),
          if (onShowInformation != null)
            IconButton.filledTonal(
              tooltip:
                  informationAccessibilityLabel ??
                  MaterialLocalizations.of(context).moreButtonTooltip,
              onPressed: onShowInformation,
              icon: const Icon(Icons.info_outline_rounded),
            ),
          if (onShowInformation != null) const SizedBox(width: 8),
        ],
      );
    }

    final canPop = Navigator.of(context).canPop();
    final topPadding = MediaQuery.paddingOf(context).top;
    return ColoredBox(
      key: const ValueKey('ios-liquid-glass-top-navigation'),
      color: Colors.transparent,
      child: Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: _NativeCatalogNavigation(
          kind: _NativeNavigationKind.top,
          title: title,
          dataVersionLabel: dataVersionLabel,
          showsBackButton: canPop,
          backAccessibilityLabel: MaterialLocalizations.of(context)
              .backButtonTooltip,
          informationAccessibilityLabel: onShowInformation == null
              ? null
              : informationAccessibilityLabel ??
                    MaterialLocalizations.of(context).moreButtonTooltip,
          onBack: canPop ? () => Navigator.of(context).maybePop() : null,
          onShowInformation: onShowInformation,
        ),
      ),
    );
  }
}

class CatalogPlatformBottomNavigation extends StatelessWidget {
  const CatalogPlatformBottomNavigation({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.labels,
    super.key,
  }) : assert(labels.length == 4);

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final isIOS = Theme.of(context).platform == TargetPlatform.iOS;
    if (isIOS) {
      return _NavigationSafeAreaBackdrop(
        child: _NativeCatalogNavigation(
          key: const ValueKey('ios-liquid-glass-bottom-navigation'),
          kind: _NativeNavigationKind.bottom,
          selectedIndex: selectedIndex,
          labels: labels,
          onDestinationSelected: onDestinationSelected,
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return _NavigationSafeAreaBackdrop(
      child: SafeArea(
        key: const ValueKey('android-floating-bottom-navigation'),
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Material(
          key: const ValueKey('android-floating-navigation-surface'),
          color: scheme.surfaceContainerHigh,
          elevation: 8,
          shadowColor: scheme.shadow.withValues(alpha: 0.18),
          shape: StadiumBorder(
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            key: const ValueKey('android-expressive-bottom-navigation'),
            height: 72,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            destinations: <NavigationDestination>[
              NavigationDestination(
                key: const ValueKey('android-navigation-destination-0'),
                icon: const Icon(Icons.pets_outlined),
                selectedIcon: const Icon(Icons.pets_rounded),
                label: labels[0],
              ),
              NavigationDestination(
                key: const ValueKey('android-navigation-destination-1'),
                icon: const Icon(Icons.auto_awesome_outlined),
                selectedIcon: const Icon(Icons.auto_awesome_rounded),
                label: labels[1],
              ),
              NavigationDestination(
                key: const ValueKey('android-navigation-destination-2'),
                icon: const Icon(Icons.dashboard_customize_outlined),
                selectedIcon: const Icon(Icons.dashboard_customize_rounded),
                label: labels[2],
              ),
              NavigationDestination(
                key: const ValueKey('android-navigation-destination-3'),
                icon: const Icon(Icons.settings_outlined),
                selectedIcon: const Icon(Icons.settings_rounded),
                label: labels[3],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavigationSafeAreaBackdrop extends StatelessWidget {
  const _NavigationSafeAreaBackdrop({required this.child});

  final Widget child;

  static const _blurLayers = <({double heightFactor, double sigma})>[
    (heightFactor: 1.00, sigma: 0.9),
    (heightFactor: 0.86, sigma: 1.3),
    (heightFactor: 0.72, sigma: 1.8),
    (heightFactor: 0.58, sigma: 2.4),
    (heightFactor: 0.44, sigma: 3.1),
    (heightFactor: 0.30, sigma: 4.0),
    (heightFactor: 0.16, sigma: 5.2),
  ];

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        Positioned.fill(
          child: ClipRect(
            key: const ValueKey('navigation-safe-area-backdrop'),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                for (var index = 0; index < _blurLayers.length; index++)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: FractionallySizedBox(
                      widthFactor: 1,
                      heightFactor: _blurLayers[index].heightFactor,
                      child: ClipRect(
                        child: BackdropFilter(
                          key: ValueKey(
                            'navigation-progressive-blur-band-$index',
                          ),
                          filter: ui.ImageFilter.blur(
                            sigmaX: _blurLayers[index].sigma,
                            sigmaY: _blurLayers[index].sigma,
                          ),
                          child: const ColoredBox(color: Colors.transparent),
                        ),
                      ),
                    ),
                  ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        Colors.transparent,
                        surface.withValues(alpha: 0.02),
                        surface.withValues(alpha: 0.08),
                        surface.withValues(alpha: 0.18),
                      ],
                      stops: const <double>[0, 0.28, 0.68, 1],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

enum _NativeNavigationKind { top, bottom }

class _NativeCatalogNavigation extends StatefulWidget {
  const _NativeCatalogNavigation({
    required this.kind,
    this.title,
    this.dataVersionLabel,
    this.showsBackButton = false,
    this.backAccessibilityLabel,
    this.informationAccessibilityLabel,
    this.selectedIndex = 0,
    this.labels = const <String>[],
    this.onBack,
    this.onShowInformation,
    this.onDestinationSelected,
    super.key,
  });

  final _NativeNavigationKind kind;
  final String? title;
  final String? dataVersionLabel;
  final bool showsBackButton;
  final String? backAccessibilityLabel;
  final String? informationAccessibilityLabel;
  final int selectedIndex;
  final List<String> labels;
  final CatalogNavigationAction? onBack;
  final CatalogNavigationAction? onShowInformation;
  final ValueChanged<int>? onDestinationSelected;

  @override
  State<_NativeCatalogNavigation> createState() =>
      _NativeCatalogNavigationState();
}

class _NativeCatalogNavigationState extends State<_NativeCatalogNavigation> {
  MethodChannel? _channel;

  bool get _usesNativeUIKit =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Map<String, Object?> _creationParameters(BuildContext context) =>
      <String, Object?>{
        'kind': widget.kind.name,
        'title': widget.title,
        'dataVersionLabel': widget.dataVersionLabel,
        'showsBackButton': widget.showsBackButton,
        'backAccessibilityLabel': widget.backAccessibilityLabel,
        'informationAccessibilityLabel': widget.informationAccessibilityLabel,
        'selectedIndex': widget.selectedIndex,
        'labels': widget.labels,
        'brightness': Theme.of(context).brightness.name,
      };

  @override
  void didUpdateWidget(covariant _NativeCatalogNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    final channel = _channel;
    if (channel != null) {
      channel.invokeMethod<void>('update', _creationParameters(context));
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  Future<void> _onPlatformViewCreated(int id) async {
    final channel = MethodChannel('world.roco.handbook/catalog_navigation/$id');
    _channel = channel;
    channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case 'back':
          widget.onBack?.call();
          return;
        case 'showInformation':
          widget.onShowInformation?.call();
          return;
        case 'destinationSelected':
          final index = call.arguments as int?;
          if (index != null) {
            widget.onDestinationSelected?.call(index);
          }
          return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_usesNativeUIKit) {
      return _buildFlutterFallback(context);
    }
    final height = widget.kind == _NativeNavigationKind.top
        ? 56.0
        : 58.0 + MediaQuery.viewPaddingOf(context).bottom;
    final platformView = UiKitView(
      viewType: 'world.roco.handbook/catalog_navigation',
      creationParams: _creationParameters(context),
      creationParamsCodec: const StandardMessageCodec(),
      onPlatformViewCreated: _onPlatformViewCreated,
    );
    return SizedBox(
      height: height,
      child: widget.kind == _NativeNavigationKind.top
          ? platformView
          : Stack(
              fit: StackFit.expand,
              children: <Widget>[
                IgnorePointer(child: platformView),
                Row(
                  children: <Widget>[
                    for (var index = 0; index < widget.labels.length; index++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: widget.selectedIndex == index,
                          label: widget.labels[index],
                          child: GestureDetector(
                            key: ValueKey('ios-navigation-destination-$index'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () =>
                                widget.onDestinationSelected?.call(index),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildFlutterFallback(BuildContext context) {
    if (widget.kind == _NativeNavigationKind.bottom) {
      return CupertinoTabBar(
        currentIndex: widget.selectedIndex,
        onTap: widget.onDestinationSelected,
        backgroundColor: CupertinoDynamicColor.resolve(
          CupertinoTheme.of(context).barBackgroundColor.withValues(alpha: 0.82),
          context,
        ),
        activeColor: Theme.of(context).colorScheme.primary,
        border: null,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.book),
            activeIcon: const Icon(CupertinoIcons.book_fill),
            label: widget.labels[0],
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.sparkles),
            label: widget.labels[1],
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.square_grid_2x2),
            activeIcon: const Icon(CupertinoIcons.square_grid_2x2_fill),
            label: widget.labels[2],
          ),
          BottomNavigationBarItem(
            icon: const Icon(CupertinoIcons.settings),
            activeIcon: const Icon(CupertinoIcons.settings_solid),
            label: widget.labels[3],
          ),
        ],
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface.withValues(alpha: 0.88),
      child: Row(
        children: <Widget>[
          if (widget.showsBackButton)
            IconButton(
              tooltip: widget.backAccessibilityLabel,
              onPressed: widget.onBack,
              icon: const Icon(CupertinoIcons.back),
            )
          else
            const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (widget.dataVersionLabel != null)
            TextButton(
              onPressed: widget.onShowInformation,
              child: Text(widget.dataVersionLabel!),
            ),
          if (widget.onShowInformation != null)
            IconButton(
              tooltip: widget.informationAccessibilityLabel,
              onPressed: widget.onShowInformation,
              icon: const Icon(CupertinoIcons.info),
            ),
          const SizedBox(width: 4),
        ],
      ),
    );
  }
}
