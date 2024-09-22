import 'dart:io';
import 'package:blog_app/screens/add_post_screen.dart';
import 'package:blog_app/screens/log_in_screen.dart';
import 'package:blog_app/screens/my_profile_screen.dart';
import 'package:blog_app/screens/post_detail_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController searchController = TextEditingController();
  final dbRef = FirebaseFirestore.instance.collection("Posts");
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String searchText = "";
  User? _user;
  String? _userName;
  File? _image;
  final picker = ImagePicker();
  bool _isUploading = false; // To track upload progress

  Future<void> _deletePost(String docId) async {
    try {
      await dbRef.doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post deleted successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete post')));
    }
  }

  Future<void> _editPost(BuildContext context, String docId, String currentTitle, String currentDescription) async {
    TextEditingController titleController = TextEditingController(text: currentTitle);
    TextEditingController descriptionController = TextEditingController(text: currentDescription);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Post'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(labelText: 'Description'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await dbRef.doc(docId).update({
                    'PostTitle': titleController.text,
                    'PostDescription': descriptionController.text,
                  });
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post updated successfully')));
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update post')));
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser;
    if (_user != null) {
      fetchUserName();
    }
  }

  Future<void> fetchUserName() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('my_data').doc(_user!.uid).get();
      setState(() {
        _userName = userDoc['name']; // Assuming 'name' is the field in Firestore
      });
    } catch (e) {
      print("Error fetching user name: $e");
    }
  }

  Future getGalleryImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        uploadImage();
      } else {
        print("No Image Selected");
      }
    });
  }

  Future getCameraImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        uploadImage();
      } else {
        print("No Image Selected");
      }
    });
  }

  Future uploadImage() async {
    setState(() {
      _isUploading = true; // Start uploading
    });
    try {
      if (_image == null) return;

      int date = DateTime.now().microsecondsSinceEpoch;
      firebase_storage.Reference ref = firebase_storage.FirebaseStorage.instance
          .ref("/profile_pictures/${_user?.uid}/$date");

      UploadTask uploadTask = ref.putFile(_image!);
      TaskSnapshot taskSnapshot = await uploadTask;
      String newUrl = await taskSnapshot.ref.getDownloadURL();

      // Update user photo URL in Firebase Auth
      await _user?.updatePhotoURL(newUrl);

      // Update in Firestore (ProfilePictures collection)
      await FirebaseFirestore.instance
          .collection('ProfilePictures')
          .doc(_user?.uid)
          .set({'photoURL': newUrl, 'updatedAt': FieldValue.serverTimestamp()});

      // Re-fetch the current user to reflect the changes
      _user = _auth.currentUser;
      await _user?.reload(); // Ensure the latest user data is fetched

      // Trigger UI rebuild to reflect new profile picture
      setState(() {
        toastMessage("Profile picture updated successfully.");
      });
    } catch (e) {
      toastMessage("Error updating profile picture: $e");
    } finally {
      setState(() {
        _isUploading = false; // Stop uploading
      });
    }
  }

  void dialog(context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
          content: Container(
            height: 120,
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    getCameraImage();
                    Navigator.pop(context);
                  },
                  child: ListTile(
                    leading: Icon(Icons.camera),
                    title: Text('Camera'),
                  ),
                ),
                InkWell(
                  onTap: () {
                    getGalleryImage();
                    Navigator.pop(context);
                  },
                  child: ListTile(
                    leading: Icon(Icons.photo_library),
                    title: Text('Gallery'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "My Blogs",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          automaticallyImplyLeading: false,
          centerTitle: true,
          actions: [
            InkWell(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AddPostScreen()));
              },
              child: Icon(Icons.add, color: Colors.black),
            ),
            SizedBox(width: 20),
          ],
          leading: Builder(
            builder: (BuildContext context) => IconButton(
              icon: Icon(Icons.menu, color: Colors.black),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Profile Picture Section
              Container(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: CachedNetworkImageProvider(_user?.photoURL ?? 'https://www.example.com/default_profile_pic.png'),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _userName ?? 'User Name', // Update to display fetched user name
                      style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _user?.email ?? 'user@example.com',
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    InkWell(
                      onTap: () {
                        dialog(context);
                      },
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.camera_alt, size: 24, color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
              // Drawer Options
              ListTile(
                leading: Icon(Icons.person,color: Colors.black,),
                title: Text(
                  'My Profile',
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => MyProfileScreen(user: _user!)));
                },
              ),
              ListTile(
                leading: Icon(Icons.logout,color: Colors.black,),
                title: Text(
                  'Logout',
                  style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                onTap: () async {
                  await FirebaseAuth.instance.signOut();
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LogInScreen()));
                },
              ),
            ],
          ),
        ),
        backgroundColor: Colors.green.shade50,
        body:Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: TextFormField(
                controller: searchController,
                decoration: InputDecoration(
                  labelText: "Search Posts",
                  hintText: "Search posts by title",
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.black),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value.toLowerCase();
                  });
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: dbRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator(color: Colors.white));
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.white)));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(child: Text('No posts available.', style: TextStyle(color: Colors.black,fontSize: 20)));
                  }
                  var filteredPosts = snapshot.data!.docs.where((post) {
                    var postTitle = post['PostTitle']?.toLowerCase() ?? '';
                    return postTitle.contains(searchText);
                  }).toList();

                  return ListView.builder(
                    itemCount: filteredPosts.length,
                    itemBuilder: (context, index) {
                      var post = filteredPosts[index];
                      String docId = post.id;

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostDetailScreen(
                                imageUrl: post['PostImage'] ?? '',
                                title: post['PostTitle'] ?? 'No Title',
                                description: post['PostDescription'] ?? 'No Description',
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 5, spreadRadius: 1)],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  post['PostImage'] != null
                                      ? ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: CachedNetworkImage(
                                      imageUrl: post['PostImage'],
                                      height: 200,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => Center(child: CircularProgressIndicator()),
                                      errorWidget: (context, url, error) => SizedBox(height: 200, child: Icon(Icons.image, color: Colors.grey)),
                                    ),
                                  )
                                      : SizedBox(height: 200, child: Icon(Icons.image, color: Colors.grey)),
                                  SizedBox(height: 10),
                                  // Title with underline
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    child: Text(
                                      post['PostTitle'] ?? 'No Title',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 20,
                                        color: Colors.black,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  // Description with rounded rectangle border
                                  Container(
                                    padding: EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      post['PostDescription'] ?? 'No Description',
                                      style: TextStyle(fontSize: 16, color: Colors.black),
                                    ),
                                  ),
                                  // Action buttons for editing and deleting
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Edit Button
                                      IconButton(
                                        icon: Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () {
                                          _editPost(context, docId, post['PostTitle'], post['PostDescription']);
                                        },
                                      ),
                                      // Delete Button
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          _deletePost(docId);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _isUploading
            ? CircularProgressIndicator() // Show loader during upload
            : null,
      ),
    );
  }

  void toastMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.grey,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }
}
