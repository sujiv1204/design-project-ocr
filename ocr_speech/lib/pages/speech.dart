// ignore_for_file: unused_element

import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/material.dart';

enum TtsState {
  play,
  stop,
  pause,
  continued
} // enum cannot be declared inside a class

class SpeechState {
  String? input_text;

  double volume = 1.5;
  double rate = 0.5;
  double pitch = 1.0;
  TtsState state = TtsState.stop;

  late FlutterTts Tts; //creatung the FlutterTts() object

  SpeechState() {
    Tts = FlutterTts();
    //Handlers are used to change the state of the tts class
    Tts.setStartHandler(() {
      print("Playing");
      state = TtsState.play;
    });

    Tts.setCompletionHandler(() {
      print('Completed');
      state = TtsState.stop;
    });

    Tts.setCancelHandler(() {
      print("Stop");
      state = TtsState.stop;
    });

    Tts.setPauseHandler(() {
      print("Pause");
      state = TtsState.pause;
    });
  }

  Feed_data(String data) {
    this.input_text = data;
  }

  //Function to speak out text in input_text
  Future speak() async {
    //print('Hi');
    await Tts.setVolume(volume);
    await Tts.setPitch(pitch);
    await Tts.setSpeechRate(rate);

    //check for input text and read it out
    if (input_text != null) {
      if (input_text!.isNotEmpty) {
        await Tts.speak(input_text!);
      } else {
        await Tts.speak("No text present in Input Text");
      }
    } else {
      await Tts.speak('Input text is Null');
    }
  }

  Future pause() async {
    var result = await Tts.pause();
    if (result == 1) {
      state = TtsState.pause;
    }
  }

  Future stop() async {
    var result = await Tts.stop();
    if (result == 1) {
      state = TtsState.stop;
    }
  }

  set_pitch(value) async {
    var result = await Tts.setPitch(value);
    if (result == 1) {
      print('in pitch');
      this.pitch = value;
    }
  }

  set_rate(value) async {
    this.rate = value;
    await Tts.setSpeechRate(value);
  }

  download() {
    Tts.synthesizeToFile(input_text!, 'audio');
  }
}
