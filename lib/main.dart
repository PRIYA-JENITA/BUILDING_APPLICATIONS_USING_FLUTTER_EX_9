import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const UpdateStudentApp());
}

class UpdateStudentApp extends StatelessWidget {
  const UpdateStudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Update Student Information',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
        useMaterial3: true,
      ),
      home: const UpdateStudentPage(),
    );
  }
}

class UpdateStudentPage extends StatefulWidget {
  const UpdateStudentPage({super.key});

  @override
  State<UpdateStudentPage> createState() =>
      _UpdateStudentPageState();
}

class _UpdateStudentPageState
    extends State<UpdateStudentPage> {
  final registrationController = TextEditingController();
  final nameController = TextEditingController();
  final departmentController = TextEditingController();
  final marksController = TextEditingController();

  bool isLoading = false;
  bool recordFound = false;

  Future<void> loadStudent() async {
    final regNo = registrationController.text.trim();

    if (regNo.isEmpty) {
      showMessage('Please enter a registration number.');
      return;
    }

    setState(() {
      isLoading = true;
      recordFound = false;
    });

    try {
      final document = await FirebaseFirestore.instance
          .collection('students')
          .doc(regNo)
          .get();

      if (!mounted) return;

      if (!document.exists) {
        nameController.clear();
        departmentController.clear();
        marksController.clear();

        setState(() {
          recordFound = false;
        });

        showMessage('Student record not found.');
        return;
      }

      final data = document.data()!;

      nameController.text = data['name']?.toString() ?? '';
      departmentController.text =
          data['department']?.toString() ?? '';
      marksController.text = data['marks']?.toString() ?? '';

      setState(() {
        recordFound = true;
      });

      showMessage('Student record loaded successfully.');
    } catch (e) {
      if (mounted) {
        showMessage(
          'Unable to retrieve record. Check Firestore access.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> updateStudent() async {
    final regNo = registrationController.text.trim();
    final name = nameController.text.trim();
    final department = departmentController.text.trim();
    final marksText = marksController.text.trim();
    final marks = int.tryParse(marksText);

    if (!recordFound) {
      showMessage('Search for an existing student first.');
      return;
    }

    if (name.isEmpty ||
        department.isEmpty ||
        marksText.isEmpty ||
        marks == null ||
        marks < 0 ||
        marks > 100) {
      showMessage(
        'Enter valid details. Marks must be between 0 and 100.',
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(regNo)
          .update({
        'name': name,
        'department': department,
        'marks': marks,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      showMessage('Student information updated successfully.');
    } catch (e) {
      if (mounted) {
        showMessage(
          'Update failed. Check the record and Firestore permissions.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    registrationController.dispose();
    nameController.dispose();
    departmentController.dispose();
    marksController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Student Information'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 550),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.edit_note,
                  size: 65,
                  color: Colors.teal,
                ),
                const Text(
                  'Update Student Record',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                TextField(
                  controller: registrationController,
                  decoration: const InputDecoration(
                    labelText: 'Registration Number',
                    hintText: 'Enter registration number',
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: isLoading ? null : loadStudent,
                  icon: const Icon(Icons.search),
                  label: const Text('Load Student Record'),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: nameController,
                  enabled: recordFound && !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Student Name',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: departmentController,
                  enabled: recordFound && !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Department',
                    prefixIcon: Icon(Icons.school),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: marksController,
                  enabled: recordFound && !isLoading,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Marks (0–100)',
                    prefixIcon: Icon(Icons.grade),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                ElevatedButton.icon(
                  onPressed: isLoading || !recordFound
                      ? null
                      : updateStudent,
                  icon: const Icon(Icons.save),
                  label: const Text('Update Student Information'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),

                if (isLoading) ...[
                  const SizedBox(height: 20),
                  const Center(
                    child: CircularProgressIndicator(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}