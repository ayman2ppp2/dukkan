import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:dukkan/providers/list.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/models/Loaner.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/models/searchQuery.dart';
import 'package:dukkan/util/receipt.dart';

class Logs extends StatefulWidget {
  Logs({super.key});

  @override
  State<Logs> createState() => _LogsState();
}

class _LogsState extends State<Logs> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController productSearch = TextEditingController();
  int _chunkSize = 50;
  bool _isLoadingMore = false;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedLoaner;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoadingMore) {
        _loadMoreData();
      }
    });
  }

  void _loadMoreData() {
    setState(() {
      _isLoadingMore = true;
      _chunkSize += 50;
    });

    Future.delayed(Duration(milliseconds: 500), () {
      setState(() {
        _isLoadingMore = false;
      });
    });
  }

  void _selectDate(BuildContext context, bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStart ? _startDate ?? DateTime.now() : _endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var sa = Provider.of<SalesProvider>(context, listen: false);
    var li = Provider.of<Lists>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.brown[50]),
        backgroundColor: Colors.brown,
        title: Text(
          'الفواتير',
          style: TextStyle(color: Colors.brown[50]),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: productSearch,
                  decoration: InputDecoration(
                    labelText: 'بحث عام',
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _endDate != null
                                ? DateFormat('yyyy-MM-dd').format(_endDate!)
                                : 'تاريخ النهاية',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _selectDate(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _startDate != null
                                ? DateFormat('yyyy-MM-dd').format(_startDate!)
                                : 'تاريخ البداية',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                FutureBuilder<List<Loaner>>(
                  future: sa.refreshLoanersList(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }
                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                      return DropdownButtonFormField<String>(
                        value: _selectedLoaner,
                        items: snapshot.data!
                            .map((loaner) => DropdownMenuItem(
                                  value: loaner.ID.toString(),
                                  child: Text(loaner.name!),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedLoaner = value;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'اختر المقترض',
                          border: OutlineInputBorder(),
                        ),
                      );
                    }
                    return Center(child: Text('لا يوجد مقترضين'));
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    setState(() {});
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.brown,
                  ),
                  child: const Text(
                    'بحث',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: StreamBuilder<List<Log>>(
                stream: li.getLogsStream(
                  chunkSize: _chunkSize,
                  searchQuery: SearchQuery(
                    queryText: productSearch.text,
                    startDate: _startDate ?? DateTime(2000),
                    endDate: _endDate ?? DateTime.now(),
                    userId: _selectedLoaner,
                  ),
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      snapshot.data == null) {
                    return Center(
                        child: SpinKitChasingDots(color: Colors.brown));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  if (snapshot.hasData && snapshot.data!.isEmpty) {
                    return Center(child: Text('لا يوجد بيانات  لعرضها'));
                  }
                  if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                    return ListView.builder(
                      controller: _scrollController,
                      itemCount: snapshot.data!.length + 1,
                      itemBuilder: (context, index) {
                        if (index == snapshot.data!.length) {
                          return _isLoadingMore
                              ? Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                )
                              : SizedBox.shrink();
                        }
                        return Receipt(log: snapshot.data![index]);
                      },
                    );
                  }
                  return Center(child: SpinKitChasingDots(color: Colors.brown));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    productSearch.dispose();
    super.dispose();
  }
}
