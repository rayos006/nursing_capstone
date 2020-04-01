import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile/data/networkRepo.dart';
import 'package:mobile/widgets/carousel_dots.dart';
import 'package:mobile/widgets/carousel.dart';
import 'package:mobile/widgets/recording.dart';
import 'package:mobile/widgets/wavGenerator.dart';
import 'package:oscilloscope/oscilloscope.dart';
import 'package:mobile/widgets/recording_tile.dart';
import 'package:mobile/widgets/filter.dart';
import 'package:mobile/widgets/ExistingRecordingList.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => new _HomeState();
}

class _HomeState extends State<Home> {
  
  int _pageNumber;
  int _carouselPage;
  bool _admin;
  // BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  String _address = "";
  String _name = "";

  Timer _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  List<int> audio = [];

  GlobalKey<NavigatorState> key = new GlobalKey();
  GlobalKey<CarouselDotsState> _keyChild = GlobalKey();
  GlobalKey<ExistingRecordingsState> _recordinList = GlobalKey();

  bool _currentlyRecording;
  String _patientId;

  Oscilloscope oscilloscope;

  void initState() {
    super.initState();
    _admin = true;
    _pageNumber = 0;
    _carouselPage = 0;

    _currentlyRecording = false;
    _patientId = '';

    oscilloscope = new Oscilloscope(
      yAxisMax: 440,
      yAxisMin: -440,
      dataSet: []
    );
  }

  List<BottomNavigationBarItem> items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.perm_camera_mic,color: Color.fromARGB(255, 0, 0, 0)),
      title: new Text('New Recording')
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.flag,color: Color.fromARGB(255, 0, 0, 0)),
      title: new Text('Admin Review')
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.update, color: Color.fromARGB(255, 0, 0, 0)),
      title: new Text('Review/Submit')
    )
  ];

  List<BottomNavigationBarItem> _getItems() {
    List<BottomNavigationBarItem> authorized = [];

    authorized.add(items[0]);
    if (_admin) {
      authorized.add(items[1]);
    }
    authorized.add(items[2]);

    return authorized;
  }

  void _startReading() {
    showDialog(
      context: context,
      builder: (context) {

        GlobalKey stateKey = new GlobalKey(); 

        List<double> volumes = [];
        void callback(double nextValue) {
          stateKey.currentState.setState(() { 
            volumes.add(nextValue * 2.828); //2*sqrt(2) rms->peak
              oscilloscope = new Oscilloscope(
                yAxisMax: 440,
                yAxisMin: -440,
                dataSet: volumes
              );
          });
        }
        RecordingMic mic = new RecordingMic('$_carouselPage', _patientId, context, callback);
        Future<bool> ready = mic.init();
        ready.then((value) {
          mic.viewAudio();
        });

        return  StatefulBuilder(
          key: stateKey,
          builder: (context, setState) { 
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Container(
                height: 300,
                width: 250,
                color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      height: 250,
                      width: 250,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            flex: 1,
                            child: oscilloscope,
                          )
                        ]
                      )
                    ),
                    Row(
                      children: <Widget>[
                        FlatButton(
                          child: Text('cancel'),
                          onPressed:() => mic.cancel()
                        ),
                        FlatButton(
                          child: Text('startRecording'),
                          onPressed:() async {
                            await mic.cancel();
                            await mic.init();
                            await mic.writeAudio();
                          }
                        )
                      ]
                    )
                    //CircularProgressIndicator(),
                  ]
                )
              )
            );
          }
        );
      }
    );
  }

  void _writeWav() {
    if (audio != null) {
      WavGenerator wav = new WavGenerator("$_patientId/soundFileSample$_carouselPage", audio);
    }
  }

@override
  Widget build(BuildContext context) {

    List<String> routes = [
      '/',
      '/1',
      '/2'
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Beats Stethoscope'),
      ),
      drawer: (_pageNumber == 1) ? Filter(
          callback:(){},
          submit:(){}
      ) : Container(),
      body: Navigator(
        key: key,
        onGenerateRoute: (RouteSettings settings) {
          return MaterialPageRoute(
            settings: settings,
            builder: (BuildContext context) {
              switch(settings.name) {
                case '/':
                  return (_currentlyRecording)
                  ? Column(
                    children: <Widget>[
                      Carousel(
                        callback: (index) {
                          setState(() {
                            _carouselPage = index;
                          });
                          _keyChild.currentState.changeDots(index);
                        },
                        submit: () {
                          print('submit');
                          setState(() {
                            _patientId = '';
                            _currentlyRecording = false;
                          });
                          _recordinList.currentState.generateFilesFromLocalStorage();
                        },
                      ),
                      CarouselDots(_keyChild),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: <Widget>[
                          Container(
                            height: 50,
                            width: 100,
                            color: Colors.blue,
                            child: FlatButton(
                              child: Text('Record'),
                              onPressed: () async {
                                _startReading();
                              }
                            )
                          ),
                          Container(
                            height: 50,
                            width: 100,
                            color: Colors.blue,
                            child: FlatButton(
                              child: Text('Review'),
                              onPressed: (){
                                // WavGenerator wav = new WavGenerator("soundFileSample$_carouselPage", [0]);
                                // Future<File> file = wav.localFile;
                                // file.then((value) {
                                //   Future<Uint8List> test = value.readAsBytes();
                                //   test.then((nextValue) {
                                //     String newStuff = nextValue.toString();
                                //   });
                                // });
                              },
                            )
                          )
                        ],
                      )
                    ],
                  )
                  : Container(
                    child: FlatButton(
                      child: Center(
                        child: Container(
                          height: 50,
                          width: 150,
                          color: Colors.blue,
                          child: Center(
                            child: Text('Create New Patient', style: TextStyle(color: Colors.white),)
                          )
                        )
                      ),
                      onPressed: () async {
                        // User user = new User();
                        // await user.init();
                        String holderId = await new_patient('test@test.com');//user.username
                        setState(() {
                          _patientId = holderId;
                          _currentlyRecording = true;
                        });
                      },
                    ),
                  );
                  break;
                case '/1':
                  return (_admin) 
                  ? RecordingTile(
                    callback: (){},
                    submit:(){}
                  ) 
                  : Container();
                  break;
                case '/2':
                  return ExistingRecordingList(
                    key: _recordinList,
                  );
                  break;
                default:
                  return Container();
                  break;
              }
            }
          );
        }
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _getItems(),
        currentIndex: _pageNumber,
        //type: BottomNavigationBarType.shifting,
        onTap: (index) {
          if(_pageNumber != index) {
            setState(() {
            _pageNumber = index; 
            });
            key.currentState.popAndPushNamed(routes[index]);
          }
        },
      ),
    );
  }
}

enum RecordinStatus {
  NORECORDING,
  ACTIVERECORDING,
  POSTRECORDING
}