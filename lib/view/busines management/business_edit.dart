import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BusinessFetchAndEditPage extends StatefulWidget {
  const BusinessFetchAndEditPage({super.key});

  @override
  State<BusinessFetchAndEditPage> createState() => _BusinessFetchAndEditPageState();
}

class _BusinessFetchAndEditPageState extends State<BusinessFetchAndEditPage> {
  final _formKey = GlobalKey<FormState>();

  TextEditingController _name = TextEditingController();
  TextEditingController _address = TextEditingController();
  TextEditingController _email = TextEditingController();
  TextEditingController _contact = TextEditingController();
  TextEditingController _postcode = TextEditingController();
  TextEditingController _lat = TextEditingController();
  TextEditingController _lng = TextEditingController();

  String? _token;
  int? _businessId;
  File? _image;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAndFetchFirstBusiness();
  }

  Future<void> _loadAndFetchFirstBusiness() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');

    if (_token == null) {
      setState(() {
        _error = "Access token missing.";
        _loading = false;
      });
      return;
    }

    final res = await http.get(
      Uri.parse('https://taskova.co.uk/api/shopkeeper/businesses/'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (res.statusCode == 200) {
      List businesses = jsonDecode(res.body);
      if (businesses.isEmpty) {
        setState(() {
          _error = "No business found.";
          _loading = false;
        });
        return;
      }

      final first = businesses.first;
      setState(() {
        _businessId = first['id'];
        _name.text = first['name'] ?? '';
        _address.text = first['address'] ?? '';
        _email.text = first['email'] ?? '';
        _contact.text = first['contact_number'] ?? '';
        _postcode.text = first['postcode'] ?? '';
        _lat.text = first['latitude']?.toString() ?? '';
        _lng.text = first['longitude']?.toString() ?? '';
        _loading = false;
      });
    } else {
      setState(() {
        _error = "Failed to fetch businesses.";
        _loading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _image = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (_businessId == null || !_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final request = http.MultipartRequest(
      'PUT',
      Uri.parse('https://taskova.co.uk/api/shopkeeper/businesses/$_businessId/'),
    );

    request.headers['Authorization'] = 'Bearer $_token';
    request.fields.addAll({
      'name': _name.text,
      'address': _address.text,
      'email': _email.text,
      'contact_number': _contact.text,
      'postcode': _postcode.text,
      'latitude': _lat.text,
      'longitude': _lng.text,
    });

    if (_image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Business updated")));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $body")));
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!)));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Business')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _name, decoration: InputDecoration(labelText: 'Name')),
              TextFormField(controller: _address, decoration: InputDecoration(labelText: 'Address')),
              TextFormField(
                controller: _email,
                decoration: InputDecoration(labelText: 'Email'),
                readOnly: true,
              ),
              TextFormField(controller: _contact, decoration: InputDecoration(labelText: 'Contact Number')),
              TextFormField(controller: _postcode, decoration: InputDecoration(labelText: 'Postcode')),
              TextFormField(controller: _lat, decoration: InputDecoration(labelText: 'Latitude')),
              TextFormField(controller: _lng, decoration: InputDecoration(labelText: 'Longitude')),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickImage,
                child: Text(_image == null ? 'Pick Image' : 'Change Image'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _submit, child: const Text('Update Business')),
            ],
          ),
        ),
      ),
    );
  }
}
