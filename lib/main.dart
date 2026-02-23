import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'Page1.dart';
import 'Page2.dart';
import 'Symbol.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown
  ]);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HACKATUS TEST',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyPage(title: 'Symbol payment test'),
    );
  }
}

class MyPage extends StatefulWidget {
  const MyPage({super.key, required this.title});
  final String title;

  @override
  State<MyPage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyPage> {
  static const _screens = [
    Page1(title: 'WriteQR'),
    MainPage(),
    Page2(title: 'RradQR'),
  ];

  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }



  @override
  initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.initState();
    setNode();
  }

  Future<void> setNode() async{
    await setNode_Test();
    if(mounted){
      setState(() {
      });
    }
    if(MyNode.endpoint.isEmpty){
      _showDialogAfterDelay();
    }
  }

  Future<void> _showDialogAfterDelay() async {
    await Future.delayed(Duration.zero); // ウィジェットが初期化された後に非同期でダイアログを表示するための遅延
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("接続エラー"),
          content: Text("ノードが接続されていません"),
          actions: <Widget>[
            GestureDetector(
              child: const Text('分かりました'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {

    if (MyNode.endpoint.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body:_screens[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.attach_money_outlined),label: '書き込み'),
          BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Wallet'),
          BottomNavigationBarItem(icon: Icon(Icons.camera), label: '読み込み'),
        ],
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => MainPageState();

}
class MainPageState extends State<MainPage>{

  double _XYM =0.0;
  @override
  initState() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.initState();
    GetXYM();
  }

  Future<void> GetXYM() async{
    _XYM = await setXYM(M_Address);
    setState((){

    });
  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Center(
          child: Container(
            height: 300,
            margin: EdgeInsets.all(15),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black),
              borderRadius: BorderRadius.circular(10),
            ),
            child:Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Account',
                  style: const TextStyle(
                    fontSize: 36.0,
                  ),
                ),
                const Padding(padding: EdgeInsets.all(20)),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Address:',
                        style: const TextStyle(
                          fontSize: 26.0,
                        ),
                      ),
                      const Padding(padding: EdgeInsets.all(10)),
                      Expanded(
                        child: Text(
                          M_Address,
                          style: const TextStyle(fontSize: 24),
                          overflow: TextOverflow.ellipsis, // 長いテキストを省略
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: M_Address));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Text Copied")),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Row(
                  children: <Widget>[
                    const Text(
                      'XYM:',
                      style: const TextStyle(
                        fontSize: 26.0,
                      ),
                    ),
                    const Padding(padding: EdgeInsets.all(10)),
                    Text(
                      '${_XYM.toStringAsFixed(3)} XYM',
                      style: const TextStyle(
                        fontSize: 26.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ),
    );
  }
}