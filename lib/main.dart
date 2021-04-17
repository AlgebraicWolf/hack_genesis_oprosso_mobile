import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.grey,
      ),
      // home: Task(title: 'Flutter Demo Home Page'),
      initialRoute: '/',
      routes: {
        '/': (context) => FirstSetup(),
        '/second': (context) => SecondSetup(),
        '/task': (context) => Task()
      },
    );
  }
}

class Task extends StatefulWidget {
  Task({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _TaskState createState() => _TaskState();
}

class _TaskState extends State<Task> {
  bool isRecording = false;

  Future<bool> startScreenRecord(String filename) async {
    bool result = await FlutterScreenRecording.startRecordScreen(filename);
    return result;
  }

  Future<String> stopScreenRecord() async {
    String path = await FlutterScreenRecording.stopRecordScreen;
    return path;
  }

  void printOnArrival(Future<String> str) async {
    str.then((s) {
      print(s);
    });
  }

  void requestPermissions() async {
    await PermissionHandler().requestPermissions([
      PermissionGroup.storage,
      PermissionGroup.photos,
      PermissionGroup.microphone,
    ]);
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Testers gonna test"),
      ),
      body: Container(
        child: ElevatedButton(
          onPressed: () {
            if (!isRecording) {
              startScreenRecord("demo");
              Dio().get('http://127.0.0.1:5000/start');
              setState(() {
                isRecording = true;
              });
            } else {
              Future path = stopScreenRecord();
              Dio().get('http://127.0.0.1:5000/stop');
              printOnArrival(path);
              setState(() {
                isRecording = false;
              });
            }
          },
          child: Text(
            !isRecording ? "Start recording" : "Stop recording",
            style: TextStyle(
              fontSize: 20,
            ),
          ),
        ),
        alignment: Alignment.center,
      ),
    );
  }
}

// First form: IP + Port1 + ADB Code
class FirstForm extends StatefulWidget {
  @override
  _FirstFormState createState() => _FirstFormState();
}

class _FirstFormState extends State<FirstForm> {
  static const double textFieldInset = 10.0;

  final ipController = TextEditingController();
  final portController = TextEditingController();
  final adbController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final _notEmptyValidator = (String value) {
    if (value == null || value.isEmpty) {
      return 'Please enter correct value';
    }
    return null;
  };

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Padding(
            child: TextFormField(
              controller: ipController,
              decoration: InputDecoration(
                hintText: "IP address",
              ),
              validator: _notEmptyValidator,
            ),
            padding: EdgeInsets.all(textFieldInset),
          ),
          Padding(
            child: TextFormField(
              controller: portController,
              decoration: InputDecoration(
                hintText: "Port number",
              ),
              validator: _notEmptyValidator,
            ),
            padding: EdgeInsets.all(textFieldInset),
          ),
          Padding(
            child: TextFormField(
              controller: adbController,
              decoration: InputDecoration(
                hintText: "ADB code",
              ),
              validator: _notEmptyValidator,
            ),
            padding: EdgeInsets.all(textFieldInset),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  Dio().get(
                      'http://127.0.0.1:5000/pair?addr=${ipController.text}:${portController.text}&code=${adbController.text}');
                  Navigator.pushNamed(
                    context,
                    '/second',
                    arguments: ipController.text,
                  );
                }
              },
              child: Text("Submit"),
            ),
          ),
        ],
      ),
    );
  }
}

// Second form: Port2
class SecondForm extends StatefulWidget {
  final String ip;

  SecondForm({Key key, this.ip}) : super(key: key);

  @override
  _SecondFormState createState() => _SecondFormState();
}

class _SecondFormState extends State<SecondForm> {
  static const double textFieldInset = 10.0;

  final portController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  final _notEmptyValidator = (String value) {
    if (value == null || value.isEmpty) {
      return 'Please enter correct value';
    }
    return null;
  };

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Padding(
            child: TextFormField(
              controller: portController,
              decoration: InputDecoration(
                hintText: "Another port number",
              ),
              validator: _notEmptyValidator,
            ),
            padding: EdgeInsets.all(textFieldInset),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
            child: ElevatedButton(
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  Dio().get(Uri.encodeFull(
                      'http://127.0.0.1:5000/connect?addr=${widget.ip}:${portController.text}'));
                  Navigator.pushNamed(context, '/task');
                }
              },
              child: Text("Submit"),
            ),
          ),
        ],
      ),
    );
  }
}

// First portion of settings
class FirstSetup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Testers gonna test!"),
      ),
      body: FirstForm(),
    );
  }
}

// Second portion of settings
class SecondSetup extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String ip = ModalRoute.of(context).settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: Text("Testers gonna test!"),
      ),
      body: SecondForm(
        ip: ip,
      ),
    );
  }
}
