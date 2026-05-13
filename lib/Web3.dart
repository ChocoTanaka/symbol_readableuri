import 'const.dart';

enum UriCheckError {
  notSymbolUri,
  differentNetwork,
  invalidFormat,
  doubling,
}

String errorMessage(UriCheckError e) {
  switch (e) {
    case UriCheckError.notSymbolUri:
      return 'Symbolの請求書ではありません';
    case UriCheckError.differentNetwork:
      return 'ネットワークが違います';
    case UriCheckError.invalidFormat:
      return 'URI形式が不正です';
    case UriCheckError.doubling:
      return '重複しています';
  }
}

BigInt toBigInt(String input, int div) {
  String normalized = input.replaceAll('.', '');
  int decimals = input.contains('.') ? input.split('.')[1].length : 0;
  int zerosToAdd = div - decimals;
  for (int i = 0; i < zerosToAdd; i++) {
    normalized += '0';
  }
  return BigInt.parse(normalized);
}



final action_Now = "transfer";

//Mosaic
class Mosaic{
  late String Id;
  late BigInt Amount;
  late int Div;

  Mosaic._internal({required this.Id, required this.Amount, required this.Div});

  String toDisplay() {
    final s = Amount.toString().padLeft(Div + 1, '0');

    var integer = s.substring(0, s.length - Div);
    var decimal = s.substring(s.length - Div);

    decimal = decimal.replaceFirst(RegExp(r'0+$'), '');

    integer = integer.replaceFirst(RegExp(r'^0+'), '');
    if (integer.isEmpty) integer = '0';

    return decimal.isEmpty ? integer : '$integer.$decimal';
  }

  factory Mosaic.fromParams({
    required String id,
    required BigInt amount,
    required int div,
  }) {
    return Mosaic._internal(
      Id: id,
      Amount: amount,
      Div: div,
    );
  }

  //<String, String> is the best.
  Map<String, dynamic> toTransactionData({
    required String id,
    required BigInt amount,
  }) {
    return{
      "Id": id,
      "Amount": amount.toString(),
    };
  }

  void Show(){
    print(
      '-----' + '\n'
        +'Mosaic:' + '\n'
        +'id:${this.Id}' + '\n'
        +'Amount:${toDisplay()}' + '\n'
      +'-----' + '\n'
    );
  }
}

//Class Tx(for making intermediate representation)
//Ideally, Tx should inherit from the Abstract Class.
class Tx_Readable{
  late String Address;
  late List<Mosaic> Mosaics=[];
  late String Message = "";
  late String Network ="";
  late String Action = "";

  Tx_Readable(String address,List<Mosaic> mos, String network, String action){
    this.Address = address;
    for(int i = 0; i<mos.length; i++){
      this.Mosaics.add(mos[i]);
    }
    this.Network = network;
    this.Action = action;
  }

  void Show(){
    print(
      "Address:${this.Address}"+"\n"
    );
    Mosaics.forEach((mosaic){
      mosaic.Show();
    });
    print("\n");
  }

  Map<String, dynamic> toTransactionData({
    required String network,
    required String address,
    required List<Mosaic> mosaics,
    required String message,
    required String action
  }) {

    List<Map<String,dynamic>> mos = [];
    mosaics.forEach((mo){
      mos.add(mo.toTransactionData(
          id: mo.Id,
          amount: mo.Amount
      ));
    });

    return{
      "Action" : action,
      "Network": network,
      "Address": address,
      "Mosaics": mos,
      "Message": message,
    };
  }
}

//Class List<Tx>(for aggregation)
List<Tx_Readable> Tx_Readables = [];

void Add_Readable(Tx_Readable readable){
  Tx_Readables.add(readable);
}

//sending data
Map<String,dynamic>buildTransaction(String network, List<Tx_Readable> Aggtx){
  List<Map<String, dynamic>> BuildTx = [];
  Aggtx.forEach((tx){
    BuildTx.add(tx.toTransactionData(
        action: tx.Action,
        network: tx.Network,
        address: tx.Address,
        mosaics: tx.Mosaics,
        message: tx.Message,
    ));
  });
  return{
    "Network": network,
    "Transaction" : BuildTx
  };
}

List<String> ReadableList = [];
void AddList(String listS){
  ReadableList.add(listS);
}



String makeuri(String Address, String Ntype, List<Mosaic> Mosaics){
  final buffer = StringBuffer();

  buffer.write('symbol:$Address@$Ntype/$action_Now?');

  for (int i = 0; i < Mosaics.length; i++) {
    if (i > 0) buffer.write('&');
    buffer.write('id[$i]=${Mosaics[i].Id}');
    buffer.write('&amount[$i]=${Mosaics[i].Amount}');
    buffer.write('&div[$i]=${Mosaics[i].Div}');
  }

  return buffer.toString();
}

UriCheckError? validateRawUri(String uri, String walletNet) {
  if (!uri.startsWith('symbol:')) {
    return UriCheckError.notSymbolUri;
  }

  final atIndex = uri.indexOf('@');
  final slashIndex = uri.indexOf('/', atIndex);

  if (atIndex == -1 || slashIndex == -1) {
    return UriCheckError.invalidFormat;
  }

  final netStr = uri.substring(atIndex + 1, slashIndex);


  if (netStr != walletNet) {
    return UriCheckError.differentNetwork;
  }

  if (ReadableList.contains(uri)) {
    return UriCheckError.doubling;
  }
  return null; // OK
}


void onQrRead(String raw) {
  final err = validateRawUri(raw, NType_Now);

  if (err != null) {
    errorMessage(err); //エラーメッセージを何かしらの方法で引き継ぐ
    return;
  }

  ReadableList.add(raw);
}

void read_URI(String uri_string){
  final uri = Uri.parse(uri_string);

// 先頭の / が付く場合があるので除去
  final path = uri.path.startsWith('/')
      ? uri.path.substring(1)
      : uri.path;

// ADDRESS@test/transfer
  final atIndex = path.indexOf('@');
  final slashIndex = path.indexOf('/', atIndex);

  if (atIndex == -1 || slashIndex == -1) {
    throw FormatException('Invalid Symbol URI');
  }

  final address = path.substring(0, atIndex);
  final ntype = path.substring(atIndex + 1, slashIndex);

  final mosaics = <Mosaic>[];
  int i = 0;
  while (true) {
    final id = uri.queryParameters['id[$i]'];
    final amount = uri.queryParameters['amount[$i]'];
    final div = uri.queryParameters['div[$i]'];

    if (id == null || amount == null || div == null) break;
    final inputAmount = BigInt.parse(amount);
    mosaics.add(
      Mosaic.fromParams(
        id: id,
        amount: inputAmount,
        div: int.parse(div),
      ),
    );

    i++;
  }
  Tx_Readable read = new Tx_Readable(address, mosaics, ntype,action_Now);
  Add_Readable(read);
}