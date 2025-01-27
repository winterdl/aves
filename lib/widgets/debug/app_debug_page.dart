import 'package:aves/model/entry.dart';
import 'package:aves/model/source/collection_source.dart';
import 'package:aves/services/analysis_service.dart';
import 'package:aves/widgets/common/identity/aves_expansion_tile.dart';
import 'package:aves/widgets/common/providers/media_query_data_provider.dart';
import 'package:aves/widgets/debug/android_apps.dart';
import 'package:aves/widgets/debug/android_codecs.dart';
import 'package:aves/widgets/debug/android_dirs.dart';
import 'package:aves/widgets/debug/android_env.dart';
import 'package:aves/widgets/debug/cache.dart';
import 'package:aves/widgets/debug/database.dart';
import 'package:aves/widgets/debug/overlay.dart';
import 'package:aves/widgets/debug/report.dart';
import 'package:aves/widgets/debug/settings.dart';
import 'package:aves/widgets/debug/storage.dart';
import 'package:aves/widgets/viewer/info/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

class AppDebugPage extends StatefulWidget {
  static const routeName = '/debug';

  const AppDebugPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AppDebugPageState();
}

class _AppDebugPageState extends State<AppDebugPage> {
  CollectionSource get source => context.read<CollectionSource>();

  Set<AvesEntry> get visibleEntries => source.visibleEntries;

  static OverlayEntry? _taskQueueOverlayEntry;

  @override
  Widget build(BuildContext context) {
    return MediaQueryDataProvider(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Debug'),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(8),
            children: [
              _buildGeneralTabView(),
              const DebugAndroidAppSection(),
              const DebugAndroidCodecSection(),
              const DebugAndroidDirSection(),
              const DebugAndroidEnvironmentSection(),
              const DebugCacheSection(),
              const DebugAppDatabaseSection(),
              const DebugErrorReportingSection(),
              const DebugSettingsSection(),
              const DebugStorageSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralTabView() {
    final catalogued = visibleEntries.where((entry) => entry.isCatalogued);
    final withGps = catalogued.where((entry) => entry.hasGps);
    final withAddress = withGps.where((entry) => entry.hasAddress);
    final withFineAddress = withGps.where((entry) => entry.hasFineAddress);
    return AvesExpansionTile(
      title: 'General',
      children: [
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Time dilation'),
        ),
        Slider(
          value: timeDilation,
          onChanged: (v) => setState(() => timeDilation = v),
          min: 1.0,
          max: 10.0,
          divisions: 9,
          label: '$timeDilation',
        ),
        SwitchListTile(
          value: _taskQueueOverlayEntry != null,
          onChanged: (v) {
            _taskQueueOverlayEntry?.remove();
            if (v) {
              _taskQueueOverlayEntry = OverlayEntry(
                builder: (context) => const DebugTaskQueueOverlay(),
              );
              Overlay.of(context)!.insert(_taskQueueOverlayEntry!);
            } else {
              _taskQueueOverlayEntry = null;
            }
            setState(() {});
          },
          title: const Text('Show tasks overlay'),
        ),
        ElevatedButton(
          onPressed: () async {
            final source = context.read<CollectionSource>();
            await source.init();
            await source.refresh();
          },
          child: const Text('Source full refresh'),
        ),
        ElevatedButton(
          onPressed: () => AnalysisService.startService(force: false),
          child: const Text('Start analysis service'),
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 8, bottom: 8),
          child: InfoRowGroup(
            info: {
              'All entries': '${source.allEntries.length}',
              'Visible entries': '${visibleEntries.length}',
              'Catalogued': '${catalogued.length}',
              'With GPS': '${withGps.length}',
              'With address': '${withAddress.length}',
              'With fine address': '${withFineAddress.length}',
            },
          ),
        ),
      ],
    );
  }
}
