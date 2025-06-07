// import 'dart:convert';
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:image_picker/image_picker.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class BusinessFetchAndEditPage extends StatefulWidget {
//   const BusinessFetchAndEditPage({super.key});

//   @override
//   State<BusinessFetchAndEditPage> createState() => _BusinessFetchAndEditPageState();
// }

// class _BusinessFetchAndEditPageState extends State<BusinessFetchAndEditPage> {
//   final _formKey = GlobalKey<FormState>();

//   TextEditingController _name = TextEditingController();
//   TextEditingController _address = TextEditingController();
//   TextEditingController _email = TextEditingController();
//   TextEditingController _contact = TextEditingController();
//   TextEditingController _postcode = TextEditingController();
//   TextEditingController _lat = TextEditingController();
//   TextEditingController _lng = TextEditingController();

//   String? _token;
//   int? _businessId;
//   File? _image;
//   bool _loading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _loadAndFetchFirstBusiness();
//   }

//   Future<void> _loadAndFetchFirstBusiness() async {
//     final prefs = await SharedPreferences.getInstance();
//     _token = prefs.getString('access_token');

//     if (_token == null) {
//       setState(() {
//         _error = "Access token missing.";
//         _loading = false;
//       });
//       return;
//     }

//     final res = await http.get(
//       Uri.parse('https://taskova.co.uk/api/shopkeeper/businesses/'),
//       headers: {'Authorization': 'Bearer $_token'},
//     );

//     if (res.statusCode == 200) {
//       List businesses = jsonDecode(res.body);
//       if (businesses.isEmpty) {
//         setState(() {
//           _error = "No business found.";
//           _loading = false;
//         });
//         return;
//       }

//       final first = businesses.first;
//       setState(() {
//         _businessId = first['id'];
//         _name.text = first['name'] ?? '';
//         _address.text = first['address'] ?? '';
//         _email.text = first['email'] ?? '';
//         _contact.text = first['contact_number'] ?? '';
//         _postcode.text = first['postcode'] ?? '';
//         _lat.text = first['latitude']?.toString() ?? '';
//         _lng.text = first['longitude']?.toString() ?? '';
//         _loading = false;
//       });
//     } else {
//       setState(() {
//         _error = "Failed to fetch businesses.";
//         _loading = false;
//       });
//     }
//   }

//   Future<void> _pickImage() async {
//     final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
//     if (picked != null) {
//       setState(() => _image = File(picked.path));
//     }
//   }

//   Future<void> _submit() async {
//     if (_businessId == null || !_formKey.currentState!.validate()) return;

//     setState(() => _loading = true);

//     final request = http.MultipartRequest(
//       'PUT',
//       Uri.parse('https://taskova.co.uk/api/shopkeeper/businesses/$_businessId/'),
//     );

//     request.headers['Authorization'] = 'Bearer $_token';
//     request.fields.addAll({
//       'name': _name.text,
//       'address': _address.text,
//       'email': _email.text,
//       'contact_number': _contact.text,
//       'postcode': _postcode.text,
//       'latitude': _lat.text,
//       'longitude': _lng.text,
//     });

//     if (_image != null) {
//       request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
//     }

//     final response = await request.send();
//     final body = await response.stream.bytesToString();

//     if (response.statusCode == 200) {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Business updated")));
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $body")));
//     }

//     setState(() => _loading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
//     if (_error != null) return Scaffold(body: Center(child: Text(_error!)));

//     return Scaffold(
//       appBar: AppBar(title: const Text('Edit Business')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: ListView(
//             children: [
//               TextFormField(controller: _name, decoration: InputDecoration(labelText: 'Name')),
//               TextFormField(controller: _address, decoration: InputDecoration(labelText: 'Address')),
//               TextFormField(
//                 controller: _email,
//                 decoration: InputDecoration(labelText: 'Email'),
//                 readOnly: true,
//               ),
//               TextFormField(controller: _contact, decoration: InputDecoration(labelText: 'Contact Number')),
//               TextFormField(controller: _postcode, decoration: InputDecoration(labelText: 'Postcode')),
//               TextFormField(controller: _lat, decoration: InputDecoration(labelText: 'Latitude')),
//               TextFormField(controller: _lng, decoration: InputDecoration(labelText: 'Longitude')),
//               const SizedBox(height: 10),
//               ElevatedButton(
//                 onPressed: _pickImage,
//                 child: Text(_image == null ? 'Pick Image' : 'Change Image'),
//               ),
//               const SizedBox(height: 20),
//               ElevatedButton(onPressed: _submit, child: const Text('Update Business')),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_shopkeeper/Model/postcode.dart';
// Import your PostcodeSearchWidget
// import 'package:taskova_shopkeeper/widgets/postcode_search_widget.dart';

class BusinessFetchAndEditPage extends StatefulWidget {
  const BusinessFetchAndEditPage({super.key});

  @override
  State<BusinessFetchAndEditPage> createState() =>
      _BusinessFetchAndEditPageState();
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
      Uri.parse('http://192.168.20.29:8001/api/shopkeeper/businesses/'),
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

  // Handle address selection from PostcodeSearchWidget
  void _onAddressSelected(double latitude, double longitude, String address) {
    setState(() {
      _lat.text = latitude.toString();
      _lng.text = longitude.toString();
      _address.text = address;
    });

    // Show confirmation to user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Address updated successfully'),
        duration: Duration(seconds: 2),
      ),
    );
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
      Uri.parse(
        'http://192.168.20.29:8001/api/shopkeeper/businesses/$_businessId/',
      ),
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
      request.files.add(
        await http.MultipartFile.fromPath('image', _image!.path),
      );
    }

    final response = await request.send();
    final body = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Business updated")));
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $body")));
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_error != null) return Scaffold(body: Center(child: Text(_error!)));

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Business')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter business name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Postcode Search Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Search by Postcode',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      PostcodeSearchWidget(
                        onAddressSelected: _onAddressSelected,
                        placeholderText: 'Enter postcode to update address',
                        postcodeController: _postcode,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Address field (now read-only, updated by postcode search)
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  helperText: 'Updated automatically when postcode is selected',
                ),
                readOnly: true,
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
                readOnly: true,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _contact,
                decoration: const InputDecoration(labelText: 'Contact Number'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter contact number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Postcode field (read-only, managed by PostcodeSearchWidget)
              TextFormField(
                controller: _postcode,
                decoration: const InputDecoration(
                  labelText: 'Postcode',
                  helperText: 'Use postcode search above to update',
                ),
                readOnly: true,
              ),
              const SizedBox(height: 16),

              // Coordinates section (read-only, updated automatically)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _lat,
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        helperText: 'Auto-updated',
                      ),
                      readOnly: true,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _lng,
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        helperText: 'Auto-updated',
                      ),
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Image section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Business Image',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_image != null) ...[
                        Container(
                          width: double.infinity,
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: FileImage(_image!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(
                          _image == null
                              ? Icons.add_photo_alternate
                              : Icons.change_circle,
                        ),
                        label: Text(
                          _image == null ? 'Add Image' : 'Change Image',
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 45),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Submit button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5DC1),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Update Business',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
