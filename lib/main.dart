import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:simple_edge_detection/edge_detection.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scan(),
    );
  }
}

class Scan extends StatefulWidget {
  @override
  _ScanState createState() => _ScanState();
}

class _ScanState extends State<Scan> {
  CameraController controller;
  List<CameraDescription> cameras;
  List<PickedFile> fileList = new List();
  String imagePath;
  bool run = false;
  @override
  void initState() {
    super.initState();
    checkForCameras().then((value) {
      _initializeController();
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _initializeController() async {
    checkForCameras();
    if (cameras.length == 0) {
      return;
    }
    controller = CameraController(cameras[0], ResolutionPreset.veryHigh,
        enableAudio: false);
    controller.initialize().then((value) {
      if (!mounted) return;
      setState(() {});
    });
  }

  Future<void> checkForCameras() async {
    cameras = await availableCameras();
  }

  Widget _getMainWidget() {
    return CameraView(controller: controller);
  }

  Widget _getBottomBar() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FloatingActionButton(
              foregroundColor: Colors.white,
              child: Icon(Icons.camera),
              onPressed: onTakePictureButtonPressed,
              heroTag: "btn1",
            ),
            SizedBox(
              width: 16,
            ),
            decider(),
          ],
        ),
      ),
    );
  }

  Widget decider() {
    if (!run)
      return FloatingActionButton(
        onPressed: _timeCameraClicker,
        foregroundColor: Colors.white,
        child: Icon(Icons.timer_10),
        heroTag: "btn2",
      );
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          run = false;
        });
      },
      foregroundColor: Colors.white,
      child: Icon(Icons.stop),
      heroTag: "btn3",
    );
  }

  Future<void> _timeCameraClicker() async {
    setState(() {
      run = true;
    });
    Future.doWhile(() async {
      await takePicture().then((value) {
        print(value);
        fileList.add(new PickedFile(value));
      });
      await Future.delayed(new Duration(seconds: 7));
      return run;
    });
  }

  String timestamp() => DateTime.now().millisecondsSinceEpoch.toString();
  Future<String> takePicture() async {
    if (!controller.value.isInitialized) {
      return null;
    }
    final Directory extDir = await getTemporaryDirectory();
    final String dirPath = '${extDir.path}/Pictures/flutter_test';
    await Directory(dirPath).create(recursive: true);
    final String filePath = '$dirPath/${timestamp()}.jpg';

    if (controller.value.isTakingPicture) {
      return null;
    }

    try {
      await controller.takePicture(filePath);
    } on CameraException catch (e) {
      print(e);
      return null;
    }
    return filePath;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ImagePreview(
                              fileList: fileList,
                            )));
              }),
        ],
      ),
      body: Stack(
        children: [
          _getMainWidget(),
          _getBottomBar(),
        ],
      ),
    );
  }

  void onTakePictureButtonPressed() async {
    String filePath = await takePicture();
    print(filePath);
  }
}

class ImagePreview extends StatefulWidget {
  final List<PickedFile> fileList;

  const ImagePreview({Key key, this.fileList}) : super(key: key);
  @override
  _ImagePreviewState createState() => _ImagePreviewState();
}

class _ImagePreviewState extends State<ImagePreview> {
  Widget bodies() {
    return new ListView.builder(
        itemCount: widget.fileList.length,
        itemBuilder: (BuildContext ctx, int index) {
          return Padding(
            padding: EdgeInsets.all(8.0),
            child: GestureDetector(
              child: Card(
                elevation: 20,
                child: Column(
                  children: [
                    Image.file(File(widget.fileList[index].path)),
                  ],
                ),
              ),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => Draw(
                              imageFile: widget.fileList[index],
                            )));
              },
            ),
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              icon: Icon(Icons.save_alt),
              onPressed: () async {
                final doc = pw.Document();
                for (int i = 0; i < widget.fileList.length; i++) {
                  var imageProvider = AssetImage(widget.fileList[i].path);
                  final PdfImage image = await pdfImageFromImageProvider(
                      pdf: doc.document, image: imageProvider);
                  doc.addPage(pw.Page(build: (pw.Context context) {
                    return pw.Center(
                      child: pw.Image(image),
                    );
                  }));
                }
                await Printing.sharePdf(
                    bytes: doc.save(), filename: "test.pdf");
              }),
        ],
      ),
      body: bodies(),
    );
  }
}

class CameraView extends StatelessWidget {
  CameraView({this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return _getCameraPreview();
  }

  Widget _getCameraPreview() {
    if (controller == null || !controller.value.isInitialized) {
      return Container();
    }

    return Center(
        child: AspectRatio(
            aspectRatio: controller.value.aspectRatio,
            child: CameraPreview(controller)));
  }
}

class ImageChecker extends StatefulWidget {
  @override
  _ImageCheckerState createState() => _ImageCheckerState();
}

class _ImageCheckerState extends State<ImageChecker> {
  PickedFile imageFile;
  bool isImageResized = false, isFirst = true;
  Uint8List task;
  Future<PickedFile> loadImage(bool gallery) async {
    Navigator.of(context).pop();
    final Completer<PickedFile> completer = new Completer();
    if (gallery) {
      ImagePicker().getImage(source: ImageSource.gallery).then((value) {
        setState(() {
          isImageResized = true;
          task = null;
        });
        return completer.complete(value);
      });
    } else {
      ImagePicker().getImage(source: ImageSource.camera).then((value) {
        setState(() {
          isImageResized = true;
          task = null;
        });
        return completer.complete(value);
      });
    }
    return completer.future;
  }

  _resizeImage(bool gallery) async {
    imageFile = await loadImage(gallery);
  }

  Future<void> _alertChoiceDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Select Image"),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  GestureDetector(
                    child: Text("Gallery"),
                    onTap: () {
                      setState(() {
                        isFirst = false;
                        imageFile = null;
                        isImageResized = false;
                        _resizeImage(true);
                      });
                    },
                  ),
                  SizedBox(height: 20.0),
                  GestureDetector(
                    child: Text("Camera"),
                    onTap: () {
                      setState(() {
                        isFirst = false;
                        imageFile = null;
                        isImageResized = false;
                        _resizeImage(false);
                      });
                    },
                  )
                ],
              ),
            ),
          );
        });
  }

  Widget _imageDecider() {
    if (isFirst || imageFile == null) return Container();
    return images();
  }

  images() {
    if (!isImageResized || imageFile == null)
      return new Center(child: new Text('loading'));
    if (task == null) return (Image.file(File(imageFile.path)));
    return Image.memory(task);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Parent Screen"),
        actions: [
          IconButton(
              icon: Icon(Icons.edit),
              onPressed: () {
                _alertChoiceDialog(context);
              })
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height - 200,
                child: _imageDecider(),
              ),
              FlatButton(
                onPressed: () async {
                  if (imageFile != null) {
                    final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => Draw(
                                  imageFile: imageFile,
                                )));
                    setState(() {
                      task = result;
                    });
                  }
                },
                child: Text("Click to edit"),
                color: Colors.blue,
                textColor: Colors.white,
                disabledColor: Colors.grey,
                disabledTextColor: Colors.black,
                padding: EdgeInsets.all(8.0),
                splashColor: Colors.blueAccent,
              )
            ],
          ),
        ),
      ),
    );
  }
}

class Draw extends StatefulWidget {
  final PickedFile imageFile;

  const Draw({Key key, this.imageFile}) : super(key: key);
  @override
  _DrawState createState() => _DrawState();
}

class _DrawState extends State<Draw> {
  List<DrawModel> pointsList = List();
  bool cropImage = false;
  bool edit = false;
  int touched = -1;
  ui.Image image;
  bool isImageLoaded = false;
  int rotation = 0;
  _openCamera() async {
    List<Offset> list = await tp();
    Offset tl, tr, br, bl;
    setState(() {
      tl = list[0];
      tr = list[1];
      br = list[2];
      bl = list[3];
      Paint paint = Paint();
      paint.color = Colors.red;
      paint.strokeWidth = 20.0;
      paint.strokeCap = StrokeCap.round;
      pointsList.add(DrawModel(
        offset: tl,
        paint: paint,
      ));
      pointsList.add(DrawModel(
        offset: (tl + tr) / 2,
        paint: paint,
      ));
      pointsList.add(DrawModel(
        offset: tr,
        paint: paint,
      ));
      pointsList.add(DrawModel(
        offset: (tr + br) / 2,
        paint: paint,
      ));
      pointsList.add(DrawModel(
        offset: br,
        paint: paint,
      ));
      pointsList.add(DrawModel(
        offset: (br + bl) / 2,
        paint: paint,
      ));
      pointsList.add(DrawModel(
        offset: bl,
        paint: paint,
      ));
      pointsList.add(DrawModel(
        offset: (bl + tl) / 2,
        paint: paint,
      ));
    });
  }

  @override
  void initState() {
//

    super.initState();
    init();
  }

  Future<Null> init() async {
    image = await loadImage(File(widget.imageFile.path).readAsBytesSync());
  }

  @override
  void dispose() {
//
    super.dispose();
  }

  tp() async {
    List<Offset> list = new List();
    list.add(new Offset(10 * (image.height / MediaQuery.of(context).size.width),
        10 * (image.height / MediaQuery.of(context).size.width)));
    list.add(new Offset(
        image.width.toDouble() -
            (10 * (image.height / MediaQuery.of(context).size.width)),
        10 * (image.height / MediaQuery.of(context).size.width)));
    list.add(new Offset(
        image.width.toDouble() -
            (10 * (image.height / MediaQuery.of(context).size.width)),
        image.height.toDouble() -
            (10 * (image.height / MediaQuery.of(context).size.width))));
    list.add(new Offset(
        10 * (image.height / MediaQuery.of(context).size.width),
        image.height.toDouble() -
            (10 * (image.height / MediaQuery.of(context).size.width))));
    return list;
  }

  Widget _buildImage() {
    if (isImageLoaded) {
      if (pointsList.length == 0) _openCamera();
      return Center(
        child: RotatedBox(
          quarterTurns: rotation,
          child: FittedBox(
            child: SizedBox(
              height: image.height.toDouble(),
              width: image.width.toDouble(),
              child: new CustomPaint(
                painter: new MyImagePainter(
                    image: image,
                    pointsList: pointsList,
                    context: context,
                    height: MediaQuery.of(context).size.width.toInt(),
                    crop: cropImage),
                child: GestureDetector(
                  onPanStart: (details) {
                    touched = closestOffset(details.localPosition);
                  },
                  onPanUpdate: (details) {
                    Offset click = new Offset(
                        details.localPosition.dx, details.localPosition.dy);
                    setState(() {
                      if (touched != -1) {
                        Paint paint = Paint();
                        paint.color = Colors.red;
                        paint.strokeWidth = 20.0;
                        paint.strokeCap = StrokeCap.round;
                        if (touched % 2 != 0) {
                          Offset diff = (pointsList[touched].offset - click);
                          Offset back =
                              (pointsList[(touched - 1) % 8].offset - diff);
                          Offset forward =
                              (pointsList[(touched + 1) % 8].offset - diff);
                          Offset bBack =
                              (pointsList[(touched - 3) % 8].offset + back) / 2;
                          Offset fForward =
                              (pointsList[(touched + 3) % 8].offset + forward) /
                                  2;
                          if (back.dx > 0 &&
                              back.dx < image.width &&
                              back.dy > 0 &&
                              back.dy < image.height &&
                              click.dx > 0 &&
                              click.dx < image.width &&
                              click.dy > 0 &&
                              click.dy < image.height) {
                            pointsList.removeAt((touched - 1) % 8);
                            pointsList.insert((touched - 1) % 8,
                                DrawModel(offset: back, paint: paint));
                          }
                          if (forward.dx > 0 &&
                              forward.dx < image.width &&
                              forward.dy > 0 &&
                              forward.dy < image.height &&
                              click.dx > 0 &&
                              click.dx < image.width &&
                              click.dy > 0 &&
                              click.dy < image.height) {
                            pointsList.removeAt((touched + 1) % 8);
                            pointsList.insert((touched + 1) % 8,
                                DrawModel(offset: forward, paint: paint));
                          }
                          if (bBack.dx > 0 &&
                              bBack.dx < image.width &&
                              bBack.dy > 0 &&
                              bBack.dy < image.height &&
                              click.dx > 0 &&
                              click.dx < image.width &&
                              click.dy > 0 &&
                              click.dy < image.height) {
                            pointsList.removeAt((touched - 2) % 8);
                            pointsList.insert((touched - 2) % 8,
                                DrawModel(offset: bBack, paint: paint));
                          }
                          if (fForward.dx > 0 &&
                              fForward.dx < image.width &&
                              fForward.dy > 0 &&
                              fForward.dy < image.height &&
                              click.dx > 0 &&
                              click.dx < image.width &&
                              click.dy > 0 &&
                              click.dy < image.height) {
                            pointsList.removeAt((touched + 2) % 8);
                            pointsList.insert((touched + 2) % 8,
                                DrawModel(offset: fForward, paint: paint));
                          }
                        } else {
                          Offset back =
                              (pointsList[(touched + 6) % 8].offset + click) /
                                  2;
                          Offset forward =
                              (pointsList[(touched + 2) % 8].offset + click) /
                                  2;
                          if (back.dx > 0 &&
                              back.dx < image.width &&
                              back.dy > 0 &&
                              back.dy < image.height &&
                              click.dx > 0 &&
                              click.dx < image.width &&
                              click.dy > 0 &&
                              click.dy < image.height) {
                            pointsList.removeAt((touched + 7) % 8);
                            pointsList.insert((touched + 7) % 8,
                                DrawModel(offset: back, paint: paint));
                          }
                          if (forward.dx > 0 &&
                              forward.dx < image.width &&
                              forward.dy > 0 &&
                              forward.dy < image.height &&
                              click.dx > 0 &&
                              click.dx < image.width &&
                              click.dy > 0 &&
                              click.dy < image.height) {
                            pointsList.removeAt((touched + 1) % 8);
                            pointsList.insert((touched + 1) % 8,
                                DrawModel(offset: forward, paint: paint));
                          }
                        }
                        if (click.dx > 0 &&
                            click.dx < image.width &&
                            click.dy > 0 &&
                            click.dy < image.height) {
                          pointsList.removeAt(touched);
                          pointsList.insert(
                              touched,
                              DrawModel(
                                offset: click,
                                paint: paint,
                              ));
                        }
                      }
                    });
                  },
                  onPanEnd: (details) {
                    touched = -1;
                  },
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return new Center(child: new Text('loading'));
    }
  }

  int closestOffset(Offset click) {
    for (int i = 0; i < pointsList.length; i++) {
      if ((pointsList[i].offset - click).distance <
          (20.0 * (image.width.toDouble() / MediaQuery.of(context).size.width)))
        return i;
    }
    return -1;
  }

  Widget _iconDecider() {
    if (!edit) {
      setState(() {
        edit = true;
      });
    }
    return IconButton(
        icon: Icon(Icons.edit),
        onPressed: () async {
          setState(() {
            cropImage = true;
          });
          processPop();
        });
  }

  void processPop() async {
    for (int i = 0; i < 4; i++) {
      int index = i * 2;
      pointsList[index].offset = new Offset(
          pointsList[index].offset.dx / image.width,
          pointsList[index].offset.dy / image.height);
    }
    EdgeDetectionResult edgeDetectionResult = new EdgeDetectionResult(
        topLeft: pointsList[0].offset,
        topRight: pointsList[2].offset,
        bottomLeft: pointsList[6].offset,
        bottomRight: pointsList[4].offset);
    EdgeDetector()
        .processImage(
            widget.imageFile.path, edgeDetectionResult, rotation * 90.0 * -1)
        .then((value) {
      Uint8List ans = File(widget.imageFile.path).readAsBytesSync();
      setState(() {
        imageCache.clearLiveImages();
        imageCache.clear();
        isImageLoaded = false;
      });
      Navigator.pop(context, ans);
    });
  }

  Widget zoomRotate() {
    return BottomAppBar(
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          IconButton(
              icon: Icon(Icons.rotate_left),
              onPressed: () async {
                setState(() {
                  rotation--;
                });
              }),
          IconButton(
              icon: Icon(Icons.rotate_right),
              onPressed: () async {
                setState(() {
                  rotation++;
                });
              }),
        ],
      ),
    );
  }

  Future<ui.Image> loadImage(List<int> img) async {
    final Completer<ui.Image> completer = new Completer();
    ui.decodeImageFromList(img, (ui.Image img) {
      setState(() {
        isImageLoaded = true;
      });
      return completer.complete(img);
    });
    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Doc Scanner"),
        actions: [_iconDecider()],
      ),
      body: _buildImage(),
      bottomNavigationBar: zoomRotate(),
    );
  }
}

class MyImagePainter extends CustomPainter {
  ui.Image image;
  int height;
  final bool crop;
  final BuildContext context;
  MyImagePainter(
      {this.image, this.pointsList, this.height, this.crop, this.context});
  final List<DrawModel> pointsList;
  double angle = 1.5686;
  List<Offset> offsetList = List();
  @override
  void paint(Canvas canvas, Size size) async {
    canvas.drawImage(image, new Offset(0.0, 0.0), new Paint());
    offsetList.clear();
    for (int i = 0; i < pointsList.length; i++) {
      offsetList.add(pointsList[i].offset);
    }
    if (pointsList.length > 0 && !crop) {
      canvas.drawPoints(
          PointMode.polygon,
          offsetList,
          Paint()
            ..strokeWidth = 3.0
            ..color = Colors.white
            ..strokeCap = StrokeCap.round);
      canvas.drawLine(
          offsetList[0],
          offsetList[offsetList.length - 1],
          Paint()
            ..strokeWidth = 3.0
            ..color = Colors.white
            ..strokeCap = StrokeCap.round);

      canvas.drawPoints(
          PointMode.points,
          offsetList,
          Paint()
            ..strokeWidth = 20 * (image.height / height)
            ..strokeCap = StrokeCap.round
            ..color = Colors.red);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class DrawModel {
  Offset offset;
  Paint paint;

  DrawModel({this.offset, this.paint});
}

class EdgeDetector {
  static Future<void> startEdgeDetectionIsolate(
      EdgeDetectionInput edgeDetectionInput) async {
    EdgeDetectionResult result =
        await EdgeDetection.detectEdges(edgeDetectionInput.inputPath);
    edgeDetectionInput.sendPort.send(result);
  }

  static Future<void> processImageIsolate(
      ProcessImageInput processImageInput) async {
    EdgeDetection.processImage(processImageInput.inputPath,
        processImageInput.edgeDetectionResult, processImageInput.rotation);
    processImageInput.sendPort.send(true);
  }

  Future<EdgeDetectionResult> detectEdges(String filePath) async {
    final port = ReceivePort();

    _spawnIsolate<EdgeDetectionInput>(startEdgeDetectionIsolate,
        EdgeDetectionInput(inputPath: filePath, sendPort: port.sendPort), port);

    return await _subscribeToPort<EdgeDetectionResult>(port);
  }

  Future<bool> processImage(String filePath,
      EdgeDetectionResult edgeDetectionResult, double rot) async {
    final port = ReceivePort();

    _spawnIsolate<ProcessImageInput>(
        processImageIsolate,
        ProcessImageInput(
            inputPath: filePath,
            edgeDetectionResult: edgeDetectionResult,
            rotation: rot,
            sendPort: port.sendPort),
        port);

    return await _subscribeToPort<bool>(port);
  }

  void _spawnIsolate<T>(Function function, dynamic input, ReceivePort port) {
    Isolate.spawn<T>(function, input,
        onError: port.sendPort, onExit: port.sendPort);
  }

  Future<T> _subscribeToPort<T>(ReceivePort port) async {
    StreamSubscription sub;

    var completer = new Completer<T>();

    sub = port.listen((result) async {
      await sub?.cancel();
      completer.complete(await result);
    });

    return completer.future;
  }
}

class EdgeDetectionInput {
  EdgeDetectionInput({this.inputPath, this.sendPort});

  String inputPath;
  SendPort sendPort;
}

class ProcessImageInput {
  ProcessImageInput(
      {this.inputPath, this.edgeDetectionResult, this.rotation, this.sendPort});

  String inputPath;
  EdgeDetectionResult edgeDetectionResult;
  SendPort sendPort;
  double rotation;
}
