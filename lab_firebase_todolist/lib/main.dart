import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Firebase Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TodoApp(),
    );
  }
}

class TodoApp extends StatefulWidget {
  const TodoApp({super.key});

  @override
  State<TodoApp> createState() => _TodoAppState();
}

class _TodoAppState extends State<TodoApp> {
  late TextEditingController _texteditController;
  late TextEditingController _descriptionController;

  final List<Map<String, dynamic>> _myList = [];

  @override
  void initState() {
    super.initState();
    _texteditController = TextEditingController();
    _descriptionController = TextEditingController();

    // ดึงข้อมูลจาก Firestore
    FirebaseFirestore.instance.collection('tasks').snapshots().listen((snapshot) {
      setState(() {
        _myList.clear();
        for (var doc in snapshot.docs) {
          _myList.add({'id': doc.id, ...doc.data()});
        }
      });
    });
  }

  void addTodoHandle(BuildContext context, [Map<String, dynamic>? item]) {
    if (item != null) {
      _texteditController.text = item['name'];
      _descriptionController.text = item['note'];
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(item == null ? "Add new task" : "Edit task"),
          content: SizedBox(
            width: 120,
            height: 140,
            child: Column(
              children: [
                TextField(
                  controller: _texteditController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: "Input your task"),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(), labelText: "Description"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (item == null) {
                  // เพิ่มข้อมูลไปยัง Firestore
                  await FirebaseFirestore.instance.collection('tasks').add({
                    'name': _texteditController.text,
                    'note': _descriptionController.text,
                    'status': false,
                  });
                } else {
                  // แก้ไขข้อมูลใน Firestore
                  await FirebaseFirestore.instance
                      .collection('tasks')
                      .doc(item['id'])
                      .update({
                    'name': _texteditController.text,
                    'note': _descriptionController.text,
                  });
                }
                _texteditController.clear();
                _descriptionController.clear();
                Navigator.pop(context);
              },
              child: Text(item == null ? "Save" : "Update"),
            ),
          ],
        );
      },
    );
  }

  void deleteTodoHandle(String id) async {
    await FirebaseFirestore.instance.collection('tasks').doc(id).delete();
    setState(() {
      _myList.removeWhere((item) => item['id'] == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Todo"),
      ),
      body: ListView.builder(
        itemCount: _myList.length,
        itemBuilder: (context, index) {
          return TaskItem(
            item: _myList[index],
            onCheckboxChanged: (value) {
              setState(() {
                _myList[index]['status'] = value;
              });
            },
            onEdit: () {
              addTodoHandle(context, _myList[index]);
            },
            onDelete: () {
              deleteTodoHandle(_myList[index]['id']);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          addTodoHandle(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class TaskItem extends StatelessWidget {
  final Map<String, dynamic> item;
  final ValueChanged<bool?> onCheckboxChanged;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskItem({
    super.key,
    required this.item,
    required this.onCheckboxChanged,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Checkbox(
            value: item["status"],
            onChanged: onCheckboxChanged,
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item["name"],
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  decoration: item["status"] ? TextDecoration.lineThrough : null, // ขีดฆ่าเมื่อทำเสร็จ
                ),
              ),
              if (item["note"] != null) 
                Text(
                  item["note"],
                  style: TextStyle(
                    decoration: item["status"] ? TextDecoration.lineThrough : null, // ขีดฆ่าเมื่อทำเสร็จ
                  ),
                ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
