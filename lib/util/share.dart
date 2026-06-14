import 'dart:io';

import 'package:dukkan/core/lan_sync.dart';
import 'package:dukkan/util/scanner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../providers/list.dart';

class Share extends StatefulWidget {
  const Share({super.key});

  @override
  State<Share> createState() => _ShareState();
}

class _ShareState extends State<Share> {
  @override
  Widget build(BuildContext context) {
    return Material(
      borderRadius: BorderRadius.circular(12),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('مشاركة البيانات'),
          backgroundColor: Colors.brown[300],
          elevation: 0,
        ),
        body: Container(
          decoration: BoxDecoration(
            color: Colors.brown[50],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
          ),
          child: Column(
            children: [
              Expanded(
                child: Consumer<Lists>(
                  builder: (context, li, child) => ListView(
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    children: [
                      _statusCard(li),
                      if (li.shareAddress != null) _shareAddressCard(li),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.brown[300],
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        IconButton(
                          tooltip: 'إرسال البيانات',
                          onPressed: () async {
                            Provider.of<Lists>(context, listen: false)
                                .runServer();
                          },
                          icon: const Icon(Icons.send, color: Colors.white),
                        ),
                        const Text(
                          'إرسال',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Consumer<Lists>(
                          builder: (context, li, child) => IconButton(
                            tooltip: 'استقبال البيانات',
                            onPressed: () async {
                              if (Platform.isWindows || Platform.isLinux) {
                                _showManualConnectDialog(context, li);
                                return;
                              }
                              showGeneralDialog(
                                context: context,
                                pageBuilder:
                                    (context, animation, secondaryAnimation) =>
                                        ChangeNotifierProvider.value(
                                  value: li,
                                  child: Scanner2(),
                                ),
                              );
                            },
                            onLongPress: () {
                              _showManualConnectDialog(context, li);
                            },
                            icon: const Icon(Icons.call_received_rounded,
                                color: Colors.white),
                          ),
                        ),
                        const Text(
                          'استقبال',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualConnectDialog(BuildContext context, Lists li) {
    var address = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('اكتب عنوان المشاركة الظاهر على جهاز الإرسال'),
        content: TextField(
          textDirection: TextDirection.ltr,
          decoration: const InputDecoration(
            labelText: 'عنوان المشاركة',
            hintText: '192.168.1.10:30000',
          ),
          onChanged: (value) {
            address = value;
          },
        ),
        actions: [
          TextButton(
            onPressed: () {
              li.client(address);
              Navigator.pop(context);
            },
            child: const Text('اتصال'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Widget _statusCard(Lists li) {
    final isBusy = li.syncStatus == SyncStatus.connecting ||
        li.syncStatus == SyncStatus.downloading ||
        li.syncStatus == SyncStatus.verifying ||
        li.syncStatus == SyncStatus.restoring;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              li.syncStatus.label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(li.syncMessage),
            if (li.syncErrorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                li.syncErrorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ],
            if (isBusy) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: li.syncStatus == SyncStatus.downloading
                    ? li.syncProgress
                    : null,
              ),
            ],
            if (li.canCancelSync) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: li.cancelSync,
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('إلغاء المزامنة'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _shareAddressCard(Lists li) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Semantics(
              label: 'رمز QR لمشاركة البيانات',
              image: true,
              child: QrImageView(data: li.shareAddress!, size: 220),
            ),
            const SizedBox(height: 12),
            SelectableText(
              li.shareAddress!,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
