import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'API Table Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'API Table Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic> _users = [];
  List<dynamic> _payments = [];
  bool _loading = true;
  String _error = '';
  bool _filterFailed = false;
  bool _sortAscending = true;
  int _sortColumnIndex = 0;

  @override
  void initState() {
    super.initState();
    // Fetch data from the APIs when the app starts
    fetchAllData();
  }

  Future<void> fetchAllData() async {
    try {
      final users = await getAllUsers();
      final payments = await getAllPayments();
      setState(() {
        _users = users;
        _payments = payments;
        _loading = false;
      });
    } catch (error) {
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<List<dynamic>> getAllUsers() async {
    final response = await http.get(Uri.parse('https://devapi.pepcorns.com/api/test/getAllUsers'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load users');
    }
  }

  Future<dynamic> getUserById(String userId) async {
    final response = await http.get(Uri.parse('https://devapi.pepcorns.com/api/test/getUserById/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user');
    }
  }

  Future<List<dynamic>> getAllPayments() async {
    final response = await http.get(Uri.parse('https://devapi.pepcorns.com/api/test/getAllPayments'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load payments');
    }
  }

  Future<dynamic> getPayment(String paymentId) async {
    final response = await http.get(Uri.parse('https://devapi.pepcorns.com/api/test/getPayment/$paymentId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load payment');
    }
  }

  void _sortTable(int columnIndex, bool ascending) {
    setState(() {
      _sortColumnIndex = columnIndex;
      _sortAscending = ascending;
      _users.sort((a, b) {
        if (ascending) {
          return a['pay_id'].compareTo(b['pay_id']);
        } else {
          return b['pay_id'].compareTo(a['pay_id']);
        }
      });
    });
  }

  void _toggleFilterFailed() {
    setState(() {
      _filterFailed = !_filterFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? Center(child: Text(_error))
          : Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _toggleFilterFailed,
                child: Row(
                  children: [
                    Checkbox(
                      value: _filterFailed,
                      onChanged: () {
                        _toggleFilterFailed();
                      },
                    ),
                    Text('Filter by failed payments'),
                  ],
                ),
              ),
              TextButton(
                onPressed: fetchAllData,
                child: Text('Refresh'),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              child: DataTable(
                sortColumnIndex: _sortColumnIndex,
                sortAscending: _sortAscending,
                columns: [
                  DataColumn(label: Text('User_id')),
                  DataColumn(label: Text('Name')),
                  DataColumn(
                      label: Text('Pay_id'),
                      onSort: (columnIndex, ascending) {
                        _sortTable(columnIndex, ascending);
                      }),
                  DataColumn(label: Text('Status')),
                ],
                rows: _users
                    .where((user) => !_filterFailed || user['status'] == 0)
                    .map<DataRow>((user) => DataRow(
                  cells: [
                    DataCell(Text(user['user_id'])),
                    DataCell(Text(user['name'])),
                    DataCell(
                      TextButton(
                        onPressed: () async {
                          final payment =
                          await getPayment(user['pay_id']);
                          showDialog(
                            context: context,
                            builder: (context) =>
                                PaymentDialog(payment: payment),
                          );
                        },
                        child: Text(user['pay_id']),
                      ),
                    ),
                    DataCell(
                      Text(user['status'] == 0 ? 'Failed' : 'Active'),
                    ),
                  ],
                ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PaymentDialog extends StatelessWidget {
  final dynamic payment;
  PaymentDialog({required this.payment});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Payment details'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment ID: ${payment['pay_id']}'),
          Text('Amount: ${payment['amount']}'),
          Text('Status: ${payment['status'] == 0 ? 'Failed' : 'Active'}'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Close'),
        ),
      ],
    );
  }
}
