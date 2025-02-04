import 'package:macos_ui/macos_ui.dart';
import 'package:macos_ui/src/library.dart';

const Duration _kExpand = Duration(milliseconds: 200);
const ShapeBorder _defaultShape = RoundedRectangleBorder(
  //TODO: consider changing to 4.0 or 5.0 - App Store, Notes and Mail seem to use 4.0 or 5.0
  borderRadius: BorderRadius.all(Radius.circular(5.0)),
);

/// {@template sidebarItemSize}
/// Enumerates the size specifications of [SidebarItem]s
///
/// Values were adapted from https://developer.apple.com/design/human-interface-guidelines/components/navigation-and-search/sidebars/#platform-considerations
/// and were eyeballed against apps like App Store, Notes, and Mail.
/// {@endtemplate}
enum SidebarItemSize {
  /// A small [SidebarItem]. Has a [height] of 24 and an [iconSize] of 12.
  small(24.0, 12.0),

  /// A medium [SidebarItem]. Has a [height] of 28 and an [iconSize] of 16.
  medium(29.0, 16.0),

  /// A large [SidebarItem]. Has a [height] of 32 and an [iconSize] of 20.0.
  large(36.0, 18.0);

  /// {@macro sidebarItemSize}
  const SidebarItemSize(
    this.height,
    this.iconSize,
  );

  /// The height of the [SidebarItem].
  final double height;

  /// The maximum size of the [SidebarItem]'s leading icon.
  final double iconSize;
}

/// A scrollable widget that renders [SidebarItem]s.
///
/// See also:
///
///  * [SidebarItem], the items used by this sidebar
///  * [Sidebar], a side bar used alongside [MacosScaffold]
class SidebarItems extends StatelessWidget {
  /// Creates a scrollable widget that renders [SidebarItem]s.
  const SidebarItems({
    super.key,
    required this.items,
    required this.currentSelected,
    required this.onChanged,
    this.currentSecondarySelected,
    this.onSecondaryChanged,
    this.itemSize = SidebarItemSize.medium,
    this.scrollController,
    this.selectedColor,
    this.unselectedColor,
    this.shape,
    this.cursor = SystemMouseCursors.basic,
  });

  /// The [SidebarItem]s used by the sidebar. If no items are provided,
  /// the sidebar is not rendered.
  final List<SidebarItem> items;

  /// The current selected index. It must be in the range of 0 to
  /// [items.length]
  final SidebarItem? currentSelected;

  /// The secondary selected, if selected for context menu
  final SidebarItem? currentSecondarySelected;

  /// Called when the current selected index should be changed.
  final ValueChanged<SidebarItem> onChanged;

  /// Called when the current secondary selected index should be changed.
  final ValueChanged<SidebarItem?>? onSecondaryChanged;

  /// The size specifications for all [items].
  ///
  /// Defaults to [SidebarItemSize.medium].
  final SidebarItemSize itemSize;

  /// The scroll controller used by this sidebar. If null, a local scroll
  /// controller is created.
  final ScrollController? scrollController;

  /// The color to paint the item when it's selected.
  ///
  /// If null, [MacosThemeData.primaryColor] is used.
  final Color? selectedColor;

  /// The color to paint the item when it's unselected.
  ///
  /// Defaults to transparent.
  final Color? unselectedColor;

  /// The [shape] property specifies the outline (border) of the
  /// decoration. The shape must not be null. It's used alongside
  /// [selectedColor].
  final ShapeBorder? shape;

  /// Specifies the kind of cursor to use for all sidebar items.
  ///
  /// Defaults to [SystemMouseCursors.basic].
  final MouseCursor? cursor;

  List<SidebarItem> get _allItems {
    List<SidebarItem> result = [];
    for (var element in items) {
      if (element.disclosureItems != null) {
        result.addAll(element.disclosureItems!);
      } else {
        result.add(element);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    assert(debugCheckHasMacosTheme(context));
    final theme = MacosTheme.of(context);
    return IconTheme.merge(
      data: const IconThemeData(size: 20),
      child: _SidebarItemsConfiguration(
        selectedColor: selectedColor ?? theme.primaryColor,
        unselectedColor: unselectedColor ?? MacosColors.transparent,
        shape: shape ?? _defaultShape,
        itemSize: itemSize,
        child: ListView(
          controller: scrollController,
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.all(10.0 - theme.visualDensity.horizontal),
          children: List.generate(items.length, (index) {
            final item = items[index];
            if (item.disclosureItems != null) {
              return MouseRegion(
                cursor: cursor!,
                child: _DisclosureSidebarItem(
                  item: item,
                  selectedItem: currentSelected,
                  onChanged: (item) {
                    onChanged(item);
                    if (onSecondaryChanged != null) {
                      onSecondaryChanged!(null);
                    }
                  },
                  secondarySelectedItem: currentSecondarySelected,
                  onSecondaryChanged: onSecondaryChanged,
                ),
              );
            }
            return MouseRegion(
              cursor: cursor!,
              child: _SidebarItem(
                item: item,
                selected: currentSelected == item,
                secondarySelected: currentSecondarySelected == item,
                onClick: () {
                  onChanged(item);
                  if (onSecondaryChanged != null) {
                    onSecondaryChanged!(null);
                  }
                },
                onSecondaryClick: () {
                  if (onSecondaryChanged != null) {
                    onSecondaryChanged!(item);
                  }
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _SidebarItemsConfiguration extends InheritedWidget {
  // ignore: use_super_parameters
  const _SidebarItemsConfiguration({
    Key? key,
    required super.child,
    this.selectedColor = MacosColors.transparent,
    this.unselectedColor = MacosColors.transparent,
    this.shape = _defaultShape,
    this.itemSize = SidebarItemSize.medium,
  }) : super(key: key);

  final Color selectedColor;
  final Color unselectedColor;
  final ShapeBorder shape;
  final SidebarItemSize itemSize;

  static _SidebarItemsConfiguration of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_SidebarItemsConfiguration>()!;
  }

  @override
  bool updateShouldNotify(_SidebarItemsConfiguration oldWidget) {
    return true;
  }
}

/// A macOS style navigation-list item intended for use in a [Sidebar]
class _SidebarItem extends StatelessWidget {
  /// Builds a [_SidebarItem].
  // ignore: use_super_parameters
  const _SidebarItem({
    Key? key,
    required this.item,
    required this.onClick,
    required this.selected,
    required this.secondarySelected,
    this.onSecondaryClick,
  }) : super(key: key);

  /// The widget to lay out first.
  ///
  /// Typically an [Icon]
  final SidebarItem item;

  /// Whether the item is selected or not
  final bool selected;

  /// Whether the item is selected or not
  final bool secondarySelected;

  /// A function to perform when the widget is clicked or tapped.
  ///
  /// Typically a [Navigator] call
  final VoidCallback? onClick;

  /// A function to perform when the widget is right clicked.
  final VoidCallback? onSecondaryClick;

  void _handleActionTap() async {
    onClick?.call();
  }

  Map<Type, Action<Intent>> get _actionMap => <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) => _handleActionTap(),
        ),
        ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
          onInvoke: (ButtonActivateIntent intent) => _handleActionTap(),
        ),
      };

  bool get hasLeading => item.leading != null;
  bool get hasTrailing => item.trailing != null;

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMacosTheme(context));
    final theme = MacosTheme.of(context);

    final selectedColor = MacosDynamicColor.resolve(
      item.selectedColor ??
          _SidebarItemsConfiguration.of(context).selectedColor,
      context,
    );
    final unselectedColor = MacosDynamicColor.resolve(
      item.unselectedColor ??
          _SidebarItemsConfiguration.of(context).unselectedColor,
      context,
    );

    final double spacing = 10.0 + theme.visualDensity.horizontal;
    final itemSize = _SidebarItemsConfiguration.of(context).itemSize;
    TextStyle? labelStyle;
    switch (itemSize) {
      case SidebarItemSize.small:
        labelStyle = theme.typography.subheadline;
        break;
      case SidebarItemSize.medium:
        labelStyle = theme.typography.body;
        break;
      case SidebarItemSize.large:
        labelStyle = theme.typography.title3;
        break;
    }

    return Semantics(
      label: item.semanticLabel,
      button: true,
      focusable: true,
      focused: item.focusNode?.hasFocus,
      enabled: onClick != null,
      selected: selected,
      child: GestureDetector(
        onTap: onClick,
        onSecondaryTap: onSecondaryClick,
        child: FocusableActionDetector(
          focusNode: item.focusNode,
          descendantsAreFocusable: false,
          enabled: onClick != null,
          //mouseCursor: SystemMouseCursors.basic,
          actions: _actionMap,
          child: Container(
            width: 134.0 + theme.visualDensity.horizontal,
            height: itemSize.height + theme.visualDensity.vertical,
            decoration: selected
                ? ShapeDecoration(
                    color: selectedColor,
                    shape: item.shape ??
                        _SidebarItemsConfiguration.of(context).shape,
                  )
                : secondarySelected
                    ? BoxDecoration(
                        border: Border.all(color: selectedColor),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(5.0)))
                    : ShapeDecoration(
                        color: unselectedColor,
                        shape: item.shape ??
                            _SidebarItemsConfiguration.of(context).shape,
                      ),
            padding: EdgeInsets.symmetric(
              vertical: 7 + theme.visualDensity.horizontal,
              horizontal: spacing,
            ),
            child: Row(
              children: [
                if (hasLeading)
                  Padding(
                    padding: EdgeInsets.only(right: spacing),
                    child: MacosIconTheme.merge(
                      data: MacosIconThemeData(
                        color: selected
                            ? MacosColors.white
                            : MacosColors.controlAccentColor,
                        size: itemSize.iconSize,
                      ),
                      child: item.leading!,
                    ),
                  ),
                DefaultTextStyle(
                  style: labelStyle.copyWith(
                    color: selected ? textLuminance(selectedColor) : null,
                  ),
                  child: item.label,
                ),
                if (hasTrailing) ...[
                  const Spacer(),
                  DefaultTextStyle(
                    style: labelStyle.copyWith(
                      color: selected ? textLuminance(selectedColor) : null,
                    ),
                    child: item.trailing!,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DisclosureSidebarItem extends StatefulWidget {
  // ignore: use_super_parameters
  _DisclosureSidebarItem({
    Key? key,
    required this.item,
    this.selectedItem,
    this.secondarySelectedItem,
    this.onChanged,
    this.onSecondaryChanged,
  }) : super(key: key);

  final SidebarItem item;

  final SidebarItem? selectedItem;

  final SidebarItem? secondarySelectedItem;

  /// A function to perform when the widget is clicked or tapped.
  ///
  /// Typically a [Navigator] call
  final ValueChanged<SidebarItem>? onChanged;

  /// A function to perform when the widget is right clicked.
  ///
  /// Typically a [Navigator] call
  final ValueChanged<SidebarItem>? onSecondaryChanged;

  @override
  __DisclosureSidebarItemState createState() => __DisclosureSidebarItemState();
}

class __DisclosureSidebarItemState extends State<_DisclosureSidebarItem>
    with SingleTickerProviderStateMixin {
  static final Animatable<double> _easeInTween =
      CurveTween(curve: Curves.easeIn);
  static final Animatable<double> _halfTween =
      Tween<double>(begin: 0.0, end: 0.25);

  late AnimationController _controller;
  late Animation<double> _iconTurns;
  late Animation<double> _heightFactor;

  bool _isExpanded = false;

  bool get hasLeading => widget.item.leading != null;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: _kExpand, vsync: this);
    _heightFactor = _controller.drive(_easeInTween);
    _iconTurns = _controller.drive(_halfTween.chain(_easeInTween));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse().then<void>((void value) {
          if (!mounted) return;
          setState(() {
            // Rebuild without widget.children.
          });
        });
      }
      PageStorage.of(context)?.writeState(context, _isExpanded);
    });
    // widget.onExpansionChanged?.call(_isExpanded);
  }

  Widget _buildChildren(BuildContext context, Widget? child) {
    final theme = MacosTheme.of(context);
    final double spacing = 10.0 + theme.visualDensity.horizontal;

    final itemSize = _SidebarItemsConfiguration.of(context).itemSize;
    TextStyle? labelStyle;
    switch (itemSize) {
      case SidebarItemSize.small:
        labelStyle = theme.typography.subheadline;
        break;
      case SidebarItemSize.medium:
        labelStyle = theme.typography.body;
        break;
      case SidebarItemSize.large:
        labelStyle = theme.typography.title3;
        break;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: double.infinity,
          child: _SidebarItem(
            item: SidebarItem(
              label: widget.item.label,
              leading: GestureDetector(
                onTap: () => _handleTap(),
                child: Row(
                  children: [
                    RotationTransition(
                      turns: _iconTurns,
                      child: Icon(
                        CupertinoIcons.chevron_right,
                        size: 12.0,
                        color: theme.brightness == Brightness.light
                            ? MacosColors.black
                            : MacosColors.white,
                      ),
                    ),
                    if (hasLeading)
                      Padding(
                        padding: EdgeInsets.only(left: spacing),
                        child: MacosIconTheme.merge(
                          data: MacosIconThemeData(size: itemSize.iconSize),
                          child: widget.item.leading!,
                        ),
                      ),
                  ],
                ),
              ),
              unselectedColor: MacosColors.transparent,
              focusNode: widget.item.focusNode,
              semanticLabel: widget.item.semanticLabel,
              shape: widget.item.shape,
              trailing: widget.item.trailing,
            ),
            onClick: () {
              widget.onChanged?.call(widget.item);
              setState(() {});
            },
            onSecondaryClick: () {
              widget.onSecondaryChanged?.call(widget.item);
              setState(() {});
            },
            selected: widget.selectedItem == widget.item,
            secondarySelected: widget.secondarySelectedItem == widget.item,
          ),
        ),
        ClipRect(
          child: DefaultTextStyle(
            style: labelStyle,
            child: Align(
              alignment: Alignment.centerLeft,
              heightFactor: _heightFactor.value,
              child: child,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMacosTheme(context));
    final theme = MacosTheme.of(context);

    final bool closed = !_isExpanded && _controller.isDismissed;

    final Widget result = Offstage(
      offstage: closed,
      child: TickerMode(
        enabled: !closed,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: (widget.item.disclosureItems ?? []).map((item) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24.0 + theme.visualDensity.horizontal,
              ),
              child: SizedBox(
                width: double.infinity,
                child: (item.disclosureItems ?? []).isEmpty
                    ? _SidebarItem(
                        item: item,
                        onClick: () => widget.onChanged?.call(item),
                        onSecondaryClick: () =>
                            widget.onSecondaryChanged?.call(item),
                        selected: widget.selectedItem == item,
                        secondarySelected: widget.secondarySelectedItem == item,
                      )
                    : _DisclosureSidebarItem(
                        item: item,
                        selectedItem: widget.selectedItem,
                        onChanged: (item) {
                          widget.onChanged?.call(item);
                        },
                        secondarySelectedItem: widget.secondarySelectedItem,
                        onSecondaryChanged: widget.onSecondaryChanged,
                      ),
              ),
            );
          }).toList(),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _controller.view,
      builder: _buildChildren,
      child: closed ? null : result,
    );
  }
}
