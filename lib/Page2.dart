import 'dart:io';
import 'main.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:symbol_readableuri/Symbol.dart';
import 'const.dart';

class Page2 extends StatefulWidget {
  const Page2({super.key, required this.title});


  final String title;

  @override
  State<Page2> createState() => _Page2state();
}

class _Page2state extends State<Page2> {
  bool isCam = true;
  String Text_Error="";
  String Read_Text = "";
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;



  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  void _onQRViewCreated(QRViewController controller){
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async{
      if(isCam ==true){
        setState(() {
          isCam=false;
          Read_Text = "Now reading Tx...";
        });
        result = scanData;
        print(result!.code);
        setState(() {
          if(validateRawUri(result!.code!,NType_Now) != null){
            Text_Error = errorMessage(validateRawUri(result!.code!,NType_Now)!);
          }else{
            AddList(result!.code!);
            Text_Error = "";
          }
        });
        await Future.delayed(const Duration(milliseconds: 1500));
        setState(() {
          isCam = true;
        });
      }
    });
  }
  
  Widget Mo_Text(Mosaic mo){
    return Column(
      children: <Widget>[
        Text(
          "Mosaic:",
          style: TextStyle(
            fontSize: 20.0,
          ),
        ),
        Text(
          mo.Id != XYMID ? "XYM" : mo.Id,
          style: TextStyle(
            fontSize: 20.0,
          ),
        ),
        Text(
          mo.toDisplay(),
          style: TextStyle(
            fontSize: 20.0,
          ),
        ),
      ],
    );
  }

  Widget Listview_Tx(int i, Tx_Readable Tx){
    final TextEditingController messageController = TextEditingController();
    return Container(
      width: 300,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.black // 枠線の色を設定
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: <Widget>[
          Text(
            "Tx ${i+1}",
            style: TextStyle(
              fontSize: 20.0,
            ),
          ),
          Text(
            "Address: ${Tx.Address}",
            style: TextStyle(
              fontSize: 20.0,
            ),
            overflow: TextOverflow.ellipsis, // 長いテキストを省略
          ),
          for(var mo in Tx.Mosaics)
            Mo_Text(mo),
          Row(
            children: <Widget>[
              Text(
                "Message:",
                style: TextStyle(
                  fontSize: 20.0,
                ),
              ),
              Expanded(
                  child: Container(
                    constraints:
                      BoxConstraints(minWidth: double.infinity),
                    child: TextFormField(
                      controller: messageController,
                      onChanged: (text)=> setState(() {
                        Tx.Message =messageController.text;
                      }),
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                  ),
              ),
            ],
          ),
          SizedBox(
            height: 10,
          )
        ],
      ),
    );
  }

  Future<void> CheckTx(BuildContext context) async {
    await showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('署名確認'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
              itemCount: Tx_Readables.length,
              itemBuilder:((context, index){
                return Listview_Tx(index, Tx_Readables[index]);
              })
          ),
      ),
        actions: <Widget>[
          GestureDetector(
            child: const Text(
                '署名しない',
              style: TextStyle(
                fontSize: 24,
              ),
            ),
            onTap: () {
              Tx_Readables.clear();
              Navigator.pop(context);
            },
          ),
          GestureDetector(
            child: const Text(
                '署名する',
              style: TextStyle(
                fontSize: 24,
              ),
            ),
            onTap: () async {
              late String Result = '';
              Navigator.pop(context);
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const AlertDialog(
                    title: Text('トランザクション処理中'),
                  );
                },
              );
              await await Tx_Pay().then((value) {
                Result = value;
              });
              print(Result);
              Navigator.pop(context);
              if (Result == 'Success') {
                Alert_num(context, Result, 'トランザクションを実行しました');
              } else {
                Alert_num(context, Result, 'トランザクションが失敗しました');
              }
            },
          )
        ],
      );
    });
  }

  void Alert_num(BuildContext context, String title, String content) {
    showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            GestureDetector(
              child: const Text('分かりました'),
              onTap: () {
                Tx_Readables.clear();
                Navigator.pop(context);
              },
            ),
          ]
      );
    },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(

        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

        title: Text(widget.title),
      ),
      body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Text(
                Text_Error,
                style: TextStyle(
                  fontSize: 22.0,
                  color: Colors.greenAccent[100]
                ),
              ),
              const Padding(padding: EdgeInsets.all(10)),
              isCam==false ?
                  SizedBox(
                    height:300,
                    width:300,
                    child: Center(
                      child:Text(
                        Read_Text,
                        style: TextStyle(
                          fontSize: 26.0,
                        ),
                      ),
                    )
                  )
                  :
                  SizedBox(
                    height:300,
                    width:300,
                    child: QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                    ),
                  ),
              const Padding(padding: EdgeInsets.all(10)),
              Text(
                  "請求書を読み取ってください" +"\n"
                  +"tx:" + ReadableList.length.toString(),
                style: TextStyle(
                  fontSize: 24.0,
                ),
              ),
            ],
          )
      ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if(ReadableList.isNotEmpty){
              setState(() {
                Text_Error = "";
                isCam=false;
                Read_Text = "Check Phase...";
              });
              ReadableList.forEach((uri){
                print(uri);
                read_URI(uri);
              });
              setState(() {
                ReadableList.clear();
              });
              Tx_Readables.forEach((tx){
                tx.Show();
              });
              CheckTx(context).then((result) async{
                await Future.delayed(const Duration(milliseconds: 1500));
                setState(() {
                  isCam=true;
                  Read_Text = "";
                });
              });
            }
          },
          child: const Icon(Icons.mail),
          backgroundColor: ReadableList.isNotEmpty ? Colors.blue : Colors.grey[200],
        ),
    );
  }
}