import 'dart:async';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
// import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';

import 'package:image_picker/image_picker.dart';

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({Key? key, required this.image}) : super(key: key);
  final image;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  final dylib = Platform.isAndroid
      ? DynamicLibrary.open("libOpenCV_ffi.so")
      : DynamicLibrary.process();

  // static get image => image;

  // Image _old = Image.asset('assets/img/default.jpg');

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var image = widget.image;
    print(image);
    Image img = image;
    return Scaffold(
      appBar: AppBar(title: Text('Start Camera')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        builder: (context, snapshot) {
          // if (snapshot.connectionState == ConnectionState.done) {
          //   // If the Future is complete, display the preview.
          //   return Center(child: img);
          //   //CameraPreview(_controller);
          // } else {
          //   // Otherwise, display a loading indicator.
          //   return const Center(child: CircularProgressIndicator());
          // }
          return Center(child: img);
        },
      ),
    );
  }
}
