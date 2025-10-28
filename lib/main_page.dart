// ignore_for_file: non_constant_identifier_names

import 'package:easy_sidemenu/easy_sidemenu.dart';
import 'package:filesize/filesize.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mirageclient/MirageClient.dart';
import 'package:mirageclient/albums_tab.dart';
import 'package:mirageclient/explore_tab.dart';
import 'package:mirageclient/photos_tab.dart';
import 'package:mirageclient/trash_tab.dart';
import 'package:mirageclient/utils/AnimatedIndexedStack.dart';
import 'package:mirageclient/utilities_tab.dart';
import 'package:package_info_plus/package_info_plus.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String _appVersion = '';
  Map<String, dynamic> _diskUsage = {
    "used": 0,
    "total": 1,
  };
  GlobalKey<PhotosTabState> GK_mts = GlobalKey();
  GlobalKey<TrashTabState> GK_trash = GlobalKey();
  final SideMenuController _sideMenuController = SideMenuController();
  int _index = 0;
  int _selected = 0;

  @override
  void initState() {
    super.initState();
    _getAppVersion();
    _getDiskUsage();
  }

  void _getAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() => _appVersion = packageInfo.version);
  }

  void _getDiskUsage() async {
    final result = await MirageClient.getDiskUsage();
    setState(() => _diskUsage = result);
  }

  bool _isSelectableIndex(int index) => index == 0 || index == 4;

  String _titleForIndex() {
    switch (_index) {
      case 1:
        return 'Explore';
      case 2:
        return 'Albums';
      case 3:
        return 'Utilities';
      case 4:
        return 'Trash';
      case 0:
      default:
        return 'Mirage';
    }
  }

  void _clearSelection() {
    if (_index == 0) {
      GK_mts.currentState?.deselectAll();
    } else if (_index == 4) {
      GK_trash.currentState?.deselectAll();
    }
    setState(() => _selected = 0);
  }

  Icon _selectionActionIcon() {
    switch (_index) {
      case 0:
        return const Icon(Icons.delete_rounded);
      case 4:
        return const Icon(Icons.restore_from_trash_rounded);
      default:
        return const Icon(Icons.error_outline_rounded);
    }
  }

  void _handleNavTap(int index) {
    if (_index == index) return;
    if (_index == 0) {
      GK_mts.currentState?.deselectAll();
    } else if (_index == 4) {
      GK_trash.currentState?.deselectAll();
    }
    _sideMenuController.changePage(index);
    setState(() {
      _index = index;
      if (!_isSelectableIndex(index)) {
        _selected = 0;
      }
    });
  }

  String _getDiskPercentageUsed(double used, double total) {
    double result = _diskUsage['used'] / _diskUsage['total'];
    if (result < 0.2) {
      return (result * 100).toStringAsFixed(2);
    } else {
      return (result * 100).toStringAsFixed(0);
    }
  }

  Icon _trashIcon() {
    return _selectionActionIcon();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selected != 0 && _isSelectableIndex(_index)
          ? AppBar(
              title: Text('$_selected selected'),
              elevation: 10,
              leading: IconButton(
                onPressed: _clearSelection,
                icon: const Icon(Icons.clear_rounded),
              ),
              actions: [
                IconButton(
                  onPressed: () async {
                    switch (_index) {
                      case 0:
                        await GK_mts.currentState?.trash();
                        GK_trash.currentState?.getTrash();
                        break;
                      case 4:
                        await GK_trash.currentState?.removeTrash();
                        GK_mts.currentState?.getPhotos();
                        break;
                    }
                  },
                  icon: _trashIcon(),
                )
              ],
            )
          : AppBar(
              title: Text(_titleForIndex()),
              leading: null,
            ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            SizedBox(
              width: 256,
              child: SideMenu(
                controller: _sideMenuController,
                alwaysShowFooter: true,
                style: SideMenuStyle(
                  itemOuterPadding:
                      const EdgeInsets.only(top: 8, left: 8, right: 8),
                  displayMode: SideMenuDisplayMode.open,
                  selectedColor: Theme.of(context).primaryColor,
                  itemBorderRadius: BorderRadius.circular(20),
                  selectedIconColor: Theme.of(context).colorScheme.surface,
                  // selectedTitleTextStyle: TextStyle(
                  //   color: Theme.of(context).colorScheme.surface,
                  // ),
                ),
                items: [
                  SideMenuItem(
                    icon: const Icon(Icons.photo_library_outlined),
                    title: 'Photos',
                    onTap: (index, _) => _handleNavTap(index),
                  ),
                  SideMenuItem(
                    icon: const Icon(Icons.explore_outlined),
                    title: 'Explore',
                    onTap: (index, _) => _handleNavTap(index),
                  ),
                  SideMenuItem(
                    icon: const Icon(Icons.photo_album_outlined),
                    title: 'Albums',
                    onTap: (index, _) => _handleNavTap(index),
                  ),
                  SideMenuItem(
                    icon: const Icon(Icons.settings_suggest_outlined),
                    title: 'Utilities',
                    onTap: (index, _) => _handleNavTap(index),
                  ),
                  SideMenuItem(
                    icon: const Icon(Icons.delete_rounded),
                    title: 'Trash',
                    onTap: (index, _) => _handleNavTap(index),
                  ),
                ],
                footer: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.all(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Storage',
                              style: GoogleFonts.overpass(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${filesize(_diskUsage['used'])} of ${filesize(_diskUsage['total'])} used (${_getDiskPercentageUsed(_diskUsage['used'], _diskUsage['total'])}%)",
                            ),
                            TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 1000),
                              curve: Curves.easeInOutQuart,
                              tween: Tween<double>(
                                begin: 0,
                                end: _diskUsage['used'] / _diskUsage['total'],
                              ),
                              builder: (context, value, _) =>
                                  LinearProgressIndicator(
                                value: value,
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      _appVersion,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: AnimatedIndexedStack(
                index: _index,
                children: [
                  PhotosTab(
                    key: GK_mts,
                    selected: (value) => setState(() => _selected = value),
                  ),
                  const ExploreTab(),
                  const AlbumsTab(),
                  const UtilitiesTab(),
                  TrashTab(
                    key: GK_trash,
                    selected: (value) => setState(() => _selected = value),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
