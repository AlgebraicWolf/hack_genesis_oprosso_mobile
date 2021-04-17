import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dio/dio.dart';
import 'package:shadow/shadow.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:app_installer/app_installer.dart';
import 'package:path_provider/path_provider.dart';
import 'Task.dart';

const bool CONNECT_TO_ADB = false;
const String SERVER_ADDR = 'http://192.168.1.85:8000/api';

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
        primaryColor: Color.fromARGB(255, 219, 246, 253),
        scaffoldBackgroundColor: Color.fromARGB(255, 243, 246, 253),
        buttonTheme: ButtonThemeData(
          buttonColor: Color(0xffc8f7dc),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(100.0)),
          ),
        ),
      ),

      // home: Task(title: 'Flutter Demo Home Page'),
      initialRoute: '/',
      routes: {
        '/': (context) => FirstSetup(),
        '/second': (context) => SecondSetup(),
        '/tasks': (context) => TasksView(),
        '/task': (context) => Task(),
        '/prepare': (context) => PrepareEnvironment(),
        '/launch': (context) => LaunchTask(),
      },
    );
  }
}

class FancyText extends StatelessWidget {
  final String txt;

  FancyText(this.txt);

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: 1,
      child: Container(
        child: Text(txt),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(20)),
          border: Border.all(
            color: Color.fromARGB(255, 228, 228, 228),
            width: 1,
          ),
        ),
        padding: EdgeInsets.all(10),
      ),
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
  void requestPermissions() async {
    await PermissionHandler().requestPermissions([
      PermissionGroup.storage,
      PermissionGroup.photos,
    ]);
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final TaskData task = ModalRoute.of(context).settings.arguments as TaskData;

    return Scaffold(
      appBar: AppBar(
        title: Text(task.name),
      ),
      body: Container(
        child: Column(
          children: <Widget>[
            Expanded(
              child: SingleChildScrollView(
                child: FancyText(task.description),
              ),
            ),
            RaisedButton(
              onPressed: () {
                Navigator.popAndPushNamed(context, '/prepare', arguments: task);
              },
              child: Text(
                "Select this task",
                style: TextStyle(
                  fontSize: 20,
                ),
              ),
            )
          ],
        ),
        alignment: Alignment.center,
        padding: EdgeInsets.all(10),
      ),
    );
  }
}

class NeatTextFormField extends StatelessWidget {
  final String hint;
  final TextEditingController controller;

  NeatTextFormField(this.hint, this.controller);

  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(50.0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
            width: 1.0,
            color: Color.fromARGB(255, 228, 228, 228),
          ),
          borderRadius: BorderRadius.all(Radius.circular(50.0)),
        ),
      ),
      validator: (value) =>
          (value == null || value.isEmpty) ? 'Please enter correctValue' : null,
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

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: <Widget>[
          Padding(
            child: NeatTextFormField("IP address", ipController),
            padding: EdgeInsets.all(textFieldInset),
          ),
          Padding(
            child: NeatTextFormField("Port number", portController),
            padding: EdgeInsets.all(textFieldInset),
          ),
          Padding(
            child: NeatTextFormField("ADB code", adbController),
            padding: EdgeInsets.all(textFieldInset),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
            child: RaisedButton(
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  if (CONNECT_TO_ADB)
                    Dio().get(Uri.encodeFull(
                        'http://127.0.0.1:5000/pair?addr=${ipController.text}:${portController.text}&code=${adbController.text}'));
                  Navigator.pushNamed(
                    context,
                    '/second',
                    arguments: ipController.text,
                  );
                }
              },
              padding: EdgeInsets.all(15.0),
              elevation: 1.0,
              child: Text(
                "Submit",
                style: TextStyle(fontSize: 20.0),
              ),
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
            child: NeatTextFormField("Another port number", portController),
            padding: EdgeInsets.all(textFieldInset),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 10.0),
            child: RaisedButton(
              onPressed: () {
                if (_formKey.currentState.validate()) {
                  if (CONNECT_TO_ADB)
                    Dio().get(Uri.encodeFull(
                        'http://127.0.0.1:5000/connect?addr=${widget.ip}:${portController.text}'));
                  Navigator.pushNamed(context, '/tasks');
                }
              },
              elevation: 1.0,
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

class TaskEntry extends StatelessWidget {
  final TaskData task;

  TaskEntry(this.task);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(task.name),
      onTap: () {
        print("Selected task ${task.taskId}");
      },
    );
  }
}

// Just a loading screen
class Loading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Shadow(
        child: Image.asset(
          'assets/animated/loading.gif',
          height: 150,
          width: 150,
        ),
      ),
    );
  }
}

// View with tasks
class TasksView extends StatelessWidget {
  Future<List<TaskData>> getTasks() async {
    // return Future.delayed(
    //     Duration(seconds: 2),
    //     () => [
    //           TaskData(
    //               0,
    //               "Задача про два стула",
    //               "Есть два стула: на одном пики точеные, на другом...",
    //               "",
    //               ""),
    //           TaskData(1, "Задача Заранкевича", "писеееееееееееееееееееееец",
    //               "", ""),
    //           TaskData(
    //               2,
    //               "Задача на хакатон",
    //               " Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum. ",
    //               "https://github.com/KristinaKulabuhova/hack_genesis_cdn/raw/master/com.sec.android.app.popupcalculator_12.0.05.5-1200505000.apk",
    //               "com.vkontakte.android")
    //         ]);
    var response = await Dio().get(SERVER_ADDR + '/tasks',
        options: Options(responseType: ResponseType.json));
    var data = response.data['tasks']; // Extract list of records
    print(response.data.toString());
    List<TaskData> mapped =
        data.map<TaskData>((elem) => TaskData.fromJson(elem)).toList();
    return mapped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Testers gonna test!"),
      ),
      body: FutureBuilder<List<TaskData>>(
        future: getTasks(),
        builder:
            (BuildContext context, AsyncSnapshot<List<TaskData>> snapshot) {
          if (snapshot.hasData) {
            final list = snapshot.data;
            return ListView.separated(
              itemCount: list.length,
              itemBuilder: (context, index) => ListTile(
                enabled: true,
                onTap: () {
                  print("Selected item ${list[index].taskId}");
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => Navigator.pushNamed(
                            context,
                            '/task',
                            arguments: list[index],
                          ));

                  return Container();
                },
                title: Text(
                  list[index].name,
                ),
              ),
              separatorBuilder: (context, index) => Divider(),
            );
          } else if (snapshot.hasError) {
            return Text("FUCK");
          } else {
            return Loading();
          }
        },
      ),
    );
  }
}

// Loading screen that checks and prepares everything for the user to complete the task
class PrepareEnvironment extends StatelessWidget {
  Future<int> prepareEnvironment(String link, String pkgname) async {
    try {
      var available = await InstalledApps.getAppInfo(pkgname);
    } on String catch (_) {
      print("App is not installed. Downloading...");
      Directory docDir = await getExternalStorageDirectory();
      String docPath = docDir.path;
      String appPath = docPath + pkgname + '.apk';

      // print("Acquired temporary directory. Downloading APK...");
      await Dio().download(link, appPath);

      print("APK was downloaded. Launching installation...");
      await AppInstaller.installApk(appPath);
      print("The app was installed.");
    }

    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final TaskData task = ModalRoute.of(context).settings.arguments as TaskData;

    return Scaffold(
      appBar: AppBar(title: Text("Настройка окружения")),
      body: FutureBuilder(
        future: prepareEnvironment(task.link, task.pkgname),
        builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
          if (snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) =>
                Navigator.popAndPushNamed(context, '/launch', arguments: task));

            return Container();
          } else if (snapshot.hasError) {
            return Text("FUCK");
          } else {
            return Loading();
          }
        },
      ),
    );
  }
}

// Screen for task launching that is opened _after_ the environment is prepared
class LaunchTask extends StatefulWidget {
  @override
  _LaunchTaskState createState() => _LaunchTaskState();
}

class _LaunchTaskState extends State<LaunchTask> {
  bool isRecording = false;

  Future<bool> startScreenRecord(String filename) async {
    bool result = await FlutterScreenRecording.startRecordScreen(filename);
    return result;
  }

  Future<String> stopScreenRecord() async {
    String path = await FlutterScreenRecording.stopRecordScreen;
    return path;
  }

  Future<bool> startTask(TaskData task) async {
    await startScreenRecord("taskExecution");
    if (CONNECT_TO_ADB) await Dio().get('http://127.0.0.1:5000/start');
    await InstalledApps.startApp(task.pkgname);
  }

  Future<bool> stopTask() async {
    String path = await stopScreenRecord();
    if (CONNECT_TO_ADB) await Dio().get('http://127.0.0.1:5000/stop');

    // TODO process path (somehow) :D
  }

  void printOnArrival(Future<String> str) async {
    str.then((s) {
      print(s);
    });
  }

  @override
  Widget build(BuildContext context) {
    final TaskData task = ModalRoute.of(context).settings.arguments as TaskData;

    return Scaffold(
      appBar: AppBar(title: Text(task.name)),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(10.0),
              child: ListView(
                children: [
                  FancyText(
                      "After pressing the \"Start\" button the app will launch the taget app and start all the necessary recording. Make sure to provide access to screen recording. The insturction will be replicated below for the sake of your convenience. When you are done, make sure to get back here and stop the tracking."),
                  Container(
                    height: 10,
                    width: 1,
                  ),
                  FancyText(task.description),
                ],
              ),
            ),
          ),
          RaisedButton(
            onPressed: () {
              if (!isRecording) {
                startTask(task);
                setState(() {
                  isRecording = true;
                });
              } else {
                stopTask();
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
            color: !isRecording ? Color(0xffc8f7dc) : Color(0xffffd3e2),
          )
        ],
      ),
    );
  }
}
