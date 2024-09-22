import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class PostDetailScreen extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String description;

  const PostDetailScreen({
    Key? key,
    required this.imageUrl,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Post Details',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),),
        centerTitle: true,
      ),
      backgroundColor: Colors.green.shade50,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 50,),
            CachedNetworkImage(
              imageUrl: imageUrl,
              height: 300,
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) => Icon(Icons.error),
            ),
            SizedBox(height: 16),
            // Title
            Text(
              "Title: $title",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              "Description: $description",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}