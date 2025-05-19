// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:taskova/Model/colors.dart';
// import 'package:taskova/auth/login.dart';
// import 'language_provider.dart';

// class LanguageSelectionScreen extends StatefulWidget {
//   const LanguageSelectionScreen({Key? key}) : super(key: key);

//   @override
//   State<LanguageSelectionScreen> createState() =>
//       _LanguageSelectionScreenState();
// }

// class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
//   late String selectedLanguage;
//   bool isLoading = false;

//   @override
//   void initState() {
//     super.initState();
//     // Initialize once during widget creation
//     final appLanguage = Provider.of<AppLanguage>(context, listen: false);
//     selectedLanguage = appLanguage.currentLanguage;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final appLanguage = Provider.of<AppLanguage>(context);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const SizedBox(height: 60),
//               // App Logo
//               Container(
//                 height: 100,
//                 width: 100,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                 ),
//                 child: Image.asset(
//                   'assets/app_logo.png',
//                   fit: BoxFit.contain,
//                   errorBuilder: (context, error, stackTrace) => Icon(
//                       Icons.language,
//                       size: 60,
//                       color: AppColors.primaryBlue),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               // App name
//               Text(
//                 appLanguage.get('app_name'),
//                 style: const TextStyle(
//                   fontSize: 28,
//                   fontWeight: FontWeight.bold,
//                   color: AppColors.primaryBlue,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               // Select language text
//               Text(
//                 appLanguage.get('select_language'),
//                 style: const TextStyle(
//                   fontSize: 16,
//                   color: Colors.grey,
//                 ),
//               ),
//               const SizedBox(height: 40),
//               // Language options
//               Expanded(
//                 child: ListView.builder(
//                   // Add clipBehavior to prevent overflow
//                   clipBehavior: Clip.hardEdge,
//                   // Add scroll physics for smooth scrolling
//                   physics: const BouncingScrollPhysics(),
//                   // Add padding to the ListView to avoid edge clipping
//                   padding: const EdgeInsets.symmetric(vertical: 8.0),
//                   itemCount: appLanguage.supportedLanguages.length,
//                   itemBuilder: (context, index) {
//                     final language = appLanguage.supportedLanguages[index];
//                     final isSelected = language['code'] == selectedLanguage;

//                     return Padding(
//                       padding: const EdgeInsets.only(
//                           bottom: 12.0, left: 8.0, right: 8.0),
//                       child: ListTile(
//                         onTap: () {
//                           setState(() {
//                             selectedLanguage = language['code']!;
//                           });
//                         },
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           side: BorderSide(
//                             color: isSelected
//                                 ? AppColors.primaryBlue
//                                 : AppColors.lightBlue,
//                             width: isSelected ? 2 : 1,
//                           ),
//                         ),
//                         tileColor: isSelected
//                             ? AppColors.lightBlue.withOpacity(0.1)
//                             : Colors.white,
//                         leading: CircleAvatar(
//                           backgroundColor: AppColors.lightBlue.withOpacity(0.3),
//                           child: Text(
//                             language['code']!.toUpperCase(),
//                             style: const TextStyle(
//                               color: AppColors.primaryBlue,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           ),
//                         ),
//                         title: Text(language['name']!),
//                         subtitle: Text(language['nativeName']!),
//                         trailing: isSelected
//                             ? const Icon(Icons.check_circle,
//                                 color: AppColors.primaryBlue)
//                             : null,
//                         // Add content padding to ensure borders are fully visible
//                         contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 16.0, vertical: 8.0),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//               const SizedBox(height: 20),
//               // Continue button
//               SizedBox(
//                 width: double.infinity,
//                 height: 55,
//                 child: ElevatedButton(
//                   onPressed: isLoading
//                       ? null
//                       : () async {
//                           setState(() {
//                             isLoading = true;
//                           });

//                           // Change language and translate strings
//                           await appLanguage.changeLanguage(selectedLanguage);

//                           if (mounted) {
//                             setState(() {
//                               isLoading = false;
//                             });

//                             // Navigate to login page
//                             Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(
//                                   builder: (context) => const Login()),
//                             );
//                           }
//                         },
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: AppColors.primaryBlue,
//                     foregroundColor: Colors.white,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                   ),
//                   child: isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : Text(
//                           appLanguage.get('continue_text'),
//                           style: const TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:taskova_shopkeeper/Model/colors.dart';
import 'package:taskova_shopkeeper/auth/login.dart';


import 'language_provider.dart';
import 'package:google_fonts/google_fonts.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  late String selectedLanguage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final appLanguage = Provider.of<AppLanguage>(context, listen: false);
    selectedLanguage = appLanguage.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final appLanguage = Provider.of<AppLanguage>(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE8F0FE),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              children: [
                // Header with Logo and Title
                Column(
                  children: [
                    Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/app_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.language,
                            size: 40,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      appLanguage.get('app_name'),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    Text(
                      appLanguage.get('select_language'),
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Language Selection Card
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      clipBehavior: Clip.hardEdge,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12.0, horizontal: 16.0),
                      itemCount: appLanguage.supportedLanguages.length,
                      itemBuilder: (context, index) {
                        final language = appLanguage.supportedLanguages[index];
                        final isSelected = language['code'] == selectedLanguage;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6.0),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primaryBlue.withOpacity(0.05)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.primaryBlue
                                    : Colors.grey[300]!,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: ListTile(
                              onTap: () {
                                setState(() {
                                  selectedLanguage = language['code']!;
                                });
                              },
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 8.0),
                              leading: CircleAvatar(
                                radius: 18,
                                backgroundColor:
                                    AppColors.primaryBlue.withOpacity(0.1),
                                child: Text(
                                  language['code']!.toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    color: AppColors.primaryBlue,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              title: Text(
                                language['name']!,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              subtitle: Text(
                                language['nativeName']!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check_circle,
                                      color: AppColors.primaryBlue,
                                      size: 20,
                                    )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            setState(() {
                              isLoading = true;
                            });
                            await appLanguage.changeLanguage(selectedLanguage);
                            if (mounted) {
                              setState(() {
                                isLoading = false;
                              });
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Login()),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      shadowColor: AppColors.primaryBlue.withOpacity(0.3),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            appLanguage.get('continue_text'),
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
