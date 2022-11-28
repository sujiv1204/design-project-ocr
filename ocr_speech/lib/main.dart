import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:tflite/tflite.dart';
import 'package:flutter/services.dart';
// import 'package:simple_edge_detection/edge_detection.dart';
// import 'package:ocr_speech/';
import 'package:ocr_speech/pages/speech_page.dart';
import 'package:ocr_speech/pages/responsive.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      //   home: const MyHomePage(),
      routes: {
        '/': (context) => const MyHomePage(),
        '/speech': (context) => const SpeechPage(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  bool _busy = false;
  FlutterTts ftts = FlutterTts();
  bool textScanning = false;

  XFile? imageFile;

  String scannedText = "";
  late Responsive responsive;

  @override
  Widget build(BuildContext context) {
    responsive = Responsive(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Text Recognition Application"),
      ),
      body: Center(
          child: SingleChildScrollView(
        child: Container(
            margin: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (textScanning) const CircularProgressIndicator(),
                // if (!textScanning && imageFile == null)
                //   Container(
                //     width: 300,
                //     height: 300,
                //     color: Colors.grey[300]!,
                //   ),
                // if (imageFile != null) Image.file(File(imageFile!.path)),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                        height: responsive.BlockHeight * 35,
                        width: responsive.BlockWidth * 75,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        padding: const EdgeInsets.only(top: 10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: Colors.white,
                            onPrimary: Colors.grey,
                            shadowColor: Colors.grey[400],
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                          ),
                          onPressed: () {
                            getImage(ImageSource.camera);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 5, horizontal: 5),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 50,
                                ),
                                Text(
                                  "Camera",
                                  style: TextStyle(
                                      fontSize: 20, color: Colors.grey[600]),
                                )
                              ],
                            ),
                          ),
                        )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                            height: responsive.BlockHeight * 25,
                            width: responsive.BlockWidth * 40,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 15),
                            padding: const EdgeInsets.only(top: 10),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Colors.white,
                                onPrimary: Colors.grey,
                                shadowColor: Colors.grey[400],
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0)),
                              ),
                              onPressed: () {
                                getImage(ImageSource.gallery);
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 5),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.image,
                                      size: 40,
                                    ),
                                    Text(
                                      "Gallery",
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.grey[600]),
                                    )
                                  ],
                                ),
                              ),
                            )),
                        Container(
                            height: responsive.BlockHeight * 25,
                            width: responsive.BlockWidth * 40,
                            margin: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 15),
                            padding: const EdgeInsets.only(top: 10),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                primary: Colors.white,
                                onPrimary: Colors.grey,
                                shadowColor: Colors.grey[400],
                                elevation: 10,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0)),
                              ),
                              onPressed: () async {
                                Navigator.pushNamed(context, '/speech',
                                    arguments: {"text": scannedText});
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 5, horizontal: 5),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.repeat,
                                      size: 40,
                                    ),
                                    Text(
                                      "Repeat",
                                      style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.grey[600]),
                                    )
                                  ],
                                ),
                              ),
                            )),
                      ],
                    ),
                  ],
                ),
                // const SizedBox(
                //   height: 20,
                // ),
                // Container(
                //   child: Text(
                //     scannedText,
                //     style: TextStyle(fontSize: 20),
                //   ),
                // )
                Container(
                    height: responsive.BlockHeight * 15,
                    width: responsive.BlockWidth * 90,
                    margin: const EdgeInsets.only(top: 10, bottom: 0),
                    padding: const EdgeInsets.only(top: 10),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: Colors.white,
                        onPrimary: Colors.grey,
                        shadowColor: Colors.grey[400],
                        elevation: 10,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.0)),
                      ),
                      onPressed: () {
                        getSpeech("You are in the Home Page");
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 5),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.help,
                              size: 30,
                            ),
                            Text(
                              "Help",
                              style: TextStyle(
                                  fontSize: 30, color: Colors.grey[600]),
                            )
                          ],
                        ),
                      ),
                    )),
              ],
            )),
      )),
    );
  }

  void getImage(ImageSource source) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      // final filePath = pickedImage?.path;
      // EdgeDetectionResult result = await EdgeDetector().detectEdges(filePath);
      // print(result);
      if (pickedImage != null) {
        textScanning = true;
        imageFile = pickedImage;
        setState(() {});
        predictImage(pickedImage);
        // getRecognisedText(pickedImage);
      }
    } catch (e) {
      textScanning = false;
      imageFile = null;
      scannedText = "Error occured while scanning";
      setState(() {});
    }
  }

  loadModel() async {
    Tflite.close();
    try {
      String res = await Tflite.loadModel(
            model: "assets/tflite/model.tflite",
            labels: "assets/tflite/labels.txt",
          ) ??
          '';
    } on PlatformException {
      print("Failed to load the model");
    }
  }

  void predictImage(XFile image) async {
    await classify(image);
    // setState(() {});
  }

  late List _recognitions;
  String val0 = "";
  String val1 = "";

  classify(XFile image) async {
    var recognitions = await Tflite.runModelOnImage(
        path: image.path, // required
        imageMean: 0.0, // defaults to 117.0
        imageStd: 255.0, // defaults to 1.0
        numResults: 2, // defaults to 5
        threshold: 0.2, // defaults to 0.1
        asynch: true // defaults to true
        );
    _recognitions = recognitions ?? [];
    // print(_recognitions);
    if (_recognitions[0]['label'].toString() == "BLUR") {
      // _selected0 = "BLUR";
      val0 = '${(_recognitions[0]["confidence"] * 100)}';
    } else {
      // _selected0 = '';
      val0 = '${(100 - (_recognitions[0]["confidence"] * 100))}';
    }

    if (_recognitions[0]['label'].toString() == "SHARP") {
      // _selected1 = "SHARP";
      val1 = '${(_recognitions[0]["confidence"] * 100)}';
    } else {
      // _selected1 = "";
      val1 = '${(100 - (_recognitions[0]["confidence"] * 100))}';
    }
    var v1 = double.parse(val0);
    var v2 = double.parse(val1);
    // print(v1);
    // print(v2);
    print('The values are: ${[val0, val1]}');
    print('The values2 are: ${[v1, v2]}');
    if (v2 > 60) {
      print("sharp");
      getRecognisedText(image);
    } else {
      print("blur");
      scannedText = "Please take picture again";
      getSpeech(scannedText);
      textScanning = false;
    }
    setState(() {});
  }

  void getRecognisedText(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    // final textDetector = GoogleMlKit.vision.textDetector();
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final recognisedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();
    scannedText = "";
    for (TextBlock block in recognisedText.blocks) {
      for (TextLine line in block.lines) {
        scannedText = "$scannedText${line.text}\n";
      }
    }
    textScanning = false;
    // getSpeech(scannedText);
    if (scannedText == "") {
      getSpeech("No text found. Please take picture again");
    } else {
      getSpeech("Text Found. Moving to next screen");
      if (!mounted) return;
      Navigator.pushNamed(context, '/speech', arguments: {"text": scannedText});
    }

    setState(() {});
  }

  void getSpeech(scannedText) async {
    await ftts.stop();
//your custom configuration
    await ftts.setLanguage("en-US");
    await ftts.setSpeechRate(0.5); //speed of speech
    await ftts.setVolume(1.0); //volume of speech
    await ftts.setPitch(1); //pitc of sound

    //play text to sp
    var result = await ftts.speak(scannedText);
    if (result == 1) {
      //speaking
    } else {
      //not speaking
    }
  }

  @override
  void initState() {
    super.initState();
    _busy = true;

    loadModel().then((val) {
      setState(() {
        _busy = false;
        scannedText = "Tflite module loded";
        print("loded");
      });
    });
  }
}
