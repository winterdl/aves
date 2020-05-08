import 'package:aves/model/image_entry.dart';
import 'package:aves/model/settings.dart';
import 'package:aves/services/image_file_service.dart';
import 'package:aves/services/viewer_service.dart';
import 'package:aves/utils/android_file_utils.dart';
import 'package:aves/widgets/album/collection_page.dart';
import 'package:aves/widgets/common/data_providers/media_store_collection_provider.dart';
import 'package:aves/widgets/fullscreen/fullscreen_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:outline_material_icons/outline_material_icons.dart';
import 'package:pedantic/pedantic.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screen/screen.dart';

void main() {
//  HttpClient.enableTimelineLogging = true; // enable network traffic logging
//  debugPrintGestureArenaDiagnostics = true;
  runApp(AvesApp());
}

class AvesApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aves',
      theme: ThemeData(
        brightness: Brightness.dark,
        accentColor: Colors.indigoAccent,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(
          textTheme: TextTheme(
            headline6: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Concourse Caps',
            ),
          ),
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage();

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  MediaStoreSource _mediaStore;
  ImageEntry _sharedEntry;
  Future<void> _appSetup;

  @override
  void initState() {
    debugPrint('$runtimeType initState');
    super.initState();
    _appSetup = _setup();
    imageCache.maximumSizeBytes = 512 * (1 << 20);
    Screen.keepOn(true);
  }

  Future<void> _setup() async {
    debugPrint('$runtimeType _setup');

    // TODO reduce permission check time
    final permissions = await [
      Permission.storage,
      // to access media with unredacted metadata with scoped storage (Android 10+)
      Permission.accessMediaLocation,
    ].request(); // 350ms
    if (permissions[Permission.storage] != PermissionStatus.granted) {
      unawaited(SystemNavigator.pop());
      return;
    }

    // TODO notify when icons are ready for drawer and section header refresh
    await androidFileUtils.init(); // 170ms

    await settings.init(); // <20ms

    final sharedExtra = await ViewerService.getSharedEntry();
    if (sharedExtra != null) {
      _sharedEntry = await ImageFileService.getImageEntry(sharedExtra['uri'], sharedExtra['mimeType']);
      // cataloging is essential for geolocation and video rotation
      await _sharedEntry.catalog();
      unawaited(_sharedEntry.locate());
    } else {
      _mediaStore = MediaStoreSource();
      unawaited(_mediaStore.fetch());
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _appSetup,
        builder: (context, AsyncSnapshot<void> snapshot) {
          if (snapshot.hasError) return const Icon(OMIcons.error);
          if (snapshot.connectionState != ConnectionState.done) return const SizedBox.shrink();
          debugPrint('$runtimeType app setup future complete');
          if (_sharedEntry != null) {
            return SingleFullscreenPage(entry: _sharedEntry);
          }
          if (_mediaStore != null) {
            return CollectionPage(_mediaStore.collection);
          }
          return const SizedBox.shrink();
        });
  }
}
