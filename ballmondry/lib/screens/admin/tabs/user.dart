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
    return RefreshIndicator(
      onRefresh: fetchUsers,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 10),
        itemCount: users.length,
        itemBuilder: (context, index) {
        var user = users[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            leading: CircleAvatar(
              radius: 25,
              backgroundColor: Colors.deepPurple.shade100,
              child: const Icon(Icons.person, color: Colors.deepPurple, size: 28),
            ),
            title: Text(
              user['username'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Text(
              "${user['no_hp']}\n${user['alamat']}",
              style: const TextStyle(fontSize: 13, height: 1.5),
            ),
            isThreeLine: true,
          ),
        );
      },
      ),
    );
  }
}