import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
// import 'package:documentscanner2/Providers/documentProvider.dart';
// import 'package:documentscanner2/Search.dart';
// import 'package:documentscanner2/drawer.dart';
// import 'package:documentscanner2/pdfScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app_docscanner/Providers/documentProvider.dart';
import 'package:flutter_app_docscanner/Search.dart';
import 'package:flutter_app_docscanner/drawer.dart';
import 'package:flutter_app_docscanner/pdfScreen.dart';
import 'package:flutter_full_pdf_viewer/full_pdf_viewer_scaffold.dart';
import 'package:flutter_share/flutter_share.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

import 'Model/documentModel.dart';
import 'NewImage.dart';



class Body extends StatefulWidget {
  final String pdfPath;
  Body({this.pdfPath});

  @override
  _MyBodyState createState() => _MyBodyState();
}

class _MyBodyState extends State<Body> {
  final String userName = Random().nextInt(10000).toString();
  final Strategy strategy = Strategy.P2P_STAR;

  String cId = "0"; //currently connected device ID
  File tempFile; //reference to the file currently being transferred
  Map<int, String> map =
  Map(); //store filename mapped to corresponding payloadId

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeData.dark().backgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListView(
            children: <Widget>[
              Text(
                "Permissions",
              ),
              Wrap(
                children: <Widget>[
                  RaisedButton(
                    child: Text("checkLocationPermission"),
                    onPressed: () async {
                      if (await Nearby().checkLocationPermission()) {
                        // Scaffold.of(context).showSnackBar(SnackBar(
                        //     content: Text("Location permissions granted :)")));
                        showSnackbar("Location permissions granted :)");
                      } else {
                        // Scaffold.of(context).showSnackBar(SnackBar(
                        //     content:
                        //     Text("Location permissions not granted :(")));
                        showSnackbar("Location permissions not granted :(");
                      }
                    },
                  ),
                  RaisedButton(
                    child: Text("askLocationPermission"),
                    onPressed: () async {
                      if (await Nearby().askLocationPermission()) {
                        // Scaffold.of(context).showSnackBar(SnackBar(
                        //     content: Text("Location Permission granted :)")));
                        showSnackbar("Location Permission granted :)");
                      } else {
                        // Scaffold.of(context).showSnackBar(SnackBar(
                        //     content:
                        //     Text("Location permissions not granted :(")));
                        showSnackbar("Location permissions not granted :(");
                      }
                    },
                  ),
                  RaisedButton(
                    child: Text("checkExternalStoragePermission"),
                    onPressed: () async {
                      if (await Nearby().checkExternalStoragePermission()) {
                        // Scaffold.of(context).showSnackBar(SnackBar(
                        //     content:
                        //     Text("External Storage permissions granted :)")));
                        showSnackbar("External Storage permissions granted :)");
                      } else {
                        // Scaffold.of(context).showSnackBar(SnackBar(
                        //     content: Text(
                        //         "External Storage permissions not granted :(")));
                        showSnackbar("External Storage permissions not granted :(");
                      }
                    },
                  ),
                  RaisedButton(
                    child: Text("askExternalStoragePermission"),
                    onPressed: () {
                      Nearby().askExternalStoragePermission();
                    },
                  ),
                ],
              ),
              Divider(),
              Text("Location Enabled"),
              Wrap(
                children: <Widget>[
                  RaisedButton(
                    child: Text("checkLocationEnabled"),
                    onPressed: () async {
                      if (await Nearby().checkLocationEnabled()) {
                        // Scaffold.of(context).showSnackBar(
                        //     SnackBar(content: Text("Location is ON :)")));
                        showSnackbar("Location is ON :)");
                      } else {
                        // Scaffold.of(context).showSnackBar(
                        //     SnackBar(content: Text("Location is OFF :(")));
                        showSnackbar("Location is OFF :(");
                      }
                    },
                  ),
                  RaisedButton(
                    child: Text("enableLocationServices"),
                    onPressed: () async {
                      if (await Nearby().enableLocationServices()) {
                        showSnackbar("Location Service Enabled :)");
                      } else {
                        showSnackbar("Enabling Location Service Failed :(");
                      }
                    },
                  ),
                ],
              ),
              Divider(),
              Text("User Name: " + userName),
              Wrap(
                children: <Widget>[
                  RaisedButton(
                    child: Text("Start Advertising"),
                    onPressed: () async {
                      try {
                        bool a = await Nearby().startAdvertising(
                          userName,
                          strategy,
                          onConnectionInitiated: onConnectionInit,
                          onConnectionResult: (id, status) {
                            showSnackbar(status);
                          },
                          onDisconnected: (id) {
                            showSnackbar("Disconnected: " + id);
                          },
                        );
                        showSnackbar("ADVERTISING: " + a.toString());
                      } catch (exception) {
                        showSnackbar(exception);
                      }
                    },
                  ),
                  RaisedButton(
                    child: Text("Stop Advertising"),
                    onPressed: () async {
                      await Nearby().stopAdvertising();
                    },
                  ),
                ],
              ),
              Wrap(
                children: <Widget>[
                  RaisedButton(
                    child: Text("Start Discovery"),
                    onPressed: () async {
                      try {
                        bool a = await Nearby().startDiscovery(
                          userName,
                          strategy,
                          onEndpointFound: (id, name, serviceId) {
                            // show sheet automatically to request connection
                            showModalBottomSheet(
                              context: context,
                              builder: (builder) {
                                return Center(
                                  child: Column(
                                    children: <Widget>[
                                      Text("id: " + id),
                                      Text("Name: " + name),
                                      Text("ServiceId: " + serviceId),
                                      RaisedButton(
                                        child: Text("Request Connection"),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          Nearby().requestConnection(
                                            userName,
                                            id,
                                            onConnectionInitiated: (id, info) {
                                              onConnectionInit(id, info);
                                            },
                                            onConnectionResult: (id, status) {
                                              showSnackbar(status);
                                            },
                                            onDisconnected: (id) {
                                              showSnackbar(id);
                                            },
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          onEndpointLost: (id) {
                            showSnackbar("Lost Endpoint:" + id);
                          },
                        );
                        showSnackbar("DISCOVERING: " + a.toString());
                      } catch (e) {
                        showSnackbar(e);
                      }
                    },
                  ),
                  RaisedButton(
                    child: Text("Stop Discovery"),
                    onPressed: () async {
                      await Nearby().stopDiscovery();
                    },
                  ),
                ],
              ),
              RaisedButton(
                child: Text("Stop All Endpoints"),
                onPressed: () async {
                  await Nearby().stopAllEndpoints();
                },
              ),
              Divider(),
              Text(
                "Sending Data",
              ),
              RaisedButton(
                child: Text("Send Random Bytes Payload"),
                onPressed: () async {
                  String a = Random().nextInt(100).toString();
                  showSnackbar("Sending $a to $cId");
                  Nearby().sendBytesPayload(cId, Uint8List.fromList(a.codeUnits));
                },
              ),
              RaisedButton(
                child: Text("Send File Payload"),
                onPressed: () async {
                  File file = File(widget.pdfPath);
                  // await ImagePicker.pickImage(source: ImageSource.gallery);

                  if (file == null) return;

                  int payloadId = await Nearby().sendFilePayload(cId, file.path);
                  showSnackbar("Sending file to $cId");
                  Nearby().sendBytesPayload(
                      cId,
                      Uint8List.fromList(
                          "$payloadId:${file.path.split('/').last}".codeUnits));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Called upon Connection request (on both devices)
  /// Both need to accept connection to start sending/receiving
  void onConnectionInit(String id, ConnectionInfo info) {
    showModalBottomSheet(
      context: context,
      builder: (builder) {
        return Center(
          child: Column(
            children: <Widget>[
              Text("id: " + id),
              Text("Token: " + info.authenticationToken),
              Text("Name" + info.endpointName),
              Text("Incoming: " + info.isIncomingConnection.toString()),
              RaisedButton(
                child: Text("Accept Connection"),
                onPressed: () {
                  Navigator.pop(context);
                  cId = id;
                  Nearby().acceptConnection(
                    id,
                    onPayLoadRecieved: (endid, payload) async {
                      if (payload.type == PayloadType.BYTES) {
                        String str = String.fromCharCodes(payload.bytes);
                        showSnackbar(endid + ": " + str);

                        if (str.contains(':')) {
                          // used for file payload as file payload is mapped as
                          // payloadId:filename
                          int payloadId = int.parse(str.split(':')[0]);
                          String fileName = (str.split(':')[1]);

                          if (map.containsKey(payloadId)) {
                            if (await tempFile.exists()) {
                              tempFile.rename(
                                  tempFile.parent.path + "/" + fileName);
                            } else {
                              showSnackbar("File doesnt exist");
                            }
                          } else {
                            //add to map if not already
                            map[payloadId] = fileName;
                          }
                        }
                      } else if (payload.type == PayloadType.FILE) {
                        showSnackbar(endid + ": File transfer started");
                        tempFile = File(payload.filePath);
                      }
                    },
                    onPayloadTransferUpdate: (endid, payloadTransferUpdate) {
                      if (payloadTransferUpdate.status ==
                          PayloadStatus.IN_PROGRRESS) {
                        print(payloadTransferUpdate.bytesTransferred);
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.FAILURE) {
                        print("failed");
                        showSnackbar(endid + ": FAILED to transfer file");
                      } else if (payloadTransferUpdate.status ==
                          PayloadStatus.SUCCESS) {
                        showSnackbar(
                            "success, total bytes = ${payloadTransferUpdate.totalBytes}");

                        if (map.containsKey(payloadTransferUpdate.id)) {
                          //rename the file now
                          String name = map[payloadTransferUpdate.id];
                          tempFile.rename(tempFile.parent.path + "/" + name);
                        } else {
                          //bytes not received till yet
                          map[payloadTransferUpdate.id] = "";
                        }
                      }
                    },
                  );
                },
              ),
              RaisedButton(
                child: Text("Reject Connection"),
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await Nearby().rejectConnection(id);
                  } catch (e) {
                    showSnackbar(e);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}


void showSnackbar(dynamic a) {
  print(a.toString());
  Fluttertoast.showToast(
    msg: "${a.toString()}",
    backgroundColor: Colors.grey,
  );
}
class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  MethodChannel channel = MethodChannel('opencv');
  File _file;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  static GlobalKey<AnimatedListState> animatedListKey =
      GlobalKey<AnimatedListState>();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: SafeArea(
          child: Drawer(
        child: DocDrawer(),
      )),
      appBar: AppBar(
        title: Text("Doc Scan"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () async {
              showSearch(context: context, delegate: Search());
            },
          ),
          IconButton(
            icon: Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: () {},
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.camera),
                onPressed: () async {
                  chooseImage(ImageSource.camera);
                },
              ),
              Container(
                color: Colors.white.withOpacity(0.2),
                width: 2,
                height: 15,
              ),
              IconButton(
                icon: Icon(Icons.image),
                onPressed: () async {
                  chooseImage(ImageSource.gallery);
                },
              )
            ],
          )),
      body: FutureBuilder(
        future: getAllDocuments(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            print("has not data");
            return CircularProgressIndicator();
          }
          if (snapshot.hasError) {
            print("error");
            return CircularProgressIndicator();
          }
          return Container(
              height: MediaQuery.of(context).size.height - 81,
              child: AnimatedList(
                key: animatedListKey,
                itemBuilder: (context, index, animation) {
                  if (index ==
                      Provider.of<DocumentProvider>(context)
                              .allDocuments
                              .length -
                          1) {
                    print("last");
                    return SizedBox(height: 100);
                  }
                  return buildDocumentCard(index, animation);
                },
                initialItemCount:
                    Provider.of<DocumentProvider>(context).allDocuments.length,
              ));
        },
      ),
    );
  }

  void chooseImage(ImageSource source) async {
    File fileGallery = await ImagePicker.pickImage(source: source);
    if (fileGallery != null) {
      _file = fileGallery;
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => NewImage(fileGallery, animatedListKey)));
    }
  }

  void permissionTaker() async {
    if (await Nearby().checkLocationPermission()) {
    } else {
      Nearby().askLocationAndExternalStoragePermission();
    }
    if (await Nearby().checkExternalStoragePermission()) {
    } else {
      Nearby().askLocationAndExternalStoragePermission();
    }
    if (await Nearby().checkLocationEnabled()) {
    } else {
      Nearby().enableLocationServices();
    }
  }

  Future<bool> getAllDocuments() async {
    print("inside get documents");
    return await Provider.of<DocumentProvider>(context, listen: false)
        .getDocuments();
  }

  Future<void> onRefresh() async {
    print("refreshed");
    Provider.of<DocumentProvider>(context, listen: false).getDocuments();
  }

  Widget buildDocumentCard(int index, Animation animation) {
    return SizeTransition(
      sizeFactor: animation,
      child: StatefulBuilder(
        builder: (context, setState) => GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => PDFScreen(
                document:
                    Provider.of<DocumentProvider>(context).allDocuments[index],
                animatedListKey: animatedListKey,
              ),
            ));
          },
          child: Card(
            color: ThemeData.dark().cardColor,
            elevation: 3,
            margin: EdgeInsets.only(left: 12, right: 12, bottom: 5, top: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(left: 12, top: 12, right: 12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(
                          left: BorderSide(color: Colors.grey[300]),
                          right: BorderSide(color: Colors.grey[300]),
                          top: BorderSide(color: Colors.grey[300])),
                    ),
                    child: Image.file(
                      new File(Provider.of<DocumentProvider>(context)
                          .allDocuments[index]
                          .documentPath),
                      height: 150,
                      width: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                        child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 150,
                          padding: EdgeInsets.all(12),
                          child: Text(
                            Provider.of<DocumentProvider>(context)
                                .allDocuments[index]
                                .name,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                            padding: EdgeInsets.only(left: 12),
                            child: Text(
                              Provider.of<DocumentProvider>(context)
                                      .allDocuments[index]
                                      .dateTime
                                      .day
                                      .toString() +
                                  "-" +
                                  Provider.of<DocumentProvider>(context)
                                      .allDocuments[index]
                                      .dateTime
                                      .month
                                      .toString() +
                                  "-" +
                                  Provider.of<DocumentProvider>(context)
                                      .allDocuments[index]
                                      .dateTime
                                      .year
                                      .toString(),
                              style: TextStyle(color: Colors.grey[400]),
                            )),
                      ],
                    )),
                    SizedBox(
                      height: 60,
                    ),
                    Container(
                        width: MediaQuery.of(context).size.width - 180,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            IconButton(
                                icon: Icon(Icons.share,color: ThemeData.dark().accentColor,),
                                onPressed: () {
                                  shareDocument(Provider.of<DocumentProvider>(
                                          context,
                                          listen: false)
                                      .allDocuments[index]
                                      .pdfPath);
                                }),
                            IconButton(icon: Icon(Icons.wifi,color: ThemeData.dark().accentColor,), onPressed: (){
                              // permissionTaker();
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>Body(pdfPath: Provider.of<DocumentProvider>(
                                  context,
                                  listen: false)
                                  .allDocuments[index]
                                  .pdfPath,)));
                            }),
                            IconButton(
                                icon: Icon(Icons.more_vert,color: ThemeData.dark().accentColor,),
                                onPressed: () {
                                  showModalSheet(
                                      index: index,
                                      filePath: Provider.of<DocumentProvider>(
                                              context,
                                              listen: false)
                                          .allDocuments[index]
                                          .documentPath,
                                      dateTime: Provider.of<DocumentProvider>(
                                              context,
                                              listen: false)
                                          .allDocuments[index]
                                          .dateTime,
                                      name: Provider.of<DocumentProvider>(
                                              context,
                                              listen: false)
                                          .allDocuments[index]
                                          .name,
                                      pdfPath: Provider.of<DocumentProvider>(
                                              context,
                                              listen: false)
                                          .allDocuments[index]
                                          .pdfPath);
                                })
                          ],
                        ))
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void shareDocument(String pdfPath) async {
    await FlutterShare.shareFile(title: "pdf", filePath: pdfPath);
  }

  void showModalSheet(
      {int index,
      String filePath,
      String name,
      DateTime dateTime,
      String pdfPath}) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 20, top: 15),
                    child: Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300])),
                      child: Image.file(
                        new File(filePath),
                        height: 80,
                        width: 50,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Container(
                        width: 150,
                        padding: EdgeInsets.only(left: 12, bottom: 12),
                        child: Text(
                          name,
                          style: TextStyle(color: Colors.black, fontSize: 18),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                          padding: EdgeInsets.only(left: 12),
                          child: Text(
                            dateTime.day.toString() +
                                "-" +
                                dateTime.month.toString() +
                                "-" +
                                dateTime.year.toString(),
                            style: TextStyle(color: Colors.grey[400]),
                          )),
                    ],
                  )
                ],
              ),
              Divider(
                thickness: 2,
              ),
              ListTile(
                leading: Icon(Icons.edit),
                title: Text("Rename"),
                onTap: () {
                  Navigator.pop(context);
                  showRenameDialog(
                      index: index, name: name, dateTime: dateTime);
                },
              ),
              ListTile(
                leading: Icon(Icons.print),
                title: Text("Print"),
                onTap: () async {
                  Navigator.pop(context);
                  final pdf = File(pdfPath);
                  await Printing.layoutPdf(
                      onLayout: (_) => pdf.readAsBytesSync());
                },
              ),
              ListTile(
                leading: Icon(Icons.delete),
                title: Text("Delete"),
                onTap: () {
                  Navigator.pop(context);
                  showDeleteDialog1(index: index, dateTime: dateTime);
                },
              )
            ],
          ),
        );
      },
    );
  }

  void showDeleteDialog1({int index, DateTime dateTime}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Container(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              "Delete file",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Divider(
              thickness: 2,
            ),
            Text(
              "Are you sure you want to delete this file?",
              style: TextStyle(color: Colors.grey[500]),
            )
          ],
        )),
        actions: <Widget>[
          OutlineButton(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.black),
            ),
          ),
          OutlineButton(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () {
              Navigator.of(context).pop();

              Provider.of<DocumentProvider>(context, listen: false)
                  .deleteDocument(
                      index, dateTime.millisecondsSinceEpoch.toString());
              Timer(Duration(milliseconds: 300), () {
                animatedListKey.currentState.removeItem(
                    index,
                    (context, animation) =>
                        buildDocumentCard(index, animation));
              });
            },
            child: Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          )
        ],
      ),
    );
  }

  void showRenameDialog({int index, DateTime dateTime, String name}) {
    TextEditingController controller = TextEditingController();
    controller.text = name;
    controller.selection =
        TextSelection(baseOffset: 0, extentOffset: controller.text.length);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Container(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text("Rename"),
            TextFormField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                  suffix: IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                      })),
            ),
          ],
        )),
        actions: <Widget>[
          OutlineButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel")),
          OutlineButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              onPressed: () {
                Navigator.of(context).pop();
                Provider.of<DocumentProvider>(context, listen: false)
                    .renameDocument(
                        index,
                        dateTime.millisecondsSinceEpoch.toString(),
                        controller.text);
              },
              child: Text("Rename")),
        ],
      ),
    );
  }
}
