import 'package:dukkan/providers/list.dart';
import 'package:dukkan/providers/salesProvider.dart';
import 'package:dukkan/util/models/Log.dart';
import 'package:dukkan/util/receipt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

class Logs extends StatefulWidget {
  Logs({super.key});

  @override
  State<Logs> createState() => _LogsState();
}

class _LogsState extends State<Logs> {
  final ScrollController _scrollController = ScrollController();
  int _chunkSize = 50; // Initial chunk size
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();

    // Listen to scroll events to load more logs when reaching the bottom
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
              _scrollController.position.maxScrollExtent &&
          !_isLoadingMore) {
        _loadMoreData();
      }
    });
  }

  // Method to increase the chunk size and trigger a new stream
  void _loadMoreData() {
    setState(() {
      _isLoadingMore = true;
      _chunkSize += 50; // Increase the chunk size by 50 logs
    });

    setState(() {
      _isLoadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.brown[50]),
        backgroundColor: Colors.brown,
        title: Text(
          'الفواتير',
          style: TextStyle(color: Colors.brown[50]),
        ),
      ),
      body: Consumer<SalesProvider>(builder: (context, sa, child) {
        return Consumer<Lists>(builder: (context, li, child) {
          return StreamBuilder<List<Log>>(
            stream: li.getLogsStream(
                chunkSize: _chunkSize), // Pass chunk size to the stream
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  snapshot.data == null) {
                return Center(
                  child: SpinKitChasingDots(
                    color: Colors.brown,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                return ListView.builder(
                  controller:
                      _scrollController, // Attach the scroll controller to detect end
                  itemCount: snapshot.data!.length +
                      1, // Add 1 for loading indicator at bottom
                  itemBuilder: (context, index) {
                    if (index == snapshot.data!.length) {
                      // Show a loading indicator at the bottom when fetching more data
                      return _isLoadingMore
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          : SizedBox.shrink();
                    }

                    // Build each log item
                    return Receipt(log: snapshot.data![index]);
                  },
                );
              }

              return Center(
                child: SpinKitChasingDots(
                  color: Colors.brown,
                ),
              );
            },
          );
        });
      }),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
