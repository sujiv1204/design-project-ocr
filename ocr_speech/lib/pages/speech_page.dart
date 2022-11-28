// ignore_for_file: prefer_const_constructors, sized_box_for_whitespace, non_constant_identifier_names
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ocr_speech/pages/responsive.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutter_tts/flutter_tts.dart';
//import 'package:speech/speech.dart';

enum TtsState { play, stop, pause, completed }

Iterable<Duration> Pauses = [
  Duration(milliseconds: 100),
  Duration(milliseconds: 500),
  Duration(milliseconds: 700),
];
// Iterable<Duration> Plays = [];
// Iterable<Duration> Stops = [];

void main() => runApp(const MaterialApp(
      home: SpeechPage(),
    ));

class SpeechPage extends StatefulWidget {
  // const SpeechPage({super.key});
  // final String? text;
  const SpeechPage({Key? key}) : super(key: key);
  @override
  State<SpeechPage> createState() => _SpeechPageState();
}
// class ScreenArguments {
//   final String text;
//   // final String message;

//   ScreenArguments(this.text);
// }

class _SpeechPageState extends State<SpeechPage> {
  late FlutterTts Tts;

  String? input_text;
  String? recognisedText;

  double volume = 1.5;
  double rate = 0.5;
  double pitch = 1.0;
  TtsState state = TtsState.stop;
  late Responsive responsive;

  bool _canVibrate = true;

  @override
  void initState() {
    super.initState();

    // init_Tts();
    // init_vibrate();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // put your logic from initState here
    final args = (ModalRoute.of(context)?.settings.arguments ??
        <String, dynamic>{}) as Map;
    recognisedText = args['text'];
    // print(recognisedText);
    init_Tts();
    init_vibrate();
  }

  Feed_data() {
    // input_text =
    //     "It all started with a random letter. Several of those were joined forces to create a random word. The words decided to get together and form a random sentence. They decided not to stop there and it wasn't long before a random paragraph had been cobbled together. The question was whether or not they could continue the momentum long enough to create a random short story.";

    print("Begin of text test");
    input_text = recognisedText;
    print(input_text);
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

  init_Tts() {
    Tts = FlutterTts();
    Tts.setStartHandler(() {
      print("Playing");
      setState() {
        state = TtsState.play;
      }
    });

    Tts.setCompletionHandler(() {
      print('Completed');
      setState(() {
        state = TtsState.completed;
      });
    });

    Tts.setCancelHandler(() {
      print("Stop");
      setState(() {
        state = TtsState.stop;
      });
    });

    Tts.setPauseHandler(() {
      print("Pause");
      setState(() {
        state = TtsState.pause;
      });
    });

    Feed_data();
  }

  Future Speak() async {
    print('In speak');
    await Tts.setVolume(volume);
    await Tts.setPitch(pitch);
    await Tts.setSpeechRate(rate);

    await setAwaitOptions();

    if (input_text != null) {
      if (input_text!.isNotEmpty) {
        //await Future.delayed(Duration(seconds: 10));
        print('after delay');
        setState(() {
          state = TtsState.play;
        });
        await Tts.speak(input_text!);
      }
    }
    print('Speak over');
  }

  Future setAwaitOptions() async {
    await Tts.awaitSpeakCompletion(true);
  }

  Future pause() async {
    var res = await Tts.pause();
    print(res);
    if (res == 1) {
      setState(() {
        state = TtsState.pause;
      });
    }
  }

  Future stop() async {
    var res = await Tts.stop();
    print(res);
    if (res == 1) {
      setState(() {
        state = TtsState.stop;
      });
    }
  }

  String get_state() {
    print('State in get_state ${state}');
    return state.toString();
  }

  @override
  Widget build(BuildContext context) {
    responsive = Responsive(context);

    // setState(() {});
    // print(args['text']);
    return SafeArea(
      child: Scaffold(
          appBar: AppBar(
            title: Text('Speech Generation'),
            centerTitle: true,
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Button('Play', Speak),
                  Button('Pause', pause),
                  Button('stop', stop)
                ],
              ),
              SizedBox(height: responsive.BlockHeight * 10),
              get_state() != 'TtsState.play' ? SliderRow() : Container(),
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
                      getSpeech("You are in playback page");
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
    );
  }

  FlutterTts ftts = FlutterTts();

  void getSpeech(scannedText) async {
    await ftts.stop();
//your custom configuration
    await ftts.setLanguage("en-US");
    await ftts.setSpeechRate(0.5); //speed of speech
    await ftts.setVolume(1.0); //volume of speech
    await ftts.setPitch(1.0); //pitch of sound

    //play text to sp
    var result = await ftts.speak(scannedText);
    if (result == 1) {
      //speaking
    } else {
      //not speaking
    }
  }

  Widget SliderRow() {
    //print('In sliderRow');
    double minRate = 0.0;
    double maxRate = 1.0;
    double minPitch = 0.0;
    double maxPitch = 2.0;

    double height = responsive.SafeBlockHeight * 30;
    //double width = responsive.SafeBlockWidth*30;
    return Container(
        height: height,
        child: SliderTheme(
          data: SliderThemeData(
            trackHeight: responsive.SafeBlockWidth * 25,
            thumbShape: SliderComponentShape.noOverlay,
            overlayShape: SliderComponentShape.noOverlay,
            valueIndicatorShape: SliderComponentShape.noOverlay,
            trackShape: RectangularSliderTrackShape(),
            activeTrackColor: Colors.blue[500],
            inactiveTrackColor: Colors.grey[400],
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SliderWidget('rate', minRate, maxRate),
                SliderWidget('pitch', minPitch, maxPitch),
              ]),
        ));
  }

  Widget SliderWidget(String type, double min, double max) {
    double Value = type == 'rate' ? rate : pitch;
    return Stack(children: [
      RotatedBox(
          quarterTurns: 3,
          child: Slider(
            value: Value,
            min: min,
            max: max,
            divisions: 4,
            label: type,
            onChanged: ((value) {
              setState(() {
                type == 'rate' ? rate = value : pitch = value;
              });
            }),
          )),
    ]);
  }

  Widget Button(String text, Function func) {
    return Container(
        height: responsive.BlockHeight * 30,
        width: responsive.BlockWidth * 30,
        child: FractionallySizedBox(
          widthFactor: 0.9,
          heightFactor: 0.9,
          child: ElevatedButton(
              onPressed: () async {
                await Vibration();
                func();
              },
              child: Text('$text')),
        ));
  }

  Future Vibration() async {
    if (_canVibrate) {
      await Vibrate.vibrateWithPauses(Pauses);
    }
  }
}
