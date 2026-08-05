import 'package:dukkan/core/observability.dart';
import 'package:dukkan/providers/auth_provider.dart';
import 'package:dukkan/providers/log_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class drawerItems extends StatelessWidget {
  const drawerItems({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          decoration: BoxDecoration(
            color: Colors.brown,
          ),
          child: Text(
            'Dukkan',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
            ),
          ),
        ),
        // 0116219798
        ListTile(
          leading: Icon(Icons.receipt_long_rounded),
          title: Text(
            'الديون',
            style: TextStyle(fontSize: 15),
          ),
          onTap: () => context.push('/loans'),
        ),
        ListTile(
          leading: Icon(Icons.manage_accounts_rounded),
          title: Text(
            'المنصرفات',
            style: TextStyle(fontSize: 15),
          ),
          onTap: () => context.push('/expenses'),
        ),
        ListTile(
          leading: Icon(Icons.manage_accounts_rounded),
          title: Text(
            'فاتورة داخل',
            style: TextStyle(fontSize: 15),
          ),
          onTap: () => context.push('/inbound'),
        ),
        ListTile(
          onTap: () => context.push('/inventory/low-stock'),
          leading: Icon(Icons.warning_amber_rounded),
          title: Text('عناصر منخفضة المخزون'),
          enabled: true,
        ),
        ListTile(
          onTap: () async {
            var li = Provider.of<AuthAPI>(context, listen: false);
            try {
              await li.uploadBackup();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم رفع نسخة احتياطية')),
              );
            } catch (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(UserSafeMessages.backupFailed)),
              );
            }
            // Navigator.pop(context);
          },
          leading: Icon(Icons.upload_rounded),
          title: Text('رفع نسخة احتياطية'),
          enabled: true,
        ),
        ListTile(
          onTap: () async {
            var li = Provider.of<AuthAPI>(context, listen: false);
            try {
              await li.downloadBackup();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم تنزيل النسخة الاحتياطية')),
              );
            } catch (_) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(UserSafeMessages.backupFailed)),
              );
            }
            // Navigator.pop(context);
          },
          leading: Icon(Icons.download_rounded),
          title: Text('تنزيل النسخة الإحتياطية'),
          enabled: true,
        ),
        ListTile(
          onTap: () async {
            try {
              await context.read<LogProvider>().db.useLocalBacup();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('تم استخدام النسخة الاحتياطية المحلية')),
              );
            } catch (e, st) {
              await AppLogger.captureException(e,
                  stackTrace: st, area: 'backup.restore.local');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text(UserSafeMessages.restoreFailed)),
              );
            }
          },
          leading: Icon(Icons.restart_alt_rounded),
          title: Text('إستخدام نسخة احتياطية محلية'),
          enabled: true,
        ),
        ListTile(
          onTap: () => context.push('/settings'),
          leading: Icon(Icons.settings),
          title: Text('الإعدادات'),
          enabled: true,
        ),
        ListTile(
          onTap: () async {
            var li = Provider.of<AuthAPI>(context, listen: false);
            li.signOut();
            // li.db.importData().then((value) {
            //   ScaffoldMessenger.of(context)
            //       .showSnackBar(SnackBar(content: Text('import done')));
            // });
          },
          leading: Icon(Icons.logout_rounded),
          title: Text('تسجيل الخروج'),
          enabled: true,
        ),
      ],
    );
  }
}
