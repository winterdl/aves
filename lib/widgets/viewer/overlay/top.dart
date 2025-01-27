import 'package:aves/model/actions/entry_actions.dart';
import 'package:aves/model/device.dart';
import 'package:aves/model/entry.dart';
import 'package:aves/model/favourites.dart';
import 'package:aves/model/settings/settings.dart';
import 'package:aves/theme/durations.dart';
import 'package:aves/theme/icons.dart';
import 'package:aves/widgets/common/basic/menu.dart';
import 'package:aves/widgets/common/basic/popup_menu_button.dart';
import 'package:aves/widgets/common/extensions/build_context.dart';
import 'package:aves/widgets/common/fx/sweeper.dart';
import 'package:aves/widgets/viewer/action/entry_action_delegate.dart';
import 'package:aves/widgets/viewer/multipage/conductor.dart';
import 'package:aves/widgets/viewer/overlay/common.dart';
import 'package:aves/widgets/viewer/overlay/minimap.dart';
import 'package:aves/widgets/viewer/overlay/notifications.dart';
import 'package:aves/widgets/viewer/page_entry_builder.dart';
import 'package:aves/widgets/viewer/visual/conductor.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

class ViewerTopOverlay extends StatelessWidget {
  final AvesEntry mainEntry;
  final Animation<double> scale;
  final EdgeInsets? viewInsets, viewPadding;
  final bool canToggleFavourite;

  static const double outerPadding = 8;
  static const double innerPadding = 8;

  const ViewerTopOverlay({
    Key? key,
    required this.mainEntry,
    required this.scale,
    required this.canToggleFavourite,
    required this.viewInsets,
    required this.viewPadding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: (viewInsets ?? EdgeInsets.zero) + (viewPadding ?? EdgeInsets.zero),
      child: Padding(
        padding: const EdgeInsets.all(outerPadding),
        child: Selector<MediaQueryData, double>(
          selector: (context, mq) => mq.size.width - mq.padding.horizontal,
          builder: (context, mqWidth, child) {
            final buttonWidth = OverlayButton.getSize(context);
            final availableCount = ((mqWidth - outerPadding * 2 - buttonWidth) / (buttonWidth + innerPadding)).floor();

            return mainEntry.isMultiPage
                ? PageEntryBuilder(
                    multiPageController: context.read<MultiPageConductor>().getController(mainEntry),
                    builder: (pageEntry) => _buildOverlay(context, availableCount, mainEntry, pageEntry: pageEntry),
                  )
                : _buildOverlay(context, availableCount, mainEntry);
          },
        ),
      ),
    );
  }

  Widget _buildOverlay(BuildContext context, int availableCount, AvesEntry mainEntry, {AvesEntry? pageEntry}) {
    pageEntry ??= mainEntry;

    bool _isVisible(EntryAction action) {
      final targetEntry = EntryActions.pageActions.contains(action) ? pageEntry! : mainEntry;
      switch (action) {
        case EntryAction.toggleFavourite:
          return canToggleFavourite;
        case EntryAction.delete:
        case EntryAction.rename:
          return targetEntry.canEdit;
        case EntryAction.rotateCCW:
        case EntryAction.rotateCW:
        case EntryAction.flip:
          return targetEntry.canRotateAndFlip;
        case EntryAction.export:
        case EntryAction.print:
          return !targetEntry.isVideo && device.canPrint;
        case EntryAction.openMap:
          return targetEntry.hasGps;
        case EntryAction.viewSource:
          return targetEntry.isSvg;
        case EntryAction.rotateScreen:
          return settings.isRotationLocked;
        case EntryAction.addShortcut:
          return device.canPinShortcut;
        case EntryAction.copyToClipboard:
        case EntryAction.edit:
        case EntryAction.info:
        case EntryAction.open:
        case EntryAction.setAs:
        case EntryAction.share:
          return true;
        case EntryAction.debug:
          return kDebugMode;
      }
    }

    final buttonRow = Selector<Settings, bool>(
      selector: (context, s) => s.isRotationLocked,
      builder: (context, s, child) {
        final quickActions = settings.viewerQuickActions.where(_isVisible).take(availableCount - 1).toList();
        final inAppActions = EntryActions.inApp.where((action) => !quickActions.contains(action)).where(_isVisible).toList();
        final externalAppActions = EntryActions.externalApp.where(_isVisible).toList();
        return _TopOverlayRow(
          quickActions: quickActions,
          inAppActions: inAppActions,
          externalAppActions: externalAppActions,
          scale: scale,
          mainEntry: mainEntry,
          pageEntry: pageEntry!,
        );
      },
    );

    if (settings.showOverlayMinimap) {
      final viewStateConductor = context.read<ViewStateConductor>();
      final viewStateNotifier = viewStateConductor.getOrCreateController(pageEntry);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buttonRow,
          const SizedBox(height: 8),
          FadeTransition(
            opacity: scale,
            child: Minimap(
              entry: pageEntry,
              viewStateNotifier: viewStateNotifier,
            ),
          )
        ],
      );
    }
    return buttonRow;
  }
}

class _TopOverlayRow extends StatelessWidget {
  final List<EntryAction> quickActions, inAppActions, externalAppActions;
  final Animation<double> scale;
  final AvesEntry mainEntry, pageEntry;

  AvesEntry get favouriteTargetEntry => mainEntry.isBurst ? pageEntry : mainEntry;

  const _TopOverlayRow({
    Key? key,
    required this.quickActions,
    required this.inAppActions,
    required this.externalAppActions,
    required this.scale,
    required this.mainEntry,
    required this.pageEntry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OverlayButton(
          scale: scale,
          child: Navigator.canPop(context) ? const BackButton() : const CloseButton(),
        ),
        const Spacer(),
        ...quickActions.map((action) => _buildOverlayButton(context, action)),
        OverlayButton(
          scale: scale,
          child: MenuIconTheme(
            child: AvesPopupMenuButton<EntryAction>(
              key: const Key('entry-menu-button'),
              itemBuilder: (context) => [
                ...inAppActions.map((action) => _buildPopupMenuItem(context, action)),
                if (pageEntry.canRotateAndFlip) _buildRotateAndFlipMenuItems(context),
                const PopupMenuDivider(),
                ...externalAppActions.map((action) => _buildPopupMenuItem(context, action)),
                if (!kReleaseMode) ...[
                  const PopupMenuDivider(),
                  _buildPopupMenuItem(context, EntryAction.debug),
                ]
              ],
              onSelected: (action) {
                // wait for the popup menu to hide before proceeding with the action
                Future.delayed(Durations.popupMenuAnimation * timeDilation, () => _onActionSelected(context, action));
              },
              onMenuOpened: () {
                // if the menu is opened while overlay is hiding,
                // the popup menu button is disposed and menu items are ineffective,
                // so we make sure overlay stays visible
                const ToggleOverlayNotification(visible: true).dispatch(context);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOverlayButton(BuildContext context, EntryAction action) {
    Widget? child;
    void onPressed() => _onActionSelected(context, action);
    switch (action) {
      case EntryAction.toggleFavourite:
        child = _FavouriteToggler(
          entry: favouriteTargetEntry,
          onPressed: onPressed,
        );
        break;
      case EntryAction.addShortcut:
      case EntryAction.copyToClipboard:
      case EntryAction.delete:
      case EntryAction.export:
      case EntryAction.flip:
      case EntryAction.info:
      case EntryAction.print:
      case EntryAction.rename:
      case EntryAction.rotateCCW:
      case EntryAction.rotateCW:
      case EntryAction.share:
      case EntryAction.rotateScreen:
      case EntryAction.viewSource:
        child = IconButton(
          icon: action.getIcon() ?? const SizedBox(),
          onPressed: onPressed,
          tooltip: action.getText(context),
        );
        break;
      case EntryAction.openMap:
      case EntryAction.open:
      case EntryAction.edit:
      case EntryAction.setAs:
      case EntryAction.debug:
        break;
    }
    return child != null
        ? Padding(
            padding: const EdgeInsetsDirectional.only(end: ViewerTopOverlay.innerPadding),
            child: OverlayButton(
              scale: scale,
              child: child,
            ),
          )
        : const SizedBox.shrink();
  }

  PopupMenuEntry<EntryAction> _buildPopupMenuItem(BuildContext context, EntryAction action) {
    Widget? child;
    switch (action) {
      // in app actions
      case EntryAction.toggleFavourite:
        child = _FavouriteToggler(
          entry: favouriteTargetEntry,
          isMenuItem: true,
        );
        break;
      default:
        child = MenuRow(text: action.getText(context), icon: action.getIcon());
        break;
    }
    return PopupMenuItem(
      value: action,
      child: child,
    );
  }

  PopupMenuItem<EntryAction> _buildRotateAndFlipMenuItems(BuildContext context) {
    Widget buildDivider() => const SizedBox(
          height: 16,
          child: VerticalDivider(
            width: 1,
            thickness: 1,
          ),
        );

    Widget buildItem(EntryAction action) => Expanded(
          child: PopupMenuItem(
            value: action,
            child: Tooltip(
              message: action.getText(context),
              child: Center(child: action.getIcon()),
            ),
          ),
        );

    return PopupMenuItem(
      child: Row(
        children: [
          buildDivider(),
          buildItem(EntryAction.rotateCCW),
          buildDivider(),
          buildItem(EntryAction.rotateCW),
          buildDivider(),
          buildItem(EntryAction.flip),
          buildDivider(),
        ],
      ),
    );
  }

  void _onActionSelected(BuildContext context, EntryAction action) {
    var targetEntry = mainEntry;
    if (mainEntry.isMultiPage && (mainEntry.isBurst || EntryActions.pageActions.contains(action))) {
      final multiPageController = context.read<MultiPageConductor>().getController(mainEntry);
      if (multiPageController != null) {
        final multiPageInfo = multiPageController.info;
        final pageEntry = multiPageInfo?.getPageEntryByIndex(multiPageController.page);
        if (pageEntry != null) {
          targetEntry = pageEntry;
        }
      }
    }
    EntryActionDelegate(targetEntry).onActionSelected(context, action);
  }
}

class _FavouriteToggler extends StatefulWidget {
  final AvesEntry entry;
  final bool isMenuItem;
  final VoidCallback? onPressed;

  const _FavouriteToggler({
    required this.entry,
    this.isMenuItem = false,
    this.onPressed,
  });

  @override
  _FavouriteTogglerState createState() => _FavouriteTogglerState();
}

class _FavouriteTogglerState extends State<_FavouriteToggler> {
  final ValueNotifier<bool> isFavouriteNotifier = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    favourites.addListener(_onChanged);
    _onChanged();
  }

  @override
  void didUpdateWidget(covariant _FavouriteToggler oldWidget) {
    super.didUpdateWidget(oldWidget);
    _onChanged();
  }

  @override
  void dispose() {
    favourites.removeListener(_onChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isFavouriteNotifier,
      builder: (context, isFavourite, child) {
        if (widget.isMenuItem) {
          return isFavourite
              ? MenuRow(
                  text: context.l10n.entryActionRemoveFavourite,
                  icon: const Icon(AIcons.favouriteActive),
                )
              : MenuRow(
                  text: context.l10n.entryActionAddFavourite,
                  icon: const Icon(AIcons.favourite),
                );
        }
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(isFavourite ? AIcons.favouriteActive : AIcons.favourite),
              onPressed: widget.onPressed,
              tooltip: isFavourite ? context.l10n.entryActionRemoveFavourite : context.l10n.entryActionAddFavourite,
            ),
            Sweeper(
              key: ValueKey(widget.entry),
              builder: (context) => const Icon(AIcons.favourite, color: Colors.redAccent),
              toggledNotifier: isFavouriteNotifier,
            ),
          ],
        );
      },
    );
  }

  void _onChanged() {
    isFavouriteNotifier.value = widget.entry.isFavourite;
  }
}
