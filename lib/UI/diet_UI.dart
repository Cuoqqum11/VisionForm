import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class DietPage extends StatefulWidget {
  const DietPage({super.key});

  @override
  State<DietPage> createState() => _DietPageState();
}

class _DietPageState extends State<DietPage> {
  File? _image;

  final _picker = ImagePicker();

  pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      _image = File(pickedFile.path);
      setState(() {
        // _image = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Diet Page')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: TextField(
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter an ingredient',
                suffixIcon: IconButton(
                  icon: Icon(Icons.camera_alt),
                  onPressed: () {
                    pickImage();
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Center(
              child: _image == null
                  ? Container(
                      width: 300,
                      height: 500,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image, size: 60, color: Colors.grey),
                          SizedBox(height: 10),
                          Text(
                            'Image preview here',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _image!,
                        width: 300,
                        height: 500,
                        fit: BoxFit.cover,
                      ),
                    ),
            ),
          ),
        ],
      ),
      // This is the floating action button for taking picture
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Add your onPressed code here!
      //   },
      //   child: const Icon(Icons.camera_alt),
      // ),
    );
  }
}

// ALL OF THIS CODE IS DUMMY CODE, JUST TO SHOW THE STRUCTURE OF THE APP. NOT FINAL.
