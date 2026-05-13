import 'dart:convert';
import 'package:symbol_sdk/index.dart';
import 'package:symbol_sdk/CryptoTypes.dart' as ct;
import 'package:symbol_sdk/symbol/index.dart' hide Address;
import 'package:http/http.dart' as http;
import 'package:symbol_sdk/symbol/models.dart' hide Address;
import 'dart:math'as math;
import 'const.dart';


String M_Address = Address;

late String Node = '';


NodeJson MyNode = NodeJson();

class NodeJson{
  String endpoint = "";
  int roles = 0;
}

NetworkType NT_Now(String NT){
  switch (NT){
    case "test":
      return NetworkType.TESTNET;
    case "main":
      return NetworkType.MAINNET;
    default:
      return NetworkType.MAINNET;
  }
}

Network N_Now(String NT){
  switch (NT){
    case "test":
      return Network.TESTNET;
    case "main":
      return Network.MAINNET;
    default:
      return Network.MAINNET;
  }
}


class Account_amount{
  late List<Mosaics_Mine> mosaics = [];

  Account_amount({required this.mosaics});

  Account_amount.fromJson(Map<String,dynamic> json){
    json['mosaics']?.forEach((element) {
      mosaics.add(Mosaics_Mine.fromJson(element));
    });
  }
}

class Mosaic_data{
  late String Id;
  late int div;

  Mosaic_data({required this.Id, required this.div});

  Mosaic_data.fromJson(Map<String,dynamic> json){
    Id = json['id'];
    div = json['divisibility'];
  }
}



class Mosaics_Mine{
  late String id;
  late double amount;
  Mosaics_Mine({required this.id, required this.amount});

  Mosaics_Mine.fromJson(Map<String,dynamic> json){
    id = json['id'];
    amount = double.tryParse(json['amount'])!;
  }

}

Future<void> setNode_Test() async {
  final client = http.Client();
  String Node = "";
  do {
    int num = math.Random().nextInt(NodeList_t.length);
    Node = 'https://${NodeList_t[num]}:3001';
    String url = '$Node/node/health';
    try{
      final response = await client.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        MyNode.endpoint = NodeList_t[num];
        return;
      }else{
        NodeList_t.removeAt(num);
        if (NodeList_t.isEmpty) {
          Node = '';
        }
      }
    }catch(e){
      print(e);
      NodeList_t.removeAt(num);
      if (NodeList_t.isEmpty) {
        return;
      }
    }
  }while(Node != '');
}
Future<String> GetDataFromAPI(String Address)async{
  // HTTPリクエストを送信してレスポンスを取得
  var response = await http.get(Uri.parse('https://${MyNode.endpoint}:3001/accounts/$Address'));
  if (response.statusCode == 200) {
    // レスポンスの文字列を返す
    return response.body;
  } else {
    // レスポンスが失敗した場合はエラーをスローするなどの処理を行う
    print('APIからのデータの取得に失敗しました: ${response.statusCode}');
    return '';
  }
}

Future<String> GetDataFromAPI_Mosaic(String Id)async{
  // HTTPリクエストを送信してレスポンスを取得
  var response = await http.get(Uri.parse('https://${MyNode.endpoint}:3001/mosaics/$Id'));
  if (response.statusCode == 200) {
    // レスポンスの文字列を返す
    return response.body;
  } else {
    // レスポンスが失敗した場合はエラーをスローするなどの処理を行う
    print('APIからのデータの取得に失敗しました: ${response.statusCode}');
    return '';
  }
}

Future<double> setXYM(String Address) async{
  const JsonDecoder decoder = JsonDecoder();
  if(Address.isNotEmpty){
    String Datastring = await GetDataFromAPI(Address);
    if(Datastring == ''){
      print('Nothing');
    }else {
      Map<String,dynamic> Jdata = decoder.convert(Datastring);
      Account_amount Ac = Account_amount.fromJson(Jdata['account']);
      for (var element in Ac.mosaics) {
        if(element.id == XYMID) {
          var amount = element.amount * math.pow(10, -6);
          return amount;
        }
      }
    }
  }
  return 0.0;
}

Future<int> setdiv(String Id) async{
  const JsonDecoder decoder = JsonDecoder();
  if(Id.isNotEmpty){
    String Datastring = await GetDataFromAPI_Mosaic(Id);
    if(Datastring == ''){
      print('Nothing');
    }else {
      Map<String,dynamic> Jdata = decoder.convert(Datastring);
      Mosaic_data Mo = Mosaic_data.fromJson(Jdata['mosaic']);
      if(Mo.Id == Id) {
        return Mo.div;
      }
    }
  }
  throw new Exception("Wrong Id :${Id}");
}


//This time, only use transfer.
Future<String> Tx_Pay(Map<String, dynamic> build_tx) async{
  var keyPair = KeyPair(ct.PrivateKey(prikey));
  var facade = SymbolFacade(N_Now(build_tx["Network"]));
  var AggTx = AggregateCompleteTransactionV3(
    network: NT_Now(build_tx["Network"]),
    signerPublicKey: PublicKey(keyPair.publicKey.bytes),
    deadline: Timestamp(facade.network.fromDatetime(DateTime.now().toUtc()).addHours(2).timestamp),
  );
  build_tx["Transaction"].forEach((tx){
    List<UnresolvedMosaic> mos = [];
    tx["Mosaics"].forEach((mo){
      mos.add(
          UnresolvedMosaic(
            mosaicId: UnresolvedMosaicId(mo["Id"]),
            amount: Amount(BigInt.parse(mo["Amount"]))
          )
      );
    });
    //tx[“Action”] fits this description, but I can't think of a good way to write it,
    // and the intermediate representation changes depending on the tx["Action"].
    var inner1 = EmbeddedTransferTransactionV1(
      network: NT_Now(build_tx["Network"]),
      recipientAddress : UnresolvedAddress(tx["Address"]),
      signerPublicKey: PublicKey(keyPair.publicKey.bytes),
      mosaics: mos,
    );
    if(tx["Message"] != ""){
      inner1.message = MessageEncorder.toPlainMessage(tx["Message"]);
    }
    AggTx.transactions.add(inner1);
  });
  AggTx.fee = Amount((AggTx.size + 1 * 104) * 100);
  var markleHash = SymbolFacade.hashEmbeddedTransactions(AggTx.transactions);
  AggTx.transactionsHash = Hash256(markleHash.bytes);
  var signature = facade.signTransaction(keyPair, AggTx);
  var payload = facade.attachSignature(AggTx, signature);
  print(payload);
  try{
    http.put(
        Uri.parse('https://${MyNode.endpoint}:3001/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: payload
    ).then((response){
      print(response.body);
    });
    return 'Success';
  }catch(e){
    print(e);
    return 'Transaction Error';
  }finally{
  }
}

