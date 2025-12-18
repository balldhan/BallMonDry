import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../config.dart';

class User extends StatefulWidget {
  const User({super.key});

  @override
  State<User> createState() => _UserState();
}

class _UserState extends State<User> {
  List users = [];

  Future<void> fetchUsers() async {
    final response = await http.get(Uri.parse('${Config.baseUrl}/users'));
    if (response.statusCode == 200) setState(() => users = jsonDecode(response.body));
  }

  @override
  void initState() { super.initState(); fetchUsers(); }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        var user = users[index];
        return ListTile(
          leading: const CircleAvatar(child: Icon(Icons.person)),
          title: Text(user['username']),
          subtitle: Text("${user['no_telepon']}\n${user['alamat']}"),
          isThreeLine: true,
        );
      },
    );
  }
}