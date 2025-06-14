// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:taskova_shopkeeper/Model/api_config.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class SubscriptionPlansPage extends StatefulWidget {
//   const SubscriptionPlansPage({Key? key}) : super(key: key);

//   @override
//   State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
// }

// class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
//   List<dynamic> plans = [];
//   String? token;
//   int? shopkeeperId;
//   bool loading = true, subscribing = false;

//   @override
//   void initState() {
//     super.initState();
//     loadTokenAndData();
//   }

//   Future<void> loadTokenAndData() async {
//     final prefs = await SharedPreferences.getInstance();
//     token = prefs.getString('access_token');
//     if (token == null) return;
//     await fetchShopkeeperId();
//     await fetchPlans();
//   }

//   Map<String, String> get headers => {
//     'Authorization': 'Bearer $token',
//     'Content-Type': 'application/json',
//   };

//   Future<void> fetchShopkeeperId() async {
//     final res = await http.get(
//       Uri.parse('${ApiConfig.baseUrl}/api/shopkeeper/profile/'),
//       headers: headers,
//     );
//     if (res.statusCode == 200) {
//       final data = json.decode(res.body);
//       shopkeeperId = data['personal_profile']?['id'];
//     }
//   }

//   Future<void> fetchPlans() async {
//     final res = await http.get(
//       Uri.parse('${ApiConfig.baseUrl}/api/subscription-plans/'),
//       headers: headers,
//     );
//     if (res.statusCode == 200) {
//       setState(() {
//         plans = json.decode(res.body);
//         loading = false;
//       });
//     } else {
//       setState(() => loading = false);
//       showSnack('Failed to load plans');
//     }
//   }

//   // Stripe checkout function
//   Future<void> createStripeCheckoutSimple(dynamic plan) async {
//     if (token == null) return showSnack('Login required');

//     setState(() => subscribing = true);

//     try {
//       final url = '${ApiConfig.baseUrl}/api/stripe/checkout/';
//       final body = {"plan_id": plan['id'].toString()};

//       print('POST $url');
//       print('Body: $body');
//       print('Token: ${token?.substring(0, 20)}...');

//       final response = await http.post(
//         Uri.parse(url),
//         headers: {
//           'Content-Type': 'application/json',
//           'Authorization': 'Bearer $token',
//         },
//         body: json.encode(body),
//       );

//       print('Status: ${response.statusCode}');
//       print('Response: ${response.body}');

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         final data = json.decode(response.body);
//         final checkoutUrl = data['checkout_url'];

//         if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
//           print('Opening payment page in app: $checkoutUrl');

//           // Navigate to in-app payment page
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder:
//                   (context) => StripePaymentPage(
//                     checkoutUrl: checkoutUrl,
//                     onPaymentComplete: () {
//                       Navigator.pop(context); // Close payment page
//                       showSnack('Payment completed successfully!');
//                       // Optionally refresh plans or check subscription status
//                     },
//                     onPaymentCancelled: () {
//                       Navigator.pop(context); // Close payment page
//                       showSnack('Payment cancelled');
//                     },
//                   ),
//             ),
//           );
//         } else {
//           showSnack('No checkout URL received');
//         }
//       } else {
//         showSnack('API Error: ${response.statusCode} - ${response.body}');
//       }
//     } catch (e) {
//       showSnack('Error: $e');
//       print('Exception: $e');
//     } finally {
//       setState(() => subscribing = false);
//     }
//   }

//   void showSnack(String message) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(message)));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Subscription Plans")),
//       body:
//           loading
//               ? const Center(child: CircularProgressIndicator())
//               : ListView.builder(
//                 itemCount: plans.length,
//                 itemBuilder: (_, i) {
//                   final plan = plans[i];
//                   return Card(
//                     margin: const EdgeInsets.all(12),
//                     child: ListTile(
//                       title: Text(plan['name']),
//                       subtitle: Text(
//                         "₹${plan['price']} • ${plan['description']}",
//                       ),
//                       trailing: ElevatedButton(
//                         onPressed:
//                             subscribing
//                                 ? null
//                                 : () => createStripeCheckoutSimple(plan),
//                         child:
//                             subscribing
//                                 ? const SizedBox(
//                                   height: 16,
//                                   width: 16,
//                                   child: CircularProgressIndicator(
//                                     strokeWidth: 2,
//                                   ),
//                                 )
//                                 : const Text("Subscribe"),
//                       ),
//                     ),
//                   );
//                 },
//               ),
//     );
//   }
// }

// // Stripe Payment WebView Page
// class StripePaymentPage extends StatefulWidget {
//   final String checkoutUrl;
//   final VoidCallback onPaymentComplete;
//   final VoidCallback onPaymentCancelled;

//   const StripePaymentPage({
//     Key? key,
//     required this.checkoutUrl,
//     required this.onPaymentComplete,
//     required this.onPaymentCancelled,
//   }) : super(key: key);

//   @override
//   State<StripePaymentPage> createState() => _StripePaymentPageState();
// }

// class _StripePaymentPageState extends State<StripePaymentPage> {
//   late WebViewController controller;
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     controller =
//         WebViewController()
//           ..setJavaScriptMode(JavaScriptMode.unrestricted)
//           ..setNavigationDelegate(
//             NavigationDelegate(
//               onPageStarted: (String url) {
//                 print('Page started loading: $url');
//               },
//               onPageFinished: (String url) {
//                 setState(() {
//                   isLoading = false;
//                 });
//                 print('Page finished loading: $url');

//                 // Check if payment is complete
//                 if (url.contains('success') || url.contains('payment_intent')) {
//                   widget.onPaymentComplete();
//                 } else if (url.contains('cancel')) {
//                   widget.onPaymentCancelled();
//                 }
//               },
//               onNavigationRequest: (NavigationRequest request) {
//                 print('Navigation request: ${request.url}');

//                 // Handle payment completion
//                 if (request.url.contains('success') ||
//                     request.url.contains('payment_intent') ||
//                     request.url.contains('stripe.com/payments/')) {
//                   widget.onPaymentComplete();
//                   return NavigationDecision.prevent;
//                 }

//                 // Handle payment cancellation
//                 if (request.url.contains('cancel')) {
//                   widget.onPaymentCancelled();
//                   return NavigationDecision.prevent;
//                 }

//                 return NavigationDecision.navigate;
//               },
//             ),
//           )
//           ..loadRequest(Uri.parse(widget.checkoutUrl));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Complete Payment'),
//         leading: IconButton(
//           icon: const Icon(Icons.close),
//           onPressed: widget.onPaymentCancelled,
//         ),
//       ),
//       body: Stack(
//         children: [
//           WebViewWidget(controller: controller),
//           if (isLoading) const Center(child: CircularProgressIndicator()),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskova_shopkeeper/Model/api_config.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SubscriptionPlansPage extends StatefulWidget {
  const SubscriptionPlansPage({Key? key}) : super(key: key);

  @override
  State<SubscriptionPlansPage> createState() => _SubscriptionPlansPageState();
}

class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
  List<dynamic> plans = [];
  String? token;
  int? shopkeeperId;
  bool loading = true, subscribing = false;

  @override
  void initState() {
    super.initState();
    loadTokenAndData();
  }

  Future<void> loadTokenAndData() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('access_token');
    if (token == null) return;
    await fetchShopkeeperId();
    await fetchPlans();
  }

  Map<String, String> get headers => {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
  };

  Future<void> fetchShopkeeperId() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/shopkeeper/profile/'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      shopkeeperId = data['personal_profile']?['id'];
    }
  }

  Future<void> fetchPlans() async {
    final res = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/api/subscription-plans/'),
      headers: headers,
    );
    if (res.statusCode == 200) {
      setState(() {
        plans = json.decode(res.body);
        loading = false;
      });
    } else {
      setState(() => loading = false);
      showSnack('Failed to load plans');
    }
  }

  Future<void> createStripeCheckoutSimple(dynamic plan) async {
    if (token == null) return showSnack('Login required');

    setState(() => subscribing = true);

    try {
      final url = '${ApiConfig.baseUrl}/api/stripe/checkout/';
      final body = {"plan_id": plan['id'].toString()};

      print('POST $url');
      print('Body: $body');
      print('Token: ${token?.substring(0, 20)}...');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(body),
      );

      print('Status: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final checkoutUrl = data['checkout_url'];

        if (checkoutUrl != null && checkoutUrl.isNotEmpty) {
          print('Opening payment page in app: $checkoutUrl');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => StripePaymentPage(
                    checkoutUrl: checkoutUrl,
                    onPaymentComplete: () {
                      Navigator.pop(context);
                      showSnack('Payment completed successfully!');
                    },
                    onPaymentCancelled: () {
                      Navigator.pop(context);
                      showSnack('Payment cancelled');
                    },
                  ),
            ),
          );
        } else {
          showSnack('No checkout URL received');
        }
      } else {
        showSnack('API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      showSnack('Error: $e');
      print('Exception: $e');
    } finally {
      setState(() => subscribing = false);
    }
  }

  void showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.blue.shade700),
    );
  }

  Widget _buildFeatureItem(String key, dynamic value) {
    String displayText = '';
    IconData icon = Icons.check_circle;
    Color iconColor = Colors.green;

    if (value is bool) {
      displayText = _formatFeatureKey(key);
      if (!value) {
        icon = Icons.cancel;
        iconColor = Colors.red.shade400;
      }
    } else if (value is String) {
      displayText = '$key: $value';
    } else {
      displayText = '$key: ${value.toString()}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFeatureKey(String key) {
    return key
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _extractPricePerDay(Map<String, dynamic> features) {
    if (features.containsKey('price_per_day')) {
      return features['price_per_day'].toString();
    }
    return 'Contact for pricing';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Choose Your Plan",
          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body:
          loading
              ? Center(
                child: CircularProgressIndicator(color: Colors.blue.shade700),
              )
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  itemCount: plans.length,
                  itemBuilder: (context, index) {
                    final plan = plans[index];
                    final features =
                        plan['features'] as Map<String, dynamic>? ?? {};
                    final isBasic = plan['plan_type'] == 'BASIC';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors:
                              isBasic
                                  ? [Colors.blue.shade600, Colors.blue.shade800]
                                  : [
                                    Colors.blue.shade700,
                                    Colors.blue.shade900,
                                  ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.shade200,
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          if (!isBasic)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade400,
                                  borderRadius: const BorderRadius.only(
                                    topRight: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  'POPULAR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            plan['name'] ?? 'Unknown Plan',
                                            style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            plan['description'] ?? '',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.blue.shade100,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          _extractPricePerDay(features),
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'per day',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue.shade100,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Features',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.blue.shade800,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      ...features.entries
                                          .where(
                                            (entry) =>
                                                entry.key != 'price_per_day',
                                          )
                                          .map(
                                            (entry) => _buildFeatureItem(
                                              _formatFeatureKey(entry.key),
                                              entry.value,
                                            ),
                                          )
                                          .toList(),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton(
                                    onPressed:
                                        subscribing
                                            ? null
                                            : () => createStripeCheckoutSimple(
                                              plan,
                                            ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.blue.shade800,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      elevation: 0,
                                    ),
                                    child:
                                        subscribing
                                            ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.blue.shade800,
                                              ),
                                            )
                                            : Text(
                                              'Subscribe Now',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.blue.shade800,
                                              ),
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
    );
  }
}

// Stripe Payment WebView Page
class StripePaymentPage extends StatefulWidget {
  final String checkoutUrl;
  final VoidCallback onPaymentComplete;
  final VoidCallback onPaymentCancelled;

  const StripePaymentPage({
    Key? key,
    required this.checkoutUrl,
    required this.onPaymentComplete,
    required this.onPaymentCancelled,
  }) : super(key: key);

  @override
  State<StripePaymentPage> createState() => _StripePaymentPageState();
}

class _StripePaymentPageState extends State<StripePaymentPage> {
  late WebViewController controller;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (String url) {
                print('Page started loading: $url');
              },
              onPageFinished: (String url) {
                setState(() {
                  isLoading = false;
                });
                print('Page finished loading: $url');

                if (url.contains('success') || url.contains('payment_intent')) {
                  widget.onPaymentComplete();
                } else if (url.contains('cancel')) {
                  widget.onPaymentCancelled();
                }
              },
              onNavigationRequest: (NavigationRequest request) {
                print('Navigation request: ${request.url}');

                if (request.url.contains('success') ||
                    request.url.contains('payment_intent') ||
                    request.url.contains('stripe.com/payments/')) {
                  widget.onPaymentComplete();
                  return NavigationDecision.prevent;
                }

                if (request.url.contains('cancel')) {
                  widget.onPaymentCancelled();
                  return NavigationDecision.prevent;
                }

                return NavigationDecision.navigate;
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.checkoutUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Complete Payment',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue.shade800,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onPaymentCancelled,
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading)
            Center(
              child: CircularProgressIndicator(color: Colors.blue.shade700),
            ),
        ],
      ),
    );
  }
}
