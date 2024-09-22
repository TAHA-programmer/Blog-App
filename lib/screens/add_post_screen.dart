import 'dart:io';
import 'package:blog_app/components/round_button.dart';
import 'package:blog_app/screens/home_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  FirebaseAuth _auth = FirebaseAuth.instance;
  final firestoreRef = FirebaseFirestore.instance.collection("Posts");
  firebase_storage.FirebaseStorage storage = firebase_storage.FirebaseStorage.instance;
  bool showSpinner = false;
  File? _image;
  final picker = ImagePicker();
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future getGalleryImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        print("${pickedFile.path}");
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
        print("${pickedFile.path}");
      } else {
        print("No Image Selected");
      }
    });
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
      child: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Scaffold(
          backgroundColor: Colors.green.shade50,
          appBar: AppBar(
            title: Text(
              "Upload Blogs",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      dialog(context);
                    },
                    child: Center(
                      child: Container(
                        height: MediaQuery.of(context).size.height * .2,
                        width: MediaQuery.of(context).size.width * 1,
                        child: _image != null
                            ? ClipRect(
                          child: Image.file(
                            _image!.absolute,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        )
                            : Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          keyboardType: TextInputType.text,
                          controller: titleController,
                          decoration: InputDecoration(
                            labelText: "Title",
                            hintText: "Enter the title of post",
                            border: OutlineInputBorder(),
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.normal,
                            ),
                            labelStyle: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          minLines: 1,
                          maxLines: 5,
                          keyboardType: TextInputType.text,
                          controller: descriptionController,
                          decoration: InputDecoration(
                            labelText: "Description",
                            hintText: "Enter the description of post",
                            border: OutlineInputBorder(),
                            hintStyle: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.normal,
                            ),
                            labelStyle: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        RoundButton(
                          title: "Upload",
                          onPress: () async {
                            if (_formKey.currentState?.validate() ?? false) {
                              // Check if an image is selected
                              if (_image == null) {
                                toastMessage("Please select an image");
                                return;
                              }

                              setState(() {
                                showSpinner = true;
                              });

                              try {
                                int date = DateTime.now().microsecondsSinceEpoch;

                                // Upload the image to Firebase Storage
                                firebase_storage.Reference ref =
                                firebase_storage.FirebaseStorage.instance
                                    .ref("/blog-app$date");

                                UploadTask uploadTask = ref.putFile(_image!.absolute);
                                TaskSnapshot taskSnapshot = await uploadTask;
                                String newUrl = await taskSnapshot.ref.getDownloadURL();

                                // Get the current user details
                                final User? user = _auth.currentUser;

                                // Save the post data in Firestore
                                await firestoreRef.add({
                                  "PostId": date.toString(),
                                  "PostImage": newUrl.toString(),
                                  "PostTime": date.toString(),
                                  "PostTitle": titleController.text.toString(),
                                  "PostDescription": descriptionController.text.toString(),
                                  "UserEmail": user!.email.toString(),
                                  "UserID": user.uid.toString(),
                                });

                                toastMessage("Post Published");
                                Navigator.pushReplacement(context,
                                    MaterialPageRoute(builder: (context) => HomeScreen(),));
                                setState(() {
                                  showSpinner = false;
                                });

                              } catch (e) {
                                setState(() {
                                  showSpinner = false;
                                });
                                toastMessage(e.toString());
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void toastMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.white,
      textColor: Colors.black,
      fontSize: 16.0,
    );
  }
}
