import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyProfileScreen extends StatefulWidget {
  final User? user;

  MyProfileScreen({required this.user});

  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  String? _userName;
  String? _phoneNumber;
  bool _isLoading = true; // To track loading state

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('my_data')
          .doc(widget.user?.uid)
          .get();
      setState(() {
        _userName = userDoc['name'];
        _phoneNumber = userDoc['phone'];
        _isLoading = false; // Set loading to false after fetching data
      });
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        _isLoading = false; // Stop loading on error
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isLoading
            ? Center(child: CircularProgressIndicator()) // Show loader while loading
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 70,
              backgroundImage: CachedNetworkImageProvider(
                widget.user?.photoURL ?? 'https://www.example.com/default_profile_pic.png',
              ),
            ),
            SizedBox(height: 90),
            buildInfoCard(Icons.person, 'Name: ${_userName ?? 'Not Available'}'),
            buildInfoCard(Icons.email, 'Email: ${widget.user?.email ?? 'Not Available'}'),
            buildInfoCard(Icons.phone, 'Phone: ${_phoneNumber ?? 'Not Available'}'),
          ],
        ),
      ),
    );
  }

  Widget buildInfoCard(IconData icon, String text) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 10),
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black),
      ),
      child: Row(
        children: [
          Icon(icon, size: 30),
          SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 18))),
        ],
      ),
    );
  }
}
