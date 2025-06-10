// // Updated SubscriptionPlansPage with complete subscription functionality
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:taskova_shopkeeper/Model/api_config.dart';

// class SubscriptionPlansPage extends StatefulWidget {
//   const SubscriptionPlansPage({Key? key}) : super(key: key);

//   @override
//   _SubscriptionPlansPageState createState() => _SubscriptionPlansPageState();
// }

// class _SubscriptionPlansPageState extends State<SubscriptionPlansPage> {
//   List<dynamic> plans = [];
//   bool isLoading = true;
//   bool isSubscribing = false;
//   String? _authToken;
//   int? _shopkeeperId;

//   @override
//   void initState() {
//     super.initState();
//     _loadToken().then((_) {
//       fetchPlans();
//       _fetchShopkeeperId();
//     });
//   }

//   Future<void> _loadToken() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       setState(() {
//         _authToken = prefs.getString('access_token');
//       });
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Failed to load token: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Map<String, String> _getAuthHeaders() {
//     return {
//       'Authorization': 'Bearer $_authToken',
//       'Content-Type': 'application/json',
//     };
//   }

//   Future<void> _fetchShopkeeperId() async {
//     if (_authToken == null) return;

//     try {
//       final url = Uri.parse('${ApiConfig.baseUrl}/api/shopkeeper/profile/');
//       final response = await http.get(url, headers: _getAuthHeaders());

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         final profileId = data['personal_profile']?['id'];
//         if (mounted && profileId != null) {
//           setState(() {
//             _shopkeeperId = profileId;
//           });
//         }
//       }
//     } catch (e) {
//       debugPrint('Error fetching shopkeeper profile: $e');
//     }
//   }

//   Future<void> fetchPlans() async {
//     if (_authToken == null) return;

//     try {
//       final response = await http.get(
//         Uri.parse('${ApiConfig.baseUrl}/api/subscription-plans/'),
//         headers: _getAuthHeaders(),
//       );

//       if (response.statusCode == 200) {
//         setState(() {
//           plans = json.decode(response.body);
//           isLoading = false;
//         });
//       } else {
//         setState(() {
//           isLoading = false;
//         });
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Failed to load plans: ${response.statusCode}')),
//           );
//         }
//       }
//     } catch (e) {
//       setState(() {
//         isLoading = false;
//       });
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text('Error loading plans: ${e.toString()}')),
//         );
//       }
//     }
//   }

//   Future<void> _subscribeToPlan(dynamic plan) async {
//     if (_authToken == null || _shopkeeperId == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Authentication error. Please login again.')),
//       );
//       return;
//     }

//     setState(() {
//       isSubscribing = true;
//     });

//     try {
//       final subscriptionData = {
//         'plan_id': plan['id'],
//         'shopkeeper_id': _shopkeeperId,
//         'payment_method': 'card', // You can modify this based on your payment integration
//       };

//       final response = await http.post(
//         Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/subscribe/'),
//         headers: _getAuthHeaders(),
//         body: json.encode(subscriptionData),
//       );

//       if (mounted) {
//         if (response.statusCode == 200 || response.statusCode == 201) {
//           final responseData = json.decode(response.body);

//           // Check if payment is required
//           if (responseData['requires_payment'] == true) {
//             // Handle payment flow here
//             await _handlePayment(responseData);
//           } else {
//             // Subscription successful
//             _showSuccessDialog(plan['name']);
//           }
//         } else {
//           final errorData = json.decode(response.body);
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(errorData['message'] ?? 'Failed to subscribe'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Error: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() {
//           isSubscribing = false;
//         });
//       }
//     }
//   }

//   Future<void> _handlePayment(Map<String, dynamic> paymentData) async {
//     // This is where you would integrate with your payment provider
//     // For example, Stripe, Razorpay, or any other payment gateway

//     // For now, we'll simulate a payment flow
//     final shouldProceed = await _showPaymentDialog(paymentData);

//     if (shouldProceed) {
//       // Simulate payment processing
//       await Future.delayed(const Duration(seconds: 2));

//       // Confirm payment with backend
//       await _confirmPayment(paymentData['subscription_id']);
//     }
//   }

//   Future<bool> _showPaymentDialog(Map<String, dynamic> paymentData) async {
//     return await showDialog<bool>(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Payment Required'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text('Amount: ₹${paymentData['amount']}'),
//               const SizedBox(height: 16),
//               const Text('Please complete the payment to activate your subscription.'),
//             ],
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(false),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               onPressed: () => Navigator.of(context).pop(true),
//               child: const Text('Pay Now'),
//             ),
//           ],
//         );
//       },
//     ) ?? false;
//   }

//   Future<void> _confirmPayment(String subscriptionId) async {
//     try {
//       final response = await http.post(
//         Uri.parse('${ApiConfig.baseUrl}/api/subscriptions/confirm-payment/'),
//         headers: _getAuthHeaders(),
//         body: json.encode({
//           'subscription_id': subscriptionId,
//           'payment_status': 'completed',
//           // Add other payment confirmation data as needed
//         }),
//       );

//       if (mounted) {
//         if (response.statusCode == 200) {
//           _showSuccessDialog('Premium Plan');
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Payment confirmation failed'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('Payment confirmation error: ${e.toString()}'),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     }
//   }

//   void _showSuccessDialog(String planName) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: const Text('Subscription Successful!'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(
//                 Icons.check_circle,
//                 color: Colors.green,
//                 size: 64,
//               ),
//               const SizedBox(height: 16),
//               Text('You have successfully subscribed to $planName'),
//               const SizedBox(height: 8),
//               const Text('You can now create unlimited job posts!'),
//             ],
//           ),
//           actions: [
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close dialog
//                 Navigator.of(context).pop(true); // Return to previous screen with success
//               },
//               child: const Text('Continue'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Subscription Plans"),
//         centerTitle: true,
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : plans.isEmpty
//               ? const Center(
//                   child: Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Icon(Icons.error_outline, size: 64, color: Colors.grey),
//                       SizedBox(height: 16),
//                       Text(
//                         'No subscription plans available',
//                         style: TextStyle(fontSize: 18, color: Colors.grey),
//                       ),
//                     ],
//                   ),
//                 )
//               : Column(
//                   children: [
//                     // Header section
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.all(20),
//                       decoration: BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [Colors.blue.shade400, Colors.blue.shade600],
//                           begin: Alignment.topLeft,
//                           end: Alignment.bottomRight,
//                         ),
//                       ),
//                       child: const Column(
//                         children: [
//                           Text(
//                             'Choose Your Plan',
//                             style: TextStyle(
//                               fontSize: 24,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                           SizedBox(height: 8),
//                           Text(
//                             'Select a plan to unlock unlimited job postings',
//                             style: TextStyle(
//                               fontSize: 16,
//                               color: Colors.white70,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     // Plans list
//                     Expanded(
//                       child: ListView.builder(
//                         padding: const EdgeInsets.all(16),
//                         itemCount: plans.length,
//                         itemBuilder: (context, index) {
//                           final plan = plans[index];
//                           final features = plan['features'] as Map<String, dynamic>;
//                           final isPopular = plan['is_popular'] ?? false;

//                           return Container(
//                             margin: const EdgeInsets.only(bottom: 16),
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(12),
//                               border: isPopular
//                                   ? Border.all(color: Colors.orange, width: 2)
//                                   : null,
//                             ),
//                             child: Card(
//                               elevation: isPopular ? 8 : 3,
//                               margin: EdgeInsets.zero,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               child: Column(
//                                 children: [
//                                   if (isPopular)
//                                     Container(
//                                       width: double.infinity,
//                                       padding: const EdgeInsets.symmetric(vertical: 8),
//                                       decoration: const BoxDecoration(
//                                         color: Colors.orange,
//                                         borderRadius: BorderRadius.only(
//                                           topLeft: Radius.circular(12),
//                                           topRight: Radius.circular(12),
//                                         ),
//                                       ),
//                                       child: const Text(
//                                         'MOST POPULAR',
//                                         textAlign: TextAlign.center,
//                                         style: TextStyle(
//                                           color: Colors.white,
//                                           fontWeight: FontWeight.bold,
//                                         ),
//                                       ),
//                                     ),
//                                   Padding(
//                                     padding: const EdgeInsets.all(16),
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Row(
//                                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                                           children: [
//                                             Text(
//                                               plan['name'],
//                                               style: const TextStyle(
//                                                 fontSize: 20,
//                                                 fontWeight: FontWeight.bold,
//                                               ),
//                                             ),
//                                             Container(
//                                               padding: const EdgeInsets.symmetric(
//                                                 horizontal: 12,
//                                                 vertical: 4,
//                                               ),
//                                               decoration: BoxDecoration(
//                                                 color: Colors.green.shade100,
//                                                 borderRadius: BorderRadius.circular(20),
//                                               ),
//                                               child: Text(
//                                                 '₹${plan['price']}',
//                                                 style: TextStyle(
//                                                   fontWeight: FontWeight.bold,
//                                                   color: Colors.green.shade700,
//                                                   fontSize: 16,
//                                                 ),
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                         const SizedBox(height: 8),
//                                         Text(
//                                           plan['description'],
//                                           style: TextStyle(
//                                             color: Colors.grey.shade600,
//                                             fontSize: 14,
//                                           ),
//                                         ),
//                                         const Divider(height: 24),
//                                         const Text(
//                                           "Features:",
//                                           style: TextStyle(
//                                             fontWeight: FontWeight.w600,
//                                             fontSize: 16,
//                                           ),
//                                         ),
//                                         const SizedBox(height: 12),
//                                         ...features.entries.map((entry) {
//                                           return Padding(
//                                             padding: const EdgeInsets.only(bottom: 8),
//                                             child: Row(
//                                               children: [
//                                                 Icon(
//                                                   entry.value == true
//                                                       ? Icons.check_circle
//                                                       : Icons.cancel,
//                                                   color: entry.value == true
//                                                       ? Colors.green
//                                                       : Colors.red,
//                                                   size: 20,
//                                                 ),
//                                                 const SizedBox(width: 8),
//                                                 Expanded(
//                                                   child: Text(
//                                                     entry.key.replaceAll('_', ' ').toUpperCase(),
//                                                     style: TextStyle(
//                                                       color: entry.value == true
//                                                           ? Colors.black87
//                                                           : Colors.grey,
//                                                     ),
//                                                   ),
//                                                 ),
//                                               ],
//                                             ),
//                                           );
//                                         }).toList(),
//                                         const SizedBox(height: 16),
//                                         SizedBox(
//                                           width: double.infinity,
//                                           height: 48,
//                                           child: ElevatedButton(
//                                             onPressed: isSubscribing
//                                                 ? null
//                                                 : () => _subscribeToPlan(plan),
//                                             style: ElevatedButton.styleFrom(
//                                               backgroundColor: isPopular
//                                                   ? Colors.orange
//                                                   : Colors.blue,
//                                               shape: RoundedRectangleBorder(
//                                                 borderRadius: BorderRadius.circular(24),
//                                               ),
//                                             ),
//                                             child: isSubscribing
//                                                 ? const SizedBox(
//                                                     height: 20,
//                                                     width: 20,
//                                                     child: CircularProgressIndicator(
//                                                       strokeWidth: 2,
//                                                       valueColor: AlwaysStoppedAnimation<Color>(
//                                                         Colors.white,
//                                                       ),
//                                                     ),
//                                                   )
//                                                 : Text(
//                                                     'Subscribe to ${plan['name']}',
//                                                     style: const TextStyle(
//                                                       fontSize: 16,
//                                                       fontWeight: FontWeight.bold,
//                                                       color: Colors.white,
//                                                     ),
//                                                   ),
//                                           ),
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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

  // Stripe checkout function
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

          // Navigate to in-app payment page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => StripePaymentPage(
                    checkoutUrl: checkoutUrl,
                    onPaymentComplete: () {
                      Navigator.pop(context); // Close payment page
                      showSnack('Payment completed successfully!');
                      // Optionally refresh plans or check subscription status
                    },
                    onPaymentCancelled: () {
                      Navigator.pop(context); // Close payment page
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Subscription Plans")),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                itemCount: plans.length,
                itemBuilder: (_, i) {
                  final plan = plans[i];
                  return Card(
                    margin: const EdgeInsets.all(12),
                    child: ListTile(
                      title: Text(plan['name']),
                      subtitle: Text(
                        "₹${plan['price']} • ${plan['description']}",
                      ),
                      trailing: ElevatedButton(
                        onPressed:
                            subscribing
                                ? null
                                : () => createStripeCheckoutSimple(plan),
                        child:
                            subscribing
                                ? const SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text("Subscribe"),
                      ),
                    ),
                  );
                },
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

                // Check if payment is complete
                if (url.contains('success') || url.contains('payment_intent')) {
                  widget.onPaymentComplete();
                } else if (url.contains('cancel')) {
                  widget.onPaymentCancelled();
                }
              },
              onNavigationRequest: (NavigationRequest request) {
                print('Navigation request: ${request.url}');

                // Handle payment completion
                if (request.url.contains('success') ||
                    request.url.contains('payment_intent') ||
                    request.url.contains('stripe.com/payments/')) {
                  widget.onPaymentComplete();
                  return NavigationDecision.prevent;
                }

                // Handle payment cancellation
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
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onPaymentCancelled,
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: controller),
          if (isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
