import 'dart:convert';
import 'package:symbol_sdk/index.dart';
import 'package:symbol_sdk/CryptoTypes.dart' as ct;
import 'package:symbol_sdk/symbol/index.dart';
import 'package:http/http.dart' as http;
import 'package:symbol_sdk/symbol/models.dart';
import 'const.dart';
import 'dart:math'as math;
import 'package:collection/collection.dart';



late String pubkey = const String.fromEnvironment("pubkey");
late String prikey = const String.fromEnvironment("prikey");
late String Address = 'TCWXK7ZZW7WGEKSJ5AOADFEXMWIZOMKFBCLALPY';

late String g1 = 'TCTK2JHDMEHFNXD4HY6KQ62UOTKM3HKTX4O7O2I';
late String g2 = 'TAFO6KT5EYOJSKIQYHZM5EN3WQDEO2YPOYQTRJA';
late String g3 = 'TCPK7KUF3DXROUZ63F2M7WBPOHDBMORG5XWOMQI';

String M_Address = Address;


List<String> NodeList_t = ['	testnet1.symbol-mikun.net', '001-sai-dual.symboltest.net','t.sakia.harvestasya.com','2.dusanjp.com'];
late String Node = '';

final String XYMID = "72C0212E67A08BCE";

NodeJson MyNode = NodeJson();

class NodeJson{
  String endpoint = "";
  int roles = 0;
}

var facade = SymbolFacade(Network.TESTNET);
NetworkType? NT = N_Now(NType_Now);

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
  return 9;
}

Future<String> Tx_Pay() async{
  var keyPair = KeyPair(ct.PrivateKey(prikey));
  var AggTx = AggregateCompleteTransactionV3(
    network: NT,
    signerPublicKey: PublicKey(keyPair.publicKey.bytes),
    deadline: Timestamp(facade.network.fromDatetime(DateTime.now().toUtc()).addHours(2).timestamp),
  );
  Tx_Readables.forEach((tx){
    List<UnresolvedMosaic> mos = [];
    tx.Mosaics.forEach((mo){
      mos.add(
          UnresolvedMosaic(
            mosaicId: UnresolvedMosaicId(mo.Id),
            amount: Amount(mo.Amount)
          )
      );
    });
    var inner1 = EmbeddedTransferTransactionV1(
      network: NT,
      recipientAddress : UnresolvedAddress(tx.Address),
      signerPublicKey: PublicKey(keyPair.publicKey.bytes),
      mosaics: mos,
    );
    if(tx.Message != ""){
      inner1.message = MessageEncorder.toPlainMessage(tx.Message);
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

