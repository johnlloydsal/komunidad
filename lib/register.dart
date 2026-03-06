import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'auth_wrapper.dart';
import 'login.dart';
import 'services/user_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_logo.dart';
import 'widgets/barangay_background.dart';
import 'utils/password_validator.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final UserService _userService = UserService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController barangayAddressController = TextEditingController();
  String? selectedZone;
  final List<String> zoneOptions = [
    'Zone 1', 'Zone 2', 'Zone 3', 'Zone 4',
    'Zone 5', 'Zone 6', 'Zone 7', 'Zone 8',
  ];
  String? selectedIdType;
  final List<String> idTypeOptions = [
    'Barangay ID',
    'Philippine Passport',
    'Driver\'s License',
    'SSS ID',
    'GSIS ID',
    'UMID (Unified Multi-Purpose ID)',
    'PhilHealth ID',
    'TIN (Tax Identification Number) ID',
    'Postal ID',
    'Voter\'s ID',
    'PRC ID (Professional Regulation Commission)',
    'Senior Citizen ID',
    'PWD ID (Person with Disability)',
    'NBI Clearance',
    'Police Clearance',
    'OWWA ID (Overseas Workers Welfare Administration)',
    'OFW ID',
    'Seaman\'s Book',
    'AFP ID (Armed Forces of the Philippines)',
    'PNP ID (Philippine National Police)',
    'BIR ID',
    'Company/School ID',
    'Others',
  ];
  final TextEditingController submitIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  XFile? idImage;
  bool acceptedTerms = false;
  bool isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  int _passwordStrength = 0;

  Future<void> _pickIdImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          idImage = image;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error picking image: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: const Color(0xFF2D3748),
        resizeToAvoidBottomInset: true,
        body: AnimatedBarangayBackground(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryDark,
                  AppTheme.primaryColor.withOpacity(0.9),
                  const Color(0xFF2D3748),
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
              ),
              child: IntrinsicHeight(
                child: Column(
                  children: [
                    // Back button
                    Align(
                      alignment: Alignment.topLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16, top: 16),
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          tooltip: 'Back',
                        ),
                      ),
                    ),
                const SizedBox(height: 20),
                // Logo at top
                const AppLogo(size: 80, color: Colors.white),
                const SizedBox(height: 40),
                // Main content area - white rounded container
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        // Register heading
                        const Text(
                          "Register",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Create your account",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Username Field
                        TextField(
                          controller: usernameController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.none,
                          decoration: InputDecoration(
                            hintText: "Username",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Icon(
                              Icons.person_outlined,
                              color: Colors.grey[400],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Email Field
                        TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.none,
                          autocorrect: false,
                          decoration: InputDecoration(
                            hintText: "Email Address",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: Colors.grey[400],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // First Name Field
                        TextField(
                          controller: firstNameController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: "First Name",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Icon(
                              Icons.person_outlined,
                              color: Colors.grey[400],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Last Name Field
                        TextField(
                          controller: lastNameController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: "Last Name",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Icon(
                              Icons.person_outlined,
                              color: Colors.grey[400],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Phone Number Field
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: "Phone Number",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Icon(
                              Icons.phone_outlined,
                              color: Colors.grey[400],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Barangay Address Field
                        TextField(
                          controller: barangayAddressController,
                          textInputAction: TextInputAction.next,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: "Barangay Address",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Icon(
                              Icons.home_outlined,
                              color: Colors.grey[400],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Zone / Purok Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedZone,
                          decoration: InputDecoration(
                            hintText: "Select Zone / Purok",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Icon(
                              Icons.location_city_outlined,
                              color: Colors.grey[400],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          isExpanded: true,
                          items: zoneOptions
                              .map((zone) => DropdownMenuItem(
                                    value: zone,
                                    child: Text(zone),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedZone = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // ID Type Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedIdType,
                          decoration: InputDecoration(
                            hintText: "Select ID Type",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Icon(
                              Icons.badge_outlined,
                              color: Colors.grey[400],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          isExpanded: true,
                          items: idTypeOptions
                              .map((idType) => DropdownMenuItem(
                                    value: idType,
                                    child: Text(
                                      idType,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedIdType = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // ID Number Field
                        TextField(
                          controller: submitIdController,
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            hintText: "ID Number",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Icon(
                              Icons.numbers,
                              color: Colors.grey[400],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // ID Picture Upload
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: idImage != null ? Colors.green : Colors.grey[300]!,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.camera_alt_outlined,
                                    color: Colors.grey[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      idImage != null
                                          ? "ID Image Selected ✓"
                                          : "Upload Barangay ID Picture *",
                                      style: TextStyle(
                                        color: idImage != null
                                            ? Colors.green[700]
                                            : Colors.grey[700],
                                        fontSize: 14,
                                        fontWeight: idImage != null
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: _pickIdImage,
                                    icon: Icon(
                                      idImage != null
                                          ? Icons.edit
                                          : Icons.add_photo_alternate,
                                      size: 18,
                                    ),
                                    label: Text(
                                      idImage != null ? 'Change' : 'Choose',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1E3A8A),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (idImage != null) ...[
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    File(idImage!.path),
                                    height: 150,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                "Please upload a clear photo of your Barangay ID to verify your residency.",
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password Field with Strength Indicator
                        TextField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.next,
                          autocorrect: false,
                          enableSuggestions: false,
                          onChanged: (value) {
                            setState(() {
                              _passwordStrength = PasswordValidator.getStrength(value);
                            });
                          },
                          decoration: InputDecoration(
                            hintText: "Password",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              color: Colors.grey[400],
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey[400],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        if (passwordController.text.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: (_passwordStrength + 1) / 5,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(PasswordValidator.getStrengthColor(_passwordStrength)),
                                  ),
                                  minHeight: 4,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                PasswordValidator.getStrengthLabel(_passwordStrength),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(PasswordValidator.getStrengthColor(_passwordStrength)),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ...PasswordValidator.getRequirements(passwordController.text).map(
                            (req) => Padding(
                              padding: const EdgeInsets.only(left: 8, top: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    req.isMet ? Icons.check_circle : Icons.cancel,
                                    size: 14,
                                    color: req.isMet ? Colors.green : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    req.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: req.isMet ? Colors.green : Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),

                        // Confirm Password Field
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          enableSuggestions: false,
                          decoration: InputDecoration(
                            hintText: "Confirm Password",
                            hintStyle: TextStyle(color: Colors.grey[400]),
                            filled: true,
                            fillColor: Colors.grey[100],
                            prefixIcon: Icon(
                              Icons.lock_outlined,
                              color: Colors.grey[400],
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey[400],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Terms Checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: acceptedTerms,
                              onChanged: (value) {
                                setState(() {
                                  acceptedTerms = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFF1E3A8A),
                            ),
                            const Expanded(
                              child: Text(
                                "I accept the Terms and Policy",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E3A8A),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            onPressed: isLoading || !acceptedTerms
                                ? null
                                : () async {
                                    // For web - also use window.console.log
                                    print('🔴 REGISTER BUTTON PRESSED!');
                                    String username = usernameController.text.trim();
                                    String email = emailController.text.trim();
                                    String firstName = firstNameController.text.trim();
                                    String lastName = lastNameController.text.trim();
                                    String phone = phoneController.text.trim();
                                    String barangayAddress = barangayAddressController.text.trim();
                                    String submitId = submitIdController.text.trim();
                                    String password = passwordController.text.trim();
                                    String confirmPassword = confirmPasswordController.text.trim();

                                    print('🔴 Username: $username');
                                    print('🔴 Email: $email');
                                    print('🔴 Name: $firstName $lastName');
                                    print('🔴 Phone: $phone');
                                    print('🔴 Address: $barangayAddress, $selectedZone');
                                    print('🔴 ID Type: $selectedIdType');
                                    print('🔴 Submit ID: $submitId');
                                    print('🔴 Has ID Image: ${idImage != null}');
                                    print('🔴 Password length: ${password.length}');
                                    print('🔴 Terms accepted: $acceptedTerms');

                                    // Validation
                                    if (username.isEmpty ||
                                        email.isEmpty ||
                                        firstName.isEmpty ||
                                        lastName.isEmpty ||
                                        phone.isEmpty ||
                                        barangayAddress.isEmpty ||
                                        selectedZone == null ||
                                        selectedIdType == null ||
                                        submitId.isEmpty ||
                                        password.isEmpty ||
                                        confirmPassword.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Please fill all fields!"),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }

                                    // Validate email format
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Please enter a valid email address"),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }

                                    if (idImage == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text("Please upload your ID picture"),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    if (password != confirmPassword) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Passwords do not match!",
                                          ),
                                          backgroundColor: Colors.red,
                                          duration: Duration(seconds: 2),
                                        ),
                                      );
                                      return;
                                    }

                                    // Validate strong password
                                    String? passwordValidationError = PasswordValidator.validate(password);
                                    if (passwordValidationError != null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(passwordValidationError),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    setState(() {
                                      isLoading = true;
                                    });

                                    try {
                                      print('🔵 Starting registration for: $email');
                                      
                                      // Create account with Firebase
                                      final userCredential = await FirebaseAuth
                                          .instance
                                          .createUserWithEmailAndPassword(
                                            email: email,
                                            password: password,
                                          );

                                      if (userCredential.user != null) {
                                        // Update display name
                                        String displayName = '$firstName $lastName';
                                        print('🔵 Updating display name: $displayName');
                                        await userCredential.user!.updateDisplayName(displayName);
                                        await userCredential.user!.reload();

                                        // Upload ID image to Firebase Storage
                                        print('🔵 Uploading ID image...');
                                        String? idImageUrl;
                                        if (idImage != null) {
                                          try {
                                            final storageRef = FirebaseStorage.instance
                                                .ref()
                                                .child('user_ids')
                                                .child('${userCredential.user!.uid}_id.jpg');
                                            
                                            await storageRef.putFile(File(idImage!.path));
                                            idImageUrl = await storageRef.getDownloadURL();
                                            print('✅ ID image uploaded: $idImageUrl');
                                          } catch (e) {
                                            print('❌ Error uploading ID image: $e');
                                            // Continue even if image upload fails
                                          }
                                        }

                                        // Save ALL user data to Firestore
                                        print('🔵 Saving to Firestore...');
                                        await _userService.createUserProfile(
                                          uid: userCredential.user!.uid,
                                          email: email,
                                          displayName: displayName,
                                          username: username,
                                          firstName: firstName,
                                          lastName: lastName,
                                          phoneNumber: phone,
                                          barangayAddress: barangayAddress,
                                          zone: selectedZone,
                                          idType: selectedIdType,
                                          submitId: submitId,
                                          idImageUrl: idImageUrl,
                                          accountStatus: 'pending',
                                        );
                                        print('✅ Firestore save complete!');

                                        // Send email verification
                                        try {
                                          await userCredential.user!.sendEmailVerification();
                                          print('✅ Verification email sent to: $email');
                                        } catch (e) {
                                          print('⚠️ Could not send verification email: $e');
                                          // Continue even if email send fails
                                        }

                                        if (!mounted) return;

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              "Registration Successful!\n✅ Please check $email for verification link.\n⏳ Awaiting admin approval.",
                                            ),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(seconds: 5),
                                          ),
                                        );

                                        // Navigate to AuthWrapper which will route to pending approval page
                                        await Future.delayed(
                                          const Duration(milliseconds: 500),
                                        );
                                        if (!mounted) return;

                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder: (context) => const AuthWrapper(),
                                          ),
                                          (route) => false,
                                        );
                                      }
                                    } on FirebaseAuthException catch (e) {
                                      print(
                                        '❌ Firebase Auth Error: ${e.code} - ${e.message}',
                                      );
                                      if (!mounted) return;

                                      String errorMessage =
                                          'Registration failed';
                                      if (e.code == 'weak-password') {
                                        errorMessage =
                                            'Password should be at least 6 characters';
                                      } else if (e.code ==
                                          'email-already-in-use') {
                                        errorMessage =
                                            'Email already in use. Please login instead.';
                                      } else if (e.code == 'invalid-email') {
                                        errorMessage = 'Invalid email address';
                                      } else {
                                        errorMessage =
                                            e.message ?? 'Registration failed';
                                      }

                                      print('❌ Showing error: $errorMessage');

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(errorMessage),
                                          backgroundColor: Colors.red,
                                          duration: const Duration(seconds: 3),
                                        ),
                                      );
                                    } catch (e) {
                                      print('❌ General Error: $e');
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Error: ${e.toString()}',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    } finally {
                                      if (mounted) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                      }
                                    }
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    "Register",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Login Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? ",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const LoginPage(),
                                  ),
                                );
                              },
                              child: const Text(
                                "Login",
                                style: TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    barangayAddressController.dispose();
    submitIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
