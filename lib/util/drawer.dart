import 'package:dukkan/pages/loans.dart';
import 'package:dukkan/pages/settingsPage.dart';
import 'package:dukkan/pages/spendings.dart';
import 'package:dukkan/providers/expenseProvider.dart';
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/providers/onlineProvider.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/inboundReceipt.dart';
import 'package:flutter/material.dart';
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
          onTap: () {
            var li = Provider.of<Lists>(context, listen: false);
            var as = Provider.of<SalesProvider>(context, listen: false);
            var exp = Provider.of<ExpenseProvider>(context, listen: false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider.value(
                  value: exp,
                  child: ChangeNotifierProvider.value(
                    value: li,
                    child: ChangeNotifierProvider.value(
                      value: as,
                      child: Loans(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        ListTile(
          leading: Icon(Icons.manage_accounts_rounded),
          title: Text(
            'المنصرفات',
            style: TextStyle(fontSize: 15),
          ),
          onTap: () {
            var li = Provider.of<Lists>(context, listen: false);
            var exp = Provider.of<ExpenseProvider>(context, listen: false);
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: li,
                    child: ChangeNotifierProvider.value(
                      value: exp,
                      child: Spendings(),
                    ),
                  ),
                ));
          },
        ),
        ListTile(
          leading: Icon(Icons.manage_accounts_rounded),
          title: Text(
            'فاتورة داخل',
            style: TextStyle(fontSize: 15),
          ),
          onTap: () {
            var li = Provider.of<Lists>(context, listen: false);
            var exp = Provider.of<ExpenseProvider>(context, listen: false);
            var as = Provider.of<SalesProvider>(context, listen: false);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChangeNotifierProvider.value(
                  value: exp,
                  child: ChangeNotifierProvider.value(
                    value: as,
                    child: ChangeNotifierProvider.value(
                      value: li,
                      child: inboundReceipt(),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        ListTile(
          onTap: () async {
            var li = Provider.of<AuthAPI>(context, listen: false);
            await li.uploadBackup().then(
                  (value) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم رفع نسخة احتياطية'),
                    ),
                  ),
                );
            // Navigator.pop(context);
          },
          leading: Icon(Icons.upload_rounded),
          title: Text('رفع نسخة احتياطية'),
          enabled: true,
        ),
        ListTile(
          onTap: () async {
            var li = Provider.of<AuthAPI>(context, listen: false);
            await li.downloadBackup().then(
                  (value) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم تنزيل النسخة الاحتياطية'),
                    ),
                  ),
                );
            // Navigator.pop(context);
          },
          leading: Icon(Icons.download_rounded),
          title: Text('تنزيل النسخة الإحتياطية'),
          enabled: true,
        ),
        ListTile(
          onTap: () async {
            var li = Provider.of<Lists>(context, listen: false);
            await li.db.useLocalBacup().then(
                  (value) => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('تم استخدام النسخة الاحتياطيةالمحلية'),
                    ),
                  ),
                );
            // var li = Provider.of<Lists>(context, listen: false);
            // await li.db.useBackup().then(
            //       (value) => ScaffoldMessenger.of(context).showSnackBar(
            //         SnackBar(
            //           content: Text('done converting'),
            //         ),
            //       ),
            //     );
            // Navigator.pop(context);
          },
          leading: Icon(Icons.restart_alt_rounded),
          title: Text('إستخدام نسخة احتياطية محلية'),
          enabled: true,
        ),
        ListTile(
          onTap: () async {
            var sa = Provider.of<SalesProvider>(context, listen: false);

            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChangeNotifierProvider.value(
                    value: sa,
                    child: SettingsPage(),
                  ),
                ));
          },
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
