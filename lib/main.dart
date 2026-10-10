import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

const Color blue = Color(0xFF1E3A8A);
const Color red = Color(0xFFD62828);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Student Enrollment',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class Subject {
  TextEditingController name = TextEditingController();
  TimeOfDay? start;
  TimeOfDay? end;
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int page = 0;
  bool loading = false;

  final formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final sectionController = TextEditingController();
  final courseController = TextEditingController();
  List<Subject> subjects = [Subject()];

  int toMinutes(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> chooseTime(Subject subject, bool isStart) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        subject.start = picked;
      } else {
        subject.end = picked;
      }
    });
  }

  void goNext() {
    if (page == 0) {
      if (!formKey.currentState!.validate()) return;
    }
    if (page == 1) {
      for (var s in subjects) {
        if (s.name.text.trim().isEmpty) {
          showMessage('Please enter the subject name');
          return;
        }
        if (s.start == null || s.end == null) {
          showMessage('Please select the start and end time');
          return;
        }
        if (toMinutes(s.end!) <= toMinutes(s.start!)) {
          showMessage('End time must be later than start time');
          return;
        }
      }
    }
    setState(() {
      page = page + 1;
    });
  }

  Future<void> saveData() async {
    setState(() {
      loading = true;
    });
    try {
      List<Map<String, String>> subjectList = [];
      for (var s in subjects) {
        subjectList.add({
          'subject': s.name.text.trim(),
          'startTime': s.start!.format(context),
          'endTime': s.end!.format(context),
        });
      }
      await FirebaseFirestore.instance.collection('students').add({
        'name': nameController.text.trim(),
        'section': sectionController.text.trim(),
        'course': courseController.text.trim(),
        'subjects': subjectList,
        'createdAt': FieldValue.serverTimestamp(),
      });
      showMessage('Data saved successfully');
      setState(() {
        nameController.clear();
        sectionController.clear();
        courseController.clear();
        subjects = [Subject()];
        page = 0;
      });
    } catch (e) {
      showMessage('Error: $e');
    }
    setState(() {
      loading = false;
    });
  }

  InputDecoration inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: blue),
      border: const OutlineInputBorder(),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: red, width: 2),
      ),
    );
  }

  Widget tab(String title, int index) {
    bool active = page == index;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? red : Colors.white,
          border: Border.all(color: blue),
        ),
        child: Text(
          '${index + 1}. $title',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? Colors.white : blue,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget firstPage() {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: nameController,
            decoration: inputStyle('Name', Icons.person),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: sectionController,
            decoration: inputStyle('Section', Icons.group),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your section';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: courseController,
            decoration: inputStyle('Course', Icons.school),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your course';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget timeButton(String label, TimeOfDay? time, Subject subject, bool isStart) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () => chooseTime(subject, isStart),
        icon: const Icon(Icons.access_time, color: blue),
        label: Text(
          time == null ? label : time.format(context),
          style: const TextStyle(color: blue),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          side: const BorderSide(color: blue),
        ),
      ),
    );
  }

  Widget secondPage() {
    return Column(
      children: [
        for (int i = 0; i < subjects.length; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text(
                        'Subject ${i + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: red,
                        ),
                      ),
                      const Spacer(),
                      if (subjects.length > 1)
                        IconButton(
                          icon: const Icon(Icons.delete, color: red),
                          onPressed: () {
                            setState(() {
                              subjects.removeAt(i);
                            });
                          },
                        ),
                    ],
                  ),
                  TextField(
                    controller: subjects[i].name,
                    decoration: inputStyle('Subject', Icons.book),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      timeButton('Start Time', subjects[i].start, subjects[i], true),
                      const SizedBox(width: 8),
                      timeButton('End Time', subjects[i].end, subjects[i], false),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              subjects.add(Subject());
            });
          },
          icon: const Icon(Icons.add),
          label: const Text('Add Subject'),
          style: ElevatedButton.styleFrom(
            backgroundColor: blue,
            foregroundColor: Colors.white,
            minimumSize: const Size.fromHeight(46),
          ),
        ),
      ],
    );
  }

  Widget thirdPage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.person, color: blue),
                title: const Text('Name'),
                trailing: Text(nameController.text),
              ),
              ListTile(
                leading: const Icon(Icons.group, color: blue),
                title: const Text('Section'),
                trailing: Text(sectionController.text),
              ),
              ListTile(
                leading: const Icon(Icons.school, color: blue),
                title: const Text('Course'),
                trailing: Text(courseController.text),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Subjects',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: red),
        ),
        const SizedBox(height: 8),
        for (var s in subjects)
          Card(
            child: ListTile(
              leading: const Icon(Icons.book, color: blue),
              title: Text(s.name.text),
              subtitle: Text(
                '${s.start!.format(context)} - ${s.end!.format(context)}',
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (page == 0) {
      body = firstPage();
    } else if (page == 1) {
      body = secondPage();
    } else {
      body = thirdPage();
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        title: const Text('Student Enrollment'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Row(
                children: [
                  tab('Details', 0),
                  tab('Subjects', 1),
                  tab('Review', 2),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: body,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (page > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: loading
                              ? null
                              : () {
                                  setState(() {
                                    page = page - 1;
                                  });
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: blue,
                            side: const BorderSide(color: blue),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                    if (page > 0) const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: loading
                            ? null
                            : () {
                                if (page == 2) {
                                  saveData();
                                } else {
                                  goNext();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: loading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(page == 2 ? 'Save' : 'Next'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}