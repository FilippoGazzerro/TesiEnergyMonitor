import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:date_time_picker/date_time_picker.dart';
import 'package:intl/intl.dart';
import 'package:charts_flutter/flutter.dart' as charts;

//String _logintoken = 'JWT eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyIjp7InN0YXR1cyI6ImVuYWJsZWQiLCJfaWQiOiI2MmQ3YmZiYTQzOGI5YjAwMWVjYjkyYjYiLCJ1c2VybmFtZSI6ImVuZXJneS1tYW5hZ2VyLXVzZXItdXNlcm5hbWUiLCJwYXNzd29yZCI6IiQyYSQwOCRFdHNVQmI1d0tJZ0JzSGl1eGouSThlbGhuRWNrYXMzLmdmZHZoSVlYbnE1YlVmNmpXeFJ0QyIsInR5cGUiOiJwcm92aWRlciIsIl9fdiI6MH0sInRlbmFudCI6eyJwYXNzd29yZGhhc2giOnRydWUsIl9pZCI6ImVuZXJneS1tYW5hZ2VyLXRlbmFudCIsIm9yZ2FuaXphdGlvbiI6Ik1lYXN1cmlmeSBvcmciLCJhZGRyZXNzIjoiTWVhc3VyaWZ5IFN0cmVldCwgR2Vub3ZhIiwiZW1haWwiOiJpbmZvQG1lYXN1cmlmeS5vcmciLCJwaG9uZSI6IiszOTEwMzIxODc5MzgxNyIsImRhdGFiYXNlIjoiZW5lcmd5LW1hbmFnZXItdGVuYW50In0sImlhdCI6MTY1OTYxNjE0NiwiZXhwIjoxNjU5NjE3OTQ2fQ.lcc4PbDcR648mqosfCEgmtK8KRrdzjkI2D0eFDmRaqg';
String _logintoken = '';

Future<http.Response> sendLogin() async {
  final response = await http.post(
    Uri.parse('https://students.measurify.org/v1/login'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },    body: jsonEncode (<String, String> {
    'username' : 'energy-manager-user-username',
    'password' : 'energy-manager-user-password',
    'tenant': 'energy-manager-tenant' }),
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    dynamic jsonres=jsonDecode(response.body);
    developer.log('token: ' + jsonres['token'].toString(),name:'sendLogin');
    _logintoken =jsonres['token'].toString();
    return response;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    developer.log('statusCode: ' + response.statusCode.toString());
    developer.log('response: ' + response.toString());
    return response;
  }
}

Future<List<TAEMeasure>> getMeasuresList_aaa() async {
  developer.log('_logintoken: ' + _logintoken,name:'getMeasuresList');
  final response = await http.get(
    Uri.parse('https://students.measurify.org/v1/measurements?filter={"feature":"total-active-energy", "thing":"Via Opera Pia 11a - primo piano"}'),
    headers: {
      HttpHeaders.authorizationHeader: _logintoken,
    },
  );

  if (response.statusCode == 200) {
    // If the server did return a 200 OK response,
    // then parse the JSON.
    dynamic jsonres=jsonDecode(response.body);
    developer.log('num of things: ' + jsonres['totalDocs'].toString(),name:'httpGET');

    final parsed = jsonres['docs'].cast<Map<String, dynamic>>();

    List<TAEMeasure> samples_list = parsed.map<TAEMeasure>((json) => TAEMeasure.fromJson(json)).toList();
    developer.log('samples_list: ' + samples_list[0].toString());
    developer.log('samples_list 1: ' + samples_list[0].samples[0].toString());

    String Measures = '';

    for (TAEMeasure isample in samples_list) {
      developer.log('valore:'+ isample.samples[0].toString());
      Measures = Measures + isample.samples[0].toString();
    }

    return samples_list;
  } else {
    // If the server did not return a 200 OK response,
    // then throw an exception.
    developer.log('statusCode: ' + response.statusCode.toString());
    developer.log('response: ' + response.toString());
    throw Exception('Failed to load Measures');
  }
}

//Recupera le misure total-active-energy sulla base di data e piano (thing)
Future<List<TAEMeasure>> getMeasuresList(String sDate,String eDate, String cPiano) async {

  //prima viene fatta una chiamata POST di login
  final response1 = await http.post(
    Uri.parse('https://students.measurify.org/v1/login'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },    body: jsonEncode (<String, String> {
    'username' : 'energy-manager-user-username',
    'password' : 'energy-manager-user-password',
    'tenant': 'energy-manager-tenant' }),
  );

  if (response1.statusCode == 200) {
    //se il login è positivo viene salvato il token per la chiamata successiva
    dynamic jsonres=jsonDecode(response1.body);
    _logintoken =jsonres['token'].toString();

    List<TAEMeasure> samples_list;
    if (cPiano!='Scegli il Piano') {
      String add_sDate='';
      if (sDate!=''){
        add_sDate=', "startDate": { "\$gt":"$sDate", "\$lt":"$eDate\T23:59:59"}';
      }
      developer.log('cPiano: $cPiano sDate: $sDate eDate: $eDate\T23:59:59');

      //chiamata GET per recuperare le misure di un piano a partire da una certa data
      final response = await http.get(
        Uri.parse('https://students.measurify.org/v1/measurements?filter={"feature":"total-active-energy", "thing":"$cPiano"$add_sDate}'),
        headers: {
          HttpHeaders.authorizationHeader: _logintoken,
        },
      );

      if (response.statusCode == 200) {
        dynamic jsonres=jsonDecode(response.body);
        final parsed = jsonres['docs'].cast<Map<String, dynamic>>();
        List<TAEMeasure> samples_list = parsed.map<TAEMeasure>((json) => TAEMeasure.fromJson(json)).toList();

        developer.log('samples :'+ samples_list.length.toString());

        for (TAEMeasure isample in samples_list) {
          List samples = isample.samples.toList();

          List<TAESample> sample_list = isample.samples.map<TAESample>((json) => TAESample.fromJson(json)).toList();
          //developer.log('valore:'+ isample.samples[0].toString());
          //developer.log('valorei:'+ sample_list[0].values[0].toString());
        }
        return samples_list;
      } else {
        throw Exception('Failed to load Measures');
      }
    } else {
      String rbodynull = '{ "docs": [], "totalDocs": 0, "limit": 10, "totalPages": 1, "page": 1, "pagingCounter": 1, "hasPrevPage": false, "hasNextPage": false, "prevPage": null, "nextPage": null }';
      dynamic jsonres=jsonDecode(rbodynull);
      final parsed = jsonres['docs'].cast<Map<String, dynamic>>();
      List<TAEMeasure> samples_list = parsed.map<TAEMeasure>((json) => TAEMeasure.fromJson(json)).toList();

      return samples_list;
    }
  } else {
    throw Exception('Failed to Login');
  }
}

//Recupera le misure energy-state sulla base del piano (thing)
Future<List<TAEMeasure>> getLiveList(String cPiano) async {
  //prima viene fatta una chiamata POST di login
  final response1 = await http.post(
    Uri.parse('https://students.measurify.org/v1/login'),
    headers: <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    },    body: jsonEncode (<String, String> {
    'username' : 'energy-manager-user-username',
    'password' : 'energy-manager-user-password',
    'tenant': 'energy-manager-tenant' }),
  );
  if (response1.statusCode == 200) {
    //se il login è positivo viene salvato il token per la chiamata successiva
    dynamic jsonres=jsonDecode(response1.body);
    _logintoken =jsonres['token'].toString();

    List<TAEMeasure> samples_list;
    if (cPiano!='Scegli il Piano') {
      //chiamata GET per recuperare le ultime 50 misure di un piano
      final response = await http.get(
        Uri.parse('https://students.measurify.org/v1/measurements?filter={"feature":"energy-state", "thing":"$cPiano"}&limit=50'),
        headers: {
          HttpHeaders.authorizationHeader: _logintoken,
        },
      );

      if (response.statusCode == 200) {
        //converte il json ricevuto in una lista ti TAEMeasure
        dynamic jsonres=jsonDecode(response.body);
        final parsed = jsonres['docs'].cast<Map<String, dynamic>>();
        List<TAEMeasure> samples_list = parsed.map<TAEMeasure>((json) => TAEMeasure.fromJson(json)).toList();

        developer.log('samples :'+ samples_list.length.toString());

        for (TAEMeasure isample in samples_list) {  //
          List samples = isample.samples.toList();

          List<TAESample> sample_list = isample.samples.map<TAESample>((json) => TAESample.fromJson(json)).toList();
        }
        return samples_list;
      } else {
        throw Exception('Failed to load Measures');
      }
    } else {
      String rbodynull = '{ "docs": [], "totalDocs": 0, "limit": 10, "totalPages": 1, "page": 1, "pagingCounter": 1, "hasPrevPage": false, "hasNextPage": false, "prevPage": null, "nextPage": null }';
      dynamic jsonres=jsonDecode(rbodynull);
      final parsed = jsonres['docs'].cast<Map<String, dynamic>>();
      List<TAEMeasure> samples_list = parsed.map<TAEMeasure>((json) => TAEMeasure.fromJson(json)).toList();

      return samples_list;
    }
  } else {
    throw Exception('Failed to Login');
  }

}
//formatta la stringa da mostrare nella lista di misure, un campione è di tipo TAEMeasure e contiene un valore di tipo TAESample
String getValues(TAEMeasure samples_list){
  String cText='';
  List<TAESample> sample_list = samples_list.samples.map<TAESample>((json) => TAESample.fromJson(json)).toList();
  DateTime cDate = DateTime.parse(samples_list.startdate);
  cText = 'Data:    ' + DateFormat('dd/MM/yyyy HH:mm').format(cDate) + '\nValore: ' + sample_list[0].values[0].toString() + ' KWh';

  return cText;
}

//classe che definisce un valore di una misura, campo TAEMeasure.samples
class TAESample {
  final List values;

  const TAESample({
    required this.values
  });

  factory TAESample.fromJson(Map<String, dynamic> json) {
    return TAESample(values: json['values'] as List);
  }
}

//classe che definisce una misura, i valori sono una lista di TAESample
class TAEMeasure {
  final String id;
  final String thing;
  final String feature;
  final String device;
  final List samples;
  final String startdate;

  const TAEMeasure({
    required this.id,
    required this.thing,
    required this.feature,
    required this.device,
    required this.samples,
    required this.startdate
  });

  factory TAEMeasure.fromJson(Map<String, dynamic> json) {
    return TAEMeasure(
        id: json['_id'] as String,
        thing: json['thing'] as String,
        feature: json['feature'] as String,
        device: json['device'] as String,
        samples: json['samples'] as List,
        startdate: json['startDate'] as String
    );
  }
}

//classe che definisce una punto del grafico tempo,valore
class voltData {
  DateTime asseX;
  double volt;
  voltData(this.asseX,this.volt);
}

void main() {
  runApp(const MaterialApp(home: Homepage(),));
}

//classe per pagina dei dati live
class LiveData extends StatefulWidget {
  const LiveData({super.key});

  @override
  State<LiveData> createState() => _LiveDataState();
}

//classe per pagina dei dati live
class _LiveDataState extends State<LiveData> {
  //lista future(async) che conterrà i dati presi da measurify
  late Future<List<TAEMeasure>> liveMeasures;

  //liste per i menu dropdown
  String cPiano = 'Scegli il Piano';
  var Piani = ['Scegli il Piano','Via Opera Pia 11a - primo piano','Via Opera Pia 11a - secondo piano','Via Opera Pia 11a - terzo piano'];

  String cGrandezza = 'Tensione';
  var Grandezze = ['Scegli Grandezza','Tensione','Potenza','Corrente','Frequenza'];

  String cTime='Ultimo aggiornamento: ---';

  //timer per aggiornamento dati
  late Timer tmr1;

  //stato iniziale
  @override
  void initState() {
    super.initState();
    liveMeasures = getLiveList(cPiano);
  }

  //dispose quando si chiude la pagina
  @override
  void dispose(){
    tmr1.cancel();
    super.dispose();
  }

  var tActive=0;

  //funzione che aggiorna le misure, viene chiamata da onchange delle dropdown
  void filterLive(){
    setState(() {
      liveMeasures = getLiveList(cPiano);
      cTime = 'Ultimo aggiornamento: ' + DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
      developer.log('filterLive :' + tActive.toString() + ' - ' + DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()));
      if (tActive==0){
        tmr1 = Timer.periodic(Duration(seconds: 15), filterLiveT);
        tActive=1;
      }
    });
  }

  //funzione che aggiorna le misure, viene chiamata dal timer
  void filterLiveT(Timer tmr1){
    setState(() {
      liveMeasures = getLiveList(cPiano);
      developer.log('filterLiveT :' + DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now()));
      cTime = 'Ultimo aggiornamento: ' + DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.now());
    });
  }

  final List<voltData> cDatiserie = [];

  //crea la serie per il grafico
  getVoltData(List<TAEMeasure> cData) {
    cDatiserie.clear();
    //scorre le misure ottenute da cloud ed estrae i volt e crea la serie
    if (cGrandezza=='Tensione'){
      for (TAEMeasure isample in cData){
        List<TAESample> sample_list = isample.samples.map<TAESample>((json) => TAESample.fromJson(json)).toList();
        cDatiserie.add(new voltData(DateTime.parse(isample.startdate),sample_list[0].values[1]));
      }
    }
    if (cGrandezza=='Potenza'){
      for (TAEMeasure isample in cData){
        List<TAESample> sample_list = isample.samples.map<TAESample>((json) => TAESample.fromJson(json)).toList();
        cDatiserie.add(new voltData(DateTime.parse(isample.startdate),sample_list[0].values[0]));
      }
    }
    if (cGrandezza=='Corrente'){
      for (TAEMeasure isample in cData){
        List<TAESample> sample_list = isample.samples.map<TAESample>((json) => TAESample.fromJson(json)).toList();
        cDatiserie.add(new voltData(DateTime.parse(isample.startdate),sample_list[0].values[2]));
      }
    }
    if (cGrandezza=='Frequenza'){
      for (TAEMeasure isample in cData){
        List<TAESample> sample_list = isample.samples.map<TAESample>((json) => TAESample.fromJson(json)).toList();
        cDatiserie.add(new voltData(DateTime.parse(isample.startdate),sample_list[0].values[3]));
      }
    }
    List<charts.Series<voltData, DateTime>> series = [
      charts.Series(
          id: "Volt",
          data: cDatiserie,
          domainFn: (voltData series, _) => series.asseX,
          measureFn: (voltData series, _) => series.volt,
          colorFn: (voltData series, _) => charts.MaterialPalette.blue.shadeDefault
      )
    ];
    return series;
  }

  //disegno dei widget della pagina titolo, dropdown, ...
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Live Data'), centerTitle: true,),
      body: Center(
        child: Container(
          height: 800,
          padding: EdgeInsets.all(20),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: <Widget>[
                  DropdownButton(
                    value: cPiano,
                    items: Piani.map((String items) {
                      return DropdownMenuItem(
                        value: items,
                        child: Text(items),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        cPiano = newValue!;
                      });
                      filterLive();
                    },
                  ),
                  DropdownButton(
                    value: cGrandezza,
                    items: Grandezze.map((String items) {
                      return DropdownMenuItem(
                        value: items,
                        child: Text(items),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        cGrandezza = newValue!;
                      });
                      filterLive();
                    },
                  ),
                  SizedBox(height: 20,),
                  Text(
                    cTime,
                    style: TextStyle(
                        fontWeight: FontWeight.bold
                    ),
                  ),
                  SizedBox(height: 20,),
                  FutureBuilder<List<TAEMeasure>>(
                      future: liveMeasures,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          List<TAEMeasure> data = snapshot.data!;
                          return
                            Expanded(
                              child: new charts.TimeSeriesChart(
                                getVoltData(data),
                                animate: true,
                                primaryMeasureAxis: charts.NumericAxisSpec(
                                    tickProviderSpec:
                                    charts.BasicNumericTickProviderSpec(zeroBound: false),
                                ),
                              )
                            );
                        } else if (snapshot.hasError) {
                          return Text('${snapshot.error}');
                        }
                        return const CircularProgressIndicator();
                      }
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

//classe per prima pagina con dati total-active-energy
class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

//classe per stato della prima pagina con dati total-active-energy
class _HomepageState extends State<Homepage> {
  //definizione della lista di misure di tipo Future
  late Future<List<TAEMeasure>> futureMeasures;

  //inizializzo le date e la dropdown dei piani
  String cDateI = DateFormat('yyyy').format(DateTime.now()) + '-' + DateFormat('MM').format(DateTime.now()) + '-01';
  String cDateF = DateFormat('yyyy').format(DateTime.now()) + '-' + DateFormat('MM').format(DateTime.now()) + '-' + DateFormat('dd').format(DateTime.now());
  String cPiano = 'Scegli il Piano';
  var Piani = ['Scegli il Piano','Via Opera Pia 11a - primo piano','Via Opera Pia 11a - secondo piano','Via Opera Pia 11a - terzo piano'];

  @override
  void initState() {
    super.initState();
    futureMeasures = getMeasuresList(cDateI,cDateF,cPiano);
  }

  void filterResultS(String sDate){
    setState(() {
      futureMeasures = getMeasuresList(sDate,cDateF,cPiano);
    });
  }
  void filterResultE(String eDate){
    setState(() {
      futureMeasures = getMeasuresList(cDateI,eDate,cPiano);
    });
  }

  void filterResult(){
    setState(() {
      futureMeasures = getMeasuresList(cDateI,cDateF,cPiano);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Energy Manager',
        theme: ThemeData(primarySwatch: Colors.blue,),
        home: Scaffold(
          appBar: AppBar(title: const Text('Energy Manager'),),
          body: SingleChildScrollView(padding: EdgeInsets.only(left: 20, right: 20, top: 10),
            child: Form(
              child: Column(
                  children: <Widget>[
                    ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                              context, 
                              MaterialPageRoute(builder: (context) => const LiveData()
                              ),
                          );
                        },
                        child: const Text('Live Data')
                    ),
                    DropdownButton(
                      value: cPiano,
                      items: Piani.map((String items) {
                        return DropdownMenuItem(
                          value: items,
                          child: Text(items),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        cPiano = newValue!;
                        filterResult();
                      },
                    ),
                    DateTimePicker(
                      type: DateTimePickerType.date,
                      initialValue: cDateI,
                      firstDate: DateTime(2022),
                      lastDate: DateTime(2023),
                      icon: Icon(Icons.event),
                      dateLabelText: 'Inizio',
                      onChanged: (value) {
                        setState(() {
                          cDateI = value;
                        });
                        filterResult();
                      },
                      validator: (val) {
                        return null;
                      },
                    ),
                    DateTimePicker(
                      type: DateTimePickerType.date,
                      initialValue: cDateF,
                      firstDate: DateTime(2022),
                      lastDate: DateTime(2023),
                      icon: Icon(Icons.event),
                      dateLabelText: 'Fine',
                      onChanged: (value) {
                        setState(() {
                          cDateF = value;
                        });
                        filterResult();
                      },
                      validator: (val) {
                        print(val);
                        return null;
                      },
                      onSaved: (val) => print(val),
                    ),
                    FutureBuilder<List<TAEMeasure>>(future: futureMeasures, builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          List<TAEMeasure> data = snapshot.data!;
                          return
                            ListView.builder(
                                itemCount: data.length,
                                shrinkWrap: true,
                                itemBuilder: (BuildContext context, int index) {
                                  return Container(
                                    height: 60,
                                    color: Colors.white,
                                    child: Center(child: Text(getValues(data[index]))),
                                    //Text(data[index].thing + '\n' + data[index].samples[0].toString() + '\n' + data[index].startdate)
                                  );
                                }
                            );
                        } else if (snapshot.hasError) {
                          return Text('${snapshot.error}');
                        }
                        return const CircularProgressIndicator();
                      },
                    )
                  ]
              ),
            ),
          ),
        )
    );
  }
}


// FutureBuilder<List<TAEMeasure>>(
//   future: futureMeasures,
//   builder: (context, snapshot) {
//     if (snapshot.hasData) {
//       List<TAEMeasure> data = snapshot.data!;
//       return
//         ListView.builder(
//             itemCount: data.length,
//             shrinkWrap: true,
//             itemBuilder: (BuildContext context, int index) {
//               return Container(
//                 height: 80,
//                 color: Colors.white,
//                 child: Center(child: Text(data[index].thing + '\n' + data[index].samples[0].toString() + '\n' + data[index].startdate)),
//               );
//             }
//         );
//     } else if (snapshot.hasError) {
//       return Text('${snapshot.error}');
//     }
//     return const CircularProgressIndicator();
//   },
// )

// DateTimePicker(
// type: DateTimePickerType.date,
// initialValue: '2022-08-01',
// firstDate: DateTime(2022),
// lastDate: DateTime(2023),
// icon: Icon(Icons.event),
// dateLabelText: 'Inizio',
// onChanged: (val) => print(val),
// validator: (val) {
// print(val);
// return null;
// },
// onSaved: (val) => print(val),
// ),
