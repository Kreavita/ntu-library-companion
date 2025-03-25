import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:ntu_library_companion/api/library_service.dart';
import 'package:ntu_library_companion/model/student.dart';

class AddUserForm extends StatefulWidget {
  final String authToken;
  final String studentId;

  const AddUserForm({
    super.key,
    required this.authToken,
    required this.studentId,
  });

  @override
  State<AddUserForm> createState() => _AddUserFormState();
}

class _AddUserFormState extends State<AddUserForm> {
  final _formKey = GlobalKey<FormState>();

  final LibraryService _api = LibraryService();
  String? _studentId;
  String? _searchState;
  bool _ongoingRequest = false;

  /// Contact the Auth Server and obtain a loginToken
  void _findStudent() async {
    if (_ongoingRequest) {
      return;
    }

    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() {
      _ongoingRequest = true;
    });

    Student? student;

    try {
      student = await _api.getMember(
        studentId: _studentId!,
        authToken: widget.authToken,
      );
    } on ClientException {
      setState(() {
        _ongoingRequest = false;
        _searchState = "Search failed, network error.";
      });
      return;
    }

    setState(() {
      _ongoingRequest = false;

      if (student == null) {
        _searchState = "Student '$_studentId' not found";
      } else {
        _searchState = null;

        Navigator.of(context).pop(student);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AlertDialog(
        title: const Text("Add a Contact"),
        icon: const Icon(Icons.person_add_alt_1_outlined),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextFormField(
                validator: (value) {
                  value = value?.trim().toUpperCase();
                  if (value == null || value.isEmpty) {
                    return 'Enter their NTU Student ID';
                  }

                  if (!RegExp(r'^[a-zA-Z]').hasMatch(value)) {
                    return 'Student ID must start with a letter';
                  }

                  if (value.length < 3 || value.length > 16) {
                    return 'ID Must be 3 to 16 characters';
                  }

                  if (RegExp(r"[@\'\;\,\!\/]").hasMatch(value)) {
                    return 'Invalid characters found';
                  }

                  if (value == widget.studentId.toUpperCase()) {
                    return 'Cannot add youself as Contact!';
                  }

                  return null;
                },
                onSaved: (value) {
                  _studentId = value?.trim().toUpperCase();
                },
                decoration: const InputDecoration(hintText: "Student ID"),
              ),
              if (_searchState != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Text(
                    "Error: $_searchState",
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions:
            !_ongoingRequest
                ? <Widget>[
                  MaterialButton(
                    onPressed: () {
                      setState(() {
                        Navigator.pop(context, null);
                      });
                    },
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    onPressed: _findStudent,
                    child: const Text('Add'),
                  ),
                ]
                : [CircularProgressIndicator.adaptive()],
      ),
    );
  }
}
