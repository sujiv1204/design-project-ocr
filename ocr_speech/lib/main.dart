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
import 'package:flutter_vibrate/flutter_vibrate.dart';

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
  bool ismale = true;
  bool _busy = false;
  FlutterTts ftts = FlutterTts();
  bool textScanning = false;

  XFile? imageFile;

  String scannedText = "";
  late Responsive responsive;
  bool _canVibrate = true;

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
                            Vibration("Medium");

                            getImage(ImageSource.camera, "document");
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
                                Vibration("Medium");
                                getImage(ImageSource.camera, "currency");
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
                                      "Currency",
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
                              onPressed: () {
                                Vibration("Medium");
                                print('in repeat');
                                print(scannedText);
                                Navigator.pushNamed(context, '/speech',
                                    arguments: {
                                      "text": scannedText,
                                      "ismale": ismale
                                    });
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
                        Vibration("Medium");
                        getSpeech(
                            "You are in the Home Page. On the top is the camera button. At the bottom half there are two options of gallery on your left and repeat on the right to re read the image. ");
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

  void getImage(ImageSource source, String type) async {
    try {
      final pickedImage = await ImagePicker().pickImage(source: source);
      // final filePath = pickedImage?.path;
      // EdgeDetectionResult result = await EdgeDetector().detectEdges(filePath);
      // print(result);
      if (pickedImage != null) {
        textScanning = true;
        imageFile = pickedImage;
        setState(() {});
        predictImage(pickedImage, type);
        // getRecognisedText(pickedImage);
      }
    } catch (e) {
      textScanning = false;
      imageFile = null;
      scannedText = "Error occured while scanning";
      setState(() {});
    }
  }

  loadModel(int model) async {
    Tflite.close();
    try {
      String? modelToLoad;
      String? labelToLoad;
      if (model == 1) {
        modelToLoad = "model";
        labelToLoad = "labels";
      } else if (model == 2) {
        modelToLoad = "student";
        labelToLoad = "labels1";
      } else if (model == 3) {
        modelToLoad = "model_unquant";
        labelToLoad = "labels2";
      }
      String res = await Tflite.loadModel(
            model: "assets/tflite/$modelToLoad.tflite",
            labels: "assets/tflite/$labelToLoad.txt",
          ) ??
          '';
      setState(() {});
    } on PlatformException {
      print("Failed to load the model");
    }
  }

  void predictImage(XFile image, String type) async {
    await classify(image, type);
    // setState(() {});
  }

  late List _recognitions;
  String val0 = "";
  String val1 = "";

  classify(XFile image, String type) async {
    loadModel(1);
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
      if (type == "document") {
        documentProcessing(image);
      } else if (type == "currency") {
        currencyProcessing(image);
      }
    } else {
      print("blur");
      scannedText = "Please take picture again";
      getSpeech(scannedText);
      textScanning = false;
    }
    setState(() {});
  }

  double? ocrRes;
  documentProcessing(XFile image) async {
    loadModel(2);
    var recognitions = await Tflite.runModelOnImage(
        path: image.path, // required
        imageMean: 0.0, // defaults to 117.0
        imageStd: 255.0, // defaults to 1.0
        numResults: 2, // defaults to 5
        threshold: 0.2, // defaults to 0.1
        asynch: true // defaults to true
        );
    _recognitions = recognitions ?? [];
    ocrRes = _recognitions[0]["confidence"] * 100;
    print(ocrRes);
    if (ocrRes! > 60) {
      getRecognisedText(image);
    } else {
      scannedText = "Please take picture again";
      getSpeech(scannedText);
      textScanning = false;
    }
    setState(() {});
  }

  String currency = "";
  currencyProcessing(XFile image) async {
    loadModel(3);
    var recognitions = await Tflite.runModelOnImage(
        path: image.path, // required
        imageMean: 0.0, // defaults to 117.0
        imageStd: 255.0, // defaults to 1.0
        numResults: 2, // defaults to 5
        threshold: 0.2, // defaults to 0.1
        asynch: true // defaults to true
        );
    _recognitions = recognitions ?? [];
    print(_recognitions);
    final maxLabel = _recognitions
        .reduce((a, b) => a["confidence"] > b["confidence"] ? a : b)["label"];
    print(maxLabel);
    currency = maxLabel.toString();
    scannedText = currency;
    getSpeech(scannedText);
    textScanning = false;
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
      scannedText = "No text found. Please take picture again";
      getSpeech("No text found. Please take picture again");
    } else {
      getSpeech("Text Found. Moving to next screen");
      if (!mounted) return;
      Navigator.pushNamed(context, '/speech',
          arguments: {"text": scannedText, "ismale": ismale});
    }

    setState(() {});
  }

  void getSpeech(scannedText) async {
    await ftts.stop();
//your custom configuration
    //await ftts.setLanguage("en-US");
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

  init_vibrate() async {
    bool canvibrate = await Vibrate.canVibrate;
    setState(() {
      _canVibrate = canvibrate;
      _canVibrate
          ? print('Device can vibrate')
          : print('device cannot vibrate');
    });
  }

  Future Vibration(String text) async {
    if (_canVibrate) {
      // await Vibrate.vibrateWithPauses(Pauses);
      var type = FeedbackType.light;
      if (text == "Play") {
        type = FeedbackType.success;
      } else if (text == "Pause") {
        type = FeedbackType.warning;
      } else if (text == "Stop") {
        type = FeedbackType.error;
      } else if (text == "Medium") {
        type = FeedbackType.medium;
      }
      Vibrate.feedback(type);
    }
  }

  @override
  void initState() {
    super.initState();
    print('2');
    _busy = true;

    init_vibrate();
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    print('1');
    // put your logic from initState here
    await loadModel(1).then((val) {
      setState(() {
        _busy = false;
        scannedText = "Tflite module loaded";
        print("loaded");
      });
    });

    final args = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;
    print('args $args');
    setState(() {
      if (args.isEmpty) {
        ismale = true;
        scannedText = "Welcome to our application Eye to the Blind";
        print('Inside if block');
        print(scannedText);
      } else {
        ismale = args['ismale'];
        scannedText = args['scannedText'];
        print('Inside else block');
        print(scannedText);
      }
    });

    // setState(() {});
    // if (args['ismale'] == Null)
    //   ismale = true;
    // else
  }
}
