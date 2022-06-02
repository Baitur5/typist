import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:typist/constants/commonWords.dart';
import 'package:typist/utils/get_responsive_font.dart';
import 'package:flutter/foundation.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class TestPage extends StatefulWidget {
  TestPage({Key? key}) : super(key: key);

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final _prefs = SharedPreferences.getInstance();

  late TextEditingController backController;
  late TextEditingController frontController;

  //we need two scroll controllers so we can change scroll position of two textfields together
  late ScrollController scrollOne;
  late ScrollController scrollTwo;

  bool enabled = true; //to check whether to enable backspace button
  bool to_change = true;
  bool is_correct = true; //to check whether current word is correct or not
  bool is_timer_started = false;
  bool is_backspace = false;

  int current_word_index = 0;
  int last_words_index = 0;

  int bestWPM = 0;

  int chars = 0;
  int correct_chars = 0;
  int incorrect_chars = 0;
  int net_wpm = 0;
  int gross_wpm = 0;

  late String text;

  String last_change = '';
  int leng = -1;

  late Timer _timer;
  int _start = 60;

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = new Timer.periodic(
      oneSec,
      (Timer timer) {
        if (_start == 0) {
          setState(() async {
            timer.cancel();

            gross_wpm = (chars / 5).round();
            net_wpm = gross_wpm - incorrect_chars;
            if (net_wpm > bestWPM) {
              var is_success = await setBest(net_wpm);
            }
            showDialog(
                context: navigatorKey.currentContext!,
                builder: (context) {
                  return WillPopScope(
                    onWillPop: () async => false,
                    child: AlertDialog(
                      title: Center(
                        child: Text("Your result is $net_wpm WPM!"),
                      ),
                      actions: [
                        TextButton(
                            onPressed: () {
                              navigatorKey.currentState!.pushReplacement(
                                  MaterialPageRoute(
                                      builder: ((context) => TestPage())));
                            },
                            child: const Text(
                              "OK",
                              style: TextStyle(color: Colors.white),
                            )),
                      ],
                    ),
                  );
                });
          });
        } else {
          setState(() {
            _start--;
          });
        }
      },
    );
  }

  getBest() async {
    final SharedPreferences prefs = await _prefs;
    setState(() {
      bestWPM = prefs.getInt('best') ?? 0;
    });
  }

  setBest(int val) async {
    final SharedPreferences prefs = await _prefs;
    await prefs.setInt('best', val);
  }

  @override
  void initState() {
    super.initState();
    getBest();
    //initialize controllers
    backController = TextEditingController();
    frontController = TextEditingController();
    scrollOne = ScrollController();
    scrollTwo = ScrollController();

    commonWords.shuffle();
    text = commonWords.join(" ");
    backController.text = text;

    frontController.addListener(() {
      if (frontController.text.split(" ")[current_word_index].length >
          commonWords[current_word_index].length) {
        print("Here");
        var new_text = backController.text.split(" ");
        new_text.setAll(current_word_index,
            [frontController.text.split(" ")[current_word_index]]);
        print(new_text.join(" "));

        backController.text = new_text.join(" ");
      }
      if (frontController.text.length < leng &&
          frontController.text.isNotEmpty) {
        print("Here2 ");
        backController.value = backController.value.copyWith(
            text:
                "${frontController.text}${text.substring(frontController.text.length)}");
        last_change = frontController.text.substring(
            frontController.text.isNotEmpty
                ? frontController.text.length - 1
                : 1);
        leng = frontController.text.length;
        is_backspace = true;
      } else {
        var n_text = backController.text.substring(
            frontController.text.length, frontController.text.length + 1);
        var l_text = frontController.text.substring(
            frontController.text.isNotEmpty
                ? frontController.text.length - 1
                : 1);
        var fsplit = frontController.text.split(" ");

        if (fsplit.last.isEmpty) {
          fsplit.removeLast();
        }

        var bsplit = backController.text.split(" ");
        bsplit.removeRange(fsplit.length, bsplit.length);

        if (l_text == " ") {
          setState(() {
            current_word_index++;
            is_correct = true;
          });
        }

        if (!listEquals(bsplit, fsplit) && l_text == " ") {
          var x = backController.text.split(" ");
          x.removeRange(0, fsplit.length);
          backController.value = backController.value
              .copyWith(text: "${fsplit.join(" ")} ${x.join(" ")}".trim());
          text = backController.text;
          to_change = false;
        } else {
          String check = backController.text.substring(
              frontController.text.length, frontController.text.length + 1);

          backController.value = backController.value.copyWith(
              text:
                  "${to_change ? frontController.text : frontController.text.substring(0, frontController.text.length - 1)}${to_change ? backController.text.substring(frontController.text.length) : commonWords.skip(fsplit.length - 1).join(" ")}");
          to_change = true;
          if (frontController.text.isNotEmpty) {
            last_change = frontController.text.substring(
                frontController.text.isNotEmpty
                    ? frontController.text.length - 1
                    : 1);
            leng = frontController.text.length;
          }
        }
        // is_correct ? print("C") : print("N");
        // is_correct ? correct_chars++ : incorrect_chars++;
        is_backspace = false;
        chars++;
      }
    });

    scrollTwo.addListener(() {
      scrollOne.animateTo(scrollTwo.offset,
          duration: const Duration(microseconds: 1), curve: Curves.linear);
    });
  }

  @override
  void dispose() {
    backController.dispose();
    frontController.dispose();
    scrollOne.dispose();
    scrollTwo.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    num width = MediaQuery.of(context).size.width;
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
          appBar: AppBar(
            title: const Text(
              "Typist",
            ),
            centerTitle: false,
            actions: [
              Row(
                children: [
                  const Icon(
                    Icons.bar_chart_rounded,
                    size: 32,
                  ),
                  const SizedBox(
                    width: 3,
                  ),
                  Text(
                    "$bestWPM WPM",
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                ],
              ),
            ],
            elevation: 0,
            automaticallyImplyLeading: false,
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                height: 70,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                    child: Text(
                      _start == 60 ? "1:00" : "00:$_start",
                      style: TextStyle(
                        fontSize: getadaptiveTextSize(context, 16),
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
                    child: GestureDetector(
                      onTap: () {
                        showDialog(
                            context: navigatorKey.currentContext!,
                            builder: (context) {
                              return AlertDialog(
                                title: const Center(
                                  child: Text(
                                      "Are you sure you want to reset it?"),
                                ),
                                actions: [
                                  TextButton(
                                      onPressed: () {
                                        navigatorKey.currentState!.pop();
                                      },
                                      child: const Text(
                                        "No",
                                        style: TextStyle(color: Colors.white),
                                      )),
                                  TextButton(
                                      onPressed: () {
                                        navigatorKey.currentState!
                                            .pushReplacement(MaterialPageRoute(
                                                builder: ((context) =>
                                                    TestPage())));
                                      },
                                      child: const Text(
                                        "Yes",
                                        style: TextStyle(color: Colors.white),
                                      )),
                                ],
                              );
                            });
                      },
                      child: const Icon(
                        Icons.restart_alt_rounded,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              if (!is_timer_started)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: width * 0.02),
                  child: Text(
                    "Start typing",
                    style:
                        TextStyle(fontSize: getadaptiveTextSize(context, 13)),
                  ),
                ),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: width * 0.02),
                child: Stack(
                  children: [
                    TextField(
                      autocorrect: false,
                      scrollController: scrollOne,
                      // selectionControls: ,
                      autofocus: false,
                      controller: backController,
                      cursorColor: Colors.grey,
                      style: TextStyle(
                        fontSize: getadaptiveTextSize(context, 21),
                        color: Colors.grey,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            width: 0,
                            style: BorderStyle.none,
                          ),
                        ),
                        contentPadding: EdgeInsets.only(
                          top: width * 0.03,
                          bottom: width * 0.03,
                          left: width * 0.02,
                          right: width * 0.02,
                        ),
                      ),
                    ),
                    RawKeyboardListener(
                      focusNode: FocusNode(),
                      onKey: ((value) {
                        var text = frontController.text
                            .substring(frontController.text.length - 1);
                        if (value.logicalKey == LogicalKeyboardKey.backspace &&
                            text == " ") {
                          setState(() {
                            enabled = false;
                          });
                        } else {
                          setState(() {
                            enabled = true;
                          });
                        }
                      }),
                      child: TextField(
                        autocorrect: false,
                        autofocus: false,
                        scrollController: scrollTwo,
                        controller: frontController,
                        cursorColor: Colors.grey,
                        onChanged: (text) {
                          if (!is_timer_started) {
                            startTimer();
                            is_timer_started = true;
                          }
                          var words = frontController.text.split(" ").last;
                          var l_text = frontController.text.substring(
                              frontController.text.isNotEmpty
                                  ? frontController.text.length - 1
                                  : 1);
                          if (commonWords[current_word_index]
                              .contains(words.trim())) {
                            if (!is_backspace) correct_chars++;
                            // correct_chars++;
                            setState(() {
                              is_correct = true;
                            });
                          } else {
                            if (!is_backspace) incorrect_chars++;
                            // incorrect_chars++;
                            setState(() {
                              is_correct = false;
                            });
                          }
                          if (!enabled) {
                            var n_text = text.substring(0, text.length);
                            n_text += " ";
                            frontController.text = n_text;
                            frontController.selection = TextSelection(
                                baseOffset: n_text.length,
                                extentOffset: n_text.length);
                            setState(() {
                              current_word_index--;
                            });
                          }
                        },
                        style: TextStyle(
                          fontSize: getadaptiveTextSize(context, 21),
                          color: is_correct ? Colors.white : Colors.red[400],
                        ),
                        decoration: InputDecoration(
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              width: 0,
                              style: BorderStyle.none,
                            ),
                          ),
                          contentPadding: EdgeInsets.only(
                            top: width * 0.03,
                            bottom: width * 0.03,
                            left: width * 0.02,
                            right: width * 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )),
    );
  }
}

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}
