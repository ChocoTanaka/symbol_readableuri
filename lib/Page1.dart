import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'Symbol.dart';
import 'const.dart';

class Page1 extends StatefulWidget {
  const Page1({super.key, required this.title});


  final String title;

  @override
  State<Page1> createState() => _Page1state();
}

class _Page1state extends State<Page1> {
  final TextEditingController amountController = TextEditingController();
  final TextEditingController amountController_Mosaic1 = TextEditingController();
  final TextEditingController IdController_Mosaic1 = TextEditingController();
  String? generatedUri;
  String amount = "";
  String amountmosaic1 = "";
  String idmosaic1 = "";
  bool isShow = false;

  int XYMDIV = 6;


  @override
  void initState(){
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String maskMiddle(String text, {int head = 6, int tail = 6}) {
    if (text.length <= head + tail) {
      return text; // 短すぎる場合はそのまま
    }
    return text.substring(0, head) +
        '...' +
        text.substring(text.length - tail);
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
            child:Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  children: [
                    Text(
                      "Address:",
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 10),
                    Text(
                        maskMiddle(M_Address, head: 6, tail: 6),
                      style: const TextStyle(fontSize: 22),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: amountController,
                        onChanged: (text)=> setState(() {
                          amount =amountController.text;
                        }),
                        decoration: const InputDecoration(
                          labelText: 'Amount (XYM)',
                          border: UnderlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "XYM",
                      style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                          color: Colors.black
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: amountController_Mosaic1,
                        onChanged: (text)=> setState(() {
                          amountmosaic1 =amountController_Mosaic1.text;
                        }),
                        decoration: const InputDecoration(
                          labelText: 'Amount',
                          border: UnderlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        style: TextStyle(
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: TextFormField(
                        controller: IdController_Mosaic1,
                        onChanged: (text)=> setState(() {
                          idmosaic1 =IdController_Mosaic1.text;
                        }),
                        decoration: const InputDecoration(
                          labelText: 'Id',
                          border: UnderlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        keyboardType: TextInputType.text,
                        style: TextStyle(
                          fontSize: 22,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black, width: 2), // 黒い枠線
                  ),
                  child: isShow == false
                      ? SizedBox(
                    width: 250,
                    height: 250,
                  )
                      : QrImageView(
                    data: generatedUri!,
                    size: 240,
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  width: 300,
                  height:75,
                  child: ElevatedButton(
                      onPressed:() async{
                        List<Mosaic> Mosaics = [];
                        try{
                          if(amount !='' || amount !='0'){
                            BigInt inputAmount = toBigInt(amount, XYMDIV);
                            Mosaics.add(Mosaic.fromParams(id: XYMID, amount: inputAmount, div: XYMDIV));
                          }
                          if(amountmosaic1 != ''|| amount !='0'){
                            int div = await setdiv(idmosaic1);
                            if(div == 9){
                              throw new Exception("Wrong Id :${idmosaic1}");
                            }else{
                              BigInt inputAmount = toBigInt(amountmosaic1, div);
                              Mosaics.add(Mosaic.fromParams(id: idmosaic1, amount: inputAmount, div: div));
                            }
                          }
                        }catch(e){
                          print(e.toString());
                        }
                        if(Mosaics.length>0){
                          setState(() {
                            final uri =
                            makeuri(M_Address, parseNetwork_s(NType_Now), Mosaics);
                            print(uri);
                            generatedUri = uri;
                            isShow = !isShow;
                          });
                        }
                      },
                      child: Text(
                        isShow ? "RESET" : "SET",
                        style: TextStyle(
                            fontSize: 30,
                            color: Colors.black
                        ),
                      )
                  ),
                )
              ],
            )
        ),
    );
  }
}
