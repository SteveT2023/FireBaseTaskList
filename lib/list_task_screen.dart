import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  final TextEditingController itemController = TextEditingController();
  final Set<String> checkBoxToggle = {};

  void addTask(String taskName) async {
    final taskRef = await FirebaseFirestore.instance.collection('Tasks').add({'taskName': taskName});
    await FirebaseFirestore.instance
        .collection('Check_Box')
        .doc(taskRef.id)
        .set({'isChecked': false});
    itemController.clear();
  }

  void deleteTask(String taskID) async {
    await FirebaseFirestore.instance.collection('Tasks').doc(taskID).delete();
    await FirebaseFirestore.instance.collection('Check_Box').doc(taskID).delete();
  }

  void updateTask(String taskID, String taskName) async {
    await FirebaseFirestore.instance.collection('Tasks').doc(taskID).update({'taskName': taskName});
  }

  void checkBoxStatus(String taskID, bool isChecked) async {
    await FirebaseFirestore.instance.collection('Check_Box').doc(taskID).set({'isChecked': isChecked});
  }

  void updateDialog(String taskID, String taskName) {
    final TextEditingController updateController = TextEditingController();
    updateController.text = taskName;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Task'),
          content: TextField(
            controller: updateController,
            decoration: InputDecoration(
              labelText: 'Update Task',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                updateTask(taskID, updateController.text);
                Navigator.of(context).pop();
              },
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Task List'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(50),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: itemController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Task',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => addTask(itemController.text),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('Tasks').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                final tasks = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final id = task.id;
                    final name = task['taskName'];
                    final isToggled = checkBoxToggle.contains(id);
                    return ListTile(
                      title: Text(name),
                      leading: Checkbox(
                        value: isToggled,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              checkBoxToggle.add(id);
                            } else {
                              checkBoxToggle.remove(id);
                            }
                          });
                          checkBoxStatus(id, value ?? false);
                        },
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => deleteTask(id),
                      ),
                      onTap: () => updateDialog(id, name),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}