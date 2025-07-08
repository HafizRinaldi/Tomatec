import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pytorch_lite/pytorch_lite.dart';
import 'package:tomatect/database.dart';
import 'package:tomatect/profil.dart';
import 'package:tomatect/utama.dart';
import 'package:tomatect/warna.dart';
import 'package:screenshot/screenshot.dart';
import 'package:recase/recase.dart';

class Deteksi extends StatefulWidget {
  final ModelObjectDetection objmodelv1;
  final File? gambar;
  const Deteksi({Key? key, required this.objmodelv1, required this.gambar})
    : super(key: key);

  @override
  _DeteksiState createState() => _DeteksiState();
}

class _DeteksiState extends State<Deteksi> {
  ScreenshotController screenshotController = ScreenshotController();

  Uint8List? bytes;
  String? textToShow;
  List? _prediction;
  File? _image;
  List<String?>? kelas_list = [];
  double? akurasi;
  List<double?>? akurasi_list = [];

  String? kelas = "";
  bool objectDetection = false;
  List<ResultObjectDetection?> objDetect = [];
  @override
  void initState() {
    DatabaseHelper.getAllProfile();
    super.initState();
    runObjectDetection(widget.objmodelv1, widget.gambar);
  }

  void _konfir_save(BuildContext context) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("Tidak"),
      onPressed: () {
        Navigator.pop(context);
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Iya"),
      onPressed: () async {
        Navigator.pop(context);
        byte64String = await pickImage2();
        if (kelas != "") {
          await DatabaseHelper.insertProfile(
            ProfileModel(name: "$kelas", image64bit: byte64String).toMap(),
          );
        } else {
          await DatabaseHelper.insertProfile(
            ProfileModel(
              name: "Tidak Terdeteksi",
              image64bit: byte64String,
            ).toMap(),
          );
        }

        pList = await DatabaseHelper.getAllProfile();
        setState(() {});

        print(pList[0].id);
        print(pList[0].name);
        print(pList[0].image64bit);
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Peringatan"),
      content: const Text("Simpan Gambar?"),
      actions: [cancelButton, continueButton],
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<String> pickImage(manok) async {
    var imageBytes = await manok!.readAsBytes();

    print("IMAGE PICKED: ${manok!.path}");

    String base64Image = base64Encode(imageBytes);

    return base64Image;
  }

  String uint8ListTob64(Uint8List uint8list) {
    String base64String = base64Encode(uint8list);
    String header = "data:image/png;base64,";
    return base64String;
  }

  Future pickImage2() async {
    await screenshotController.capture().then((image) {
      //Capture Done
      setState(() {
        bytes = image;
      });
    });
    final gambar = uint8ListTob64(bytes!);

    return gambar;
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to exit an App'),
            actions: <Widget>[
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(false), //<-- SEE HERE
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(true), // <-- SEE HERE
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  //run an image model
  Future runObjectDetection(model, gambar) async {
    Stopwatch stopwatch = Stopwatch()..start();
    if (gambar != null) {
      objDetect = await model.getImagePrediction(
        await File(gambar!.path).readAsBytes(),
        minimumScore: 0.4,
        iOUThreshold: 0.3,
      );
    }
    textToShow = inferenceTimeAsString(stopwatch);
    print('object executed in ${stopwatch.elapsed.inMilliseconds} ms');

    for (var element in objDetect) {
      setState(() {
        kelas_list!.insert(0, element?.className);
        akurasi_list!.insert(0, (element!.score * 100).toPrecision(1));
        akurasi = element?.score;
        akurasi = (akurasi! * 100)!;
        akurasi = akurasi!.toPrecision(1); // 2.3
      });
      print({
        "score": element?.score,
        "className": element?.className,
        "class": element?.classIndex,
        "rect": {
          "left": element?.rect.left,
          "top": element?.rect.top,
          "width": element?.rect.width,
          "height": element?.rect.height,
          "right": element?.rect.right,
          "bottom": element?.rect.bottom,
        },
      });
    }
    if (gambar != null) {
      setState(() {
        var seen = Set<String>();
        List<String?> uniquelist = kelas_list!
            .where((country) => seen.add(country!))
            .toList();
        print(uniquelist);
        kelas = uniquelist!.join(", ");
        _image = File(gambar.path);
      });
    }
  }

  List<ProfileModel> pList = [];
  String? byte64String;

  String inferenceTimeAsString(Stopwatch stopwatch) =>
      "Inference Took ${stopwatch.elapsed.inMilliseconds} ms";

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  height: 100,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/desain/head_history.png'),
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Detection result",
                  style: TextStyle(
                    fontSize: 25,
                    color: baru,
                    fontWeight: FontWeight.w500,
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(20),
                  height: 480,
                  width: 380,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: baru, width: 1),
                    borderRadius: const BorderRadius.all(Radius.circular(0)),
                  ),
                  alignment: Alignment.center,
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child: Column(
                    children: [
                      Align(
                        alignment: AlignmentDirectional.topCenter,
                        child: Container(
                          height: 350,
                          width: 350,
                          decoration: const BoxDecoration(color: Colors.white),
                          alignment: Alignment.center,
                          margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                          //color: putih_3,
                          child: Screenshot(
                            controller: screenshotController,
                            child: objDetect.isNotEmpty
                                ? _image == null
                                      ? const Text('tidak')
                                      : widget.objmodelv1.renderBoxesOnImage(
                                          _image!,
                                          objDetect,
                                        )
                                : _image == null
                                ? const Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Tidak ada Gambar",
                                        style: TextStyle(
                                          fontSize: 25,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      Container(
                                        height: 350,
                                        width: 300,
                                        decoration: BoxDecoration(
                                          image: DecorationImage(
                                            image: FileImage(_image!),
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      kelas != ""
                          ? FittedBox(
                              fit: BoxFit.fitWidth,
                              child: Column(
                                children: [
                                  Text(
                                    "Detection Results: $kelas".titleCase,
                                    style: TextStyle(
                                      fontSize: 25,
                                      color: baru,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    "Accuracy: $akurasi_list%",
                                    style: TextStyle(
                                      fontSize: 25,
                                      color: baru,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const Text(
                              "Not detected",
                              style: TextStyle(
                                fontSize: 25,
                                color: Colors.black,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 30),
                        _image != null
                            ? TextButton(
                                onPressed: () async {
                                  _konfir_save(context);
                                },
                                child: Container(
                                  height: 60,
                                  width: 300,
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(color: baru, width: 1),
                                    borderRadius: const BorderRadius.all(
                                      Radius.circular(45),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Save",
                                            style: TextStyle(
                                              fontSize: 20,
                                              color: baru,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : const Text(""),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HalamanUtama(),
                              ),
                            );
                          },
                          child: Container(
                            height: 60,
                            width: 300,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: baru,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(45),
                              ),
                            ),
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Back",
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Visibility(
                    visible: _prediction != null,
                    child: Text(
                      _prediction != null ? "${_prediction![0]}" : "",
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
