import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'noti_services.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();

  NotificationService().initNotification();
  tz.initializeTimeZones();
  runApp(const MyApp());
}
DateTime time = DateTime.now();
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purpleAccent),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {

  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  //step2
  List<Map<String, dynamic>> _journals = [];
  bool _isLoading = true;
  String timedate = '';
  void _refreshJournals() async {
    final data = await DatabaseHelper.getItems();
    setState(() {
      _journals = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    DatabaseHelper.openDatabase().then((_) => _refreshJournals()); // opening database connection
    setState(() {
    });
  }


  @override
  void dispose() {
    DatabaseHelper.closeDatabase(); // closing database connection
    super.dispose();
  }

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();



  void _showForm(int? id) async {
    if (id != null) {
      final existingJournal =
      _journals.firstWhere((element) => element['id'] == id);
      _titleController.text = existingJournal['title'];
      _descriptionController.text = existingJournal['description'];
      _dateController.text = existingJournal['date'];
      _timeController.text = existingJournal['time'];
    }

    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
          padding: EdgeInsets.only(
            top: 15,
            left: 15,
            right: 15,
            bottom: MediaQuery.of(context).viewInsets.bottom + 40,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                TextFormField(
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Enter Event';
                    } else {
                      return null;
                    }
                  },
                  controller: _titleController,
                  decoration: const InputDecoration(hintText: 'Event Name',
                      icon: Icon(Icons.drive_file_rename_outline, color: Colors.indigo,)),
                ),
                SizedBox(height: 10,),
                TextFormField(
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Give Event\'s Description';
                    } else {
                      return null;
                    }
                  },
                  controller: _descriptionController,
                  decoration: const InputDecoration(hintText: 'Description',
                      icon: Icon(Icons.message_outlined, color: Colors.indigo)),
                ),
                SizedBox(height: 10,),
                TextFormField(
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Pick Date';
                    } else {
                      return null;
                    }
                  },
                  readOnly: true,
                  controller: _dateController,
                  decoration: const InputDecoration(hintText: 'Event Date',
                      icon: Icon(Icons.date_range_outlined, color: Colors.indigo,)),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2050));
                    if (pickedDate != Null) {
                      _dateController.text = DateFormat("dd-MM-yyyy").format(pickedDate!);
                    }
                  },
                ),
                SizedBox(height: 10,),
                TextFormField(
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Event Time Important';
                } else {
                  return null;
                }
              },
              readOnly: true,
              controller: _timeController,
              decoration: const InputDecoration(hintText: 'Enter Time',
                  icon: Icon(Icons.access_time_outlined, color: Colors.indigo,)),
              onTap: () async {
                var time = await showTimePicker(
                    context: context, initialTime: TimeOfDay.now());

                if (time != null) {
                  _timeController.text = time.format(context);
                }
              },
            ),
                SizedBox(height: 20,),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      // Save new journal
                      if (id == null) {
                        await _addItem();
                      }
                      if (id != null) {
                        await _updateItem(id);
                      }
                      NotificationService().scheduleNotification(
                          title: 'Scheduled Notification',
                          body: '$time',
                          scheduledNotificationDateTime: time);
                      // Clear the text fields
                      _titleController.text = '';
                      _descriptionController.text = '';
                      _dateController.text = '';
                      _timeController.text = '';
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(id == null ? 'Create Event' : 'Update Event', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),),
                )
              ],
            ),
          ),
        ));
  }

  Future<void> _addItem() async {
    await DatabaseHelper.createItem(
        _titleController.text, _descriptionController.text, _dateController.text, _timeController.text);
    _refreshJournals();
  }

  Future<void> _updateItem(int id) async {
    await DatabaseHelper.updateItem(
        id, _titleController.text, _descriptionController.text, _dateController.text, _timeController.text);
    _refreshJournals();
  }

  void _deleteItem(int id) async {
    await DatabaseHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Event Deleted'),
    ));
    _refreshJournals();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text('KnockMe', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),),
        actions: [
          IconButton(onPressed: (){
            _showForm(null);
          },
              icon: Icon(Icons.alarm, size: 30, color: Colors.indigo,))
        ],
      ),
      body: _isLoading ? // if ``_isLoading == true`` this widget works
      Container(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      )
      // else
          : ListView.builder(
        itemCount: _journals.length,
        itemBuilder: (context, index) =>
            ExpansionTile(
              leading: Icon(Icons.event_available_outlined, color: Colors.indigo,),
              subtitle:  Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_journals[index]['date'],
                  style: TextStyle(fontWeight: FontWeight.bold),),
                  Text(_journals[index]['time'],
                    style: TextStyle(fontWeight: FontWeight.bold),),
                ],
              ),
              title: Text(_journals[index]['title'].toString().toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold, fontStyle: FontStyle.italic,
                  fontSize: 16,),),
              children: [
                Row(
                  children: [
                    Container(
                     // height: screenHeight,
                      width: screenWidth,
                      child: InkWell(
                        onTap: (){
                          showDialog(context: context,
                              builder: (BuildContext context){
                            return AlertDialog(
                              backgroundColor: Colors.white,
                              title: Text('Your Event', style: TextStyle(fontWeight: FontWeight.bold),),
                              actions: [
                                Column(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(_journals[index]['title'].toString(),style: TextStyle(color: Colors.red)),
                                        SizedBox(height: 8,),
                                        Text(_journals[index]['description'].toString()),
                                        SizedBox(height: 8,),
                                        Text(_journals[index]['date'], style: TextStyle(color: Colors.indigo),),
                                        SizedBox(height: 8,),
                                        Text(_journals[index]['time'], style: TextStyle(color: Colors.green)),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            ElevatedButton(onPressed: (){
                                              Navigator.of(context).pop();
                                            },
                                                child: Text('OK', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)))
                                          ],
                                        )
                                      ],
                                    ),
                                  ],
                                )
                              ],
                            );
                              });
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              title: Text(_journals[index]['title'].toString(),
                              overflow: TextOverflow.visible,
                              style: TextStyle( fontWeight: FontWeight.bold),),
                            ),
                            ListTile(
                              title: Text(_journals[index]['description'].toString(),
                                overflow: TextOverflow.visible,
                                style: TextStyle( fontWeight: FontWeight.bold),),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue,),
                      onPressed: () => _showForm(_journals[index]['id']),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red,),
                      onPressed: () =>
                          _deleteItem(_journals[index]['id']),
                    ),
                  ],
                ),

              ],
            ),
      ),
    );
  }
}


