import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

class ServerProfile {
  final String name;
  final String idServer;
  final String relayServer;
  final String apiServer;
  final String key;

  ServerProfile({
    required this.name,
    required this.idServer,
    this.relayServer = '',
    this.apiServer = '',
    this.key = '',
  });

  factory ServerProfile.fromJson(Map<String, dynamic> j) => ServerProfile(
        name: (j['name'] ?? j['id_server'] ?? '').toString(),
        idServer: (j['id_server'] ?? '').toString(),
        relayServer: (j['relay_server'] ?? '').toString(),
        apiServer: (j['api_server'] ?? '').toString(),
        key: (j['key'] ?? '').toString(),
      );
}

/// فایل servers.json کنار rustdesk.exe خوانده می‌شود
Future<List<ServerProfile>> loadServerProfiles() async {
  try {
    final dir = File(Platform.resolvedExecutable).parent.path;
    final file = File('$dir${Platform.pathSeparator}servers.json');
    if (!await file.exists()) return [];
    var text = await file.readAsString();
    if (text.startsWith('\uFEFF')) text = text.substring(1); // حذف BOM
    final data = jsonDecode(text);
    final list = (data is Map ? data['servers'] : data) as List? ?? [];
    return list
        .whereType<Map>()
        .map((e) => ServerProfile.fromJson(Map<String, dynamic>.from(e)))
        .where((p) => p.idServer.isNotEmpty)
        .toList();
  } catch (e) {
    debugPrint('loadServerProfiles failed: $e');
    return [];
  }
}

/// کامبوباکس انتخاب پروفایل؛ با انتخاب، چهار کنترلر پر می‌شوند
class ServerProfilePicker extends StatefulWidget {
  final TextEditingController idCtrl;
  final TextEditingController relayCtrl;
  final TextEditingController apiCtrl;
  final TextEditingController keyCtrl;
  final double labelMinWidth;

  const ServerProfilePicker({
    Key? key,
    required this.idCtrl,
    required this.relayCtrl,
    required this.apiCtrl,
    required this.keyCtrl,
    this.labelMinWidth = 120,
  }) : super(key: key);

  @override
  State<ServerProfilePicker> createState() => _ServerProfilePickerState();
}

class _ServerProfilePickerState extends State<ServerProfilePicker> {
  List<ServerProfile> _profiles = [];
  ServerProfile? _selected;

  @override
  void initState() {
    super.initState();
    loadServerProfiles().then((v) {
      if (!mounted) return;
      setState(() {
        _profiles = v;
        for (final p in v) {
          if (p.idServer == widget.idCtrl.text.trim()) {
            _selected = p;
            break;
          }
        }
      });
    });
  }

  void _select(ServerProfile p) {
    setState(() => _selected = p);
    widget.idCtrl.text = p.idServer;
    widget.relayCtrl.text = p.relayServer;
    widget.apiCtrl.text = p.apiServer;
    widget.keyCtrl.text = p.key;
  }

  @override
  Widget build(BuildContext context) {
    // اگر فایل نبود یا خالی بود، چیزی نمایش داده نمی‌شود
    if (_profiles.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: widget.labelMinWidth,
            child: const Text('Server profile'),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final w = constraints.maxWidth;
                return MenuAnchor(
                  style: MenuStyle(
                    minimumSize: WidgetStatePropertyAll(Size(w, 0)),
                    maximumSize: WidgetStatePropertyAll(Size(w, 300)),
                  ),
                  menuChildren: _profiles
                      .map((p) => MenuItemButton(
                            onPressed: () => _select(p),
                            child: Text(p.name,
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  builder: (context, controller, child) {
                    return InkWell(
                      onTap: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          isDense: true,
                          border: OutlineInputBorder(),
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selected?.name ?? '-',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.arrow_drop_down),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    // اگر فایل نبود یا خالی بود، چیزی نمایش داده نمی‌شود
    if (_profiles.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: widget.labelMinWidth),
            child: const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Text('Server profile'),
            ),
          ),
          Expanded(
            child: DropdownButtonFormField<ServerProfile>(
              isExpanded: true,
              value: _selected,
              hint: const Text('-'),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
              items: _profiles
                  .map((p) => DropdownMenuItem<ServerProfile>(
                        value: p,
                        child: Text(p.name, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (p) {
                if (p == null) return;
                setState(() => _selected = p);
                widget.idCtrl.text = p.idServer;
                widget.relayCtrl.text = p.relayServer;
                widget.apiCtrl.text = p.apiServer;
                widget.keyCtrl.text = p.key;
              },
            ),
          ),
        ],
      ),
    );
  }
}
