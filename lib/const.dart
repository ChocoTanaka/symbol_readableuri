import 'package:symbol_sdk/symbol/index.dart';


enum UriCheckError {
  notSymbolUri,
  differentNetwork,
  invalidFormat,
  doubling,
}

final NType_Now = NType.testnet;

enum NType {
  mainnet,
  testnet,
}

NetworkType N_Now(NType NT){
  switch (NT){
    case NType.testnet:
      return NetworkType.TESTNET;
    case NType.mainnet:
      return NetworkType.MAINNET;
  }
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

NType parseNetwork(String raw) {
  switch (raw) {
    case 'main':
      return NType.mainnet;
    case 'test':
      return NType.testnet;
    default:
      throw Exception('Unknown network type');
  }
}



String parseNetwork_s(NType NT) {
  switch (NT) {
    case NType.mainnet:
      return 'main';
    case NType.testnet:
      return 'test';
    default:
      throw Exception('Unknown network type');
  }
}

class Mosaic{
  late String Id;
  late BigInt Amount;
  late int Div;

  Mosaic._internal({required this.Id, required this.Amount, required this.Div});

  String toDisplay() {
    final s = Amount.toString().padLeft(Div + 1, '0');

    var integer = s.substring(0, s.length - Div);
    var decimal = s.substring(s.length - Div);

    // 末尾ゼロ削除
    decimal = decimal.replaceFirst(RegExp(r'0+$'), '');

    // 先頭ゼロ削除（重要）
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

BigInt toBigInt(String input, int div) {
  String normalized = input.replaceAll('.', '');
  int decimals = input.contains('.') ? input.split('.')[1].length : 0;
  int zerosToAdd = div - decimals;
  for (int i = 0; i < zerosToAdd; i++) {
    normalized += '0';
  }
  return BigInt.parse(normalized);
}

class Tx_Readable{
  late String Address;
  late List<Mosaic> Mosaics=[];
  late String Message = "";

  Tx_Readable(String address,List<Mosaic> mos){
    this.Address = address;
    for(int i = 0; i<mos.length; i++){
      this.Mosaics.add(mos[i]);
    }
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
}

List<Tx_Readable> Tx_Readables = [];
void Add_Readable(Tx_Readable readable){
  Tx_Readables.add(readable);
}


List<String> ReadableList = [];
void AddList(String listS){
  ReadableList.add(listS);
}



String makeuri(String Address, String Ntype, List<Mosaic> Mosaics){
  final buffer = StringBuffer();

  buffer.write('symbol:$Address@$Ntype/transfer?');

  for (int i = 0; i < Mosaics.length; i++) {
    if (i > 0) buffer.write('&');
    buffer.write('id[$i]=${Mosaics[i].Id}');
    buffer.write('&amount[$i]=${Mosaics[i].Amount}');
    buffer.write('&div[$i]=${Mosaics[i].Div}');
  }

  return buffer.toString();
}

UriCheckError? validateRawUri(String uri, NType walletNet) {
  if (!uri.startsWith('symbol:')) {
    return UriCheckError.notSymbolUri;
  }

  final atIndex = uri.indexOf('@');
  final slashIndex = uri.indexOf('/', atIndex);

  if (atIndex == -1 || slashIndex == -1) {
    return UriCheckError.invalidFormat;
  }

  final netStr = uri.substring(atIndex + 1, slashIndex);

  final uriNet = parseNetwork(netStr);

  if (uriNet != walletNet) {
    return UriCheckError.differentNetwork;
  }

  if (ReadableList.contains(uri)) {
    return UriCheckError.doubling;
  }
  return null; // OK
}
//readable uriに加えるのは別関数で。

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

  final all = uri.queryParametersAll;

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
  Tx_Readable read = new Tx_Readable(address, mosaics);
  Add_Readable(read);
}