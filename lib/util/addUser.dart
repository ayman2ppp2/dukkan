import 'package:dukkan/util/models/Owner.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/list.dart';

class AddUser extends StatelessWidget {
  AddUser({super.key});
  final TextEditingController Person = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
        top: 100,
        bottom: 450,
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('إضافة مالك'),
            TextFormField(
              controller: Person,
              textDirection: TextDirection.rtl,
              decoration: const InputDecoration(
                  constraints: BoxConstraints(maxWidth: 250)),
            ),
            Consumer<Lists>(
              builder: (context, li, child) => IconButton(
                onPressed: () {
                  li.addOwner(
                    Owner(
                      ownerName: Person.text,
                      lastPaymentDate: DateTime.now(),
                      lastPayment: 0,
                      totalPayed: 0,
                      dueMoney: 0,
                    ),
                  );
                  li.refreshListOfOwners();
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.person_add,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
