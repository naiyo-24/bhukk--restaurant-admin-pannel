// controller/auth/auth_controller.dart
import 'package:get/get.dart';
import '../../routes/app_routes.dart';

class AuthController extends GetxController {
	// Login fields
	var phoneNumber = ''.obs;
	var otp = ''.obs;
	var isLoading = false.obs;
	var showOtpField = false.obs;

	// Signup fields
	var restaurantName = ''.obs;
	var email = ''.obs;
	var password = ''.obs;
	var confirmPassword = ''.obs;
	var showPassword = false.obs;
	var showConfirmPassword = false.obs;
	var hasDining = false.obs;
	var hasLiquor = false.obs;
	var location = ''.obs; // stub for location picker
	var gstin = ''.obs; // stub for file upload
	var vat = ''.obs;
	var fssai = ''.obs;
	var otherDocs = ''.obs;

		// Document applications tracking (for users without documents yet)
		final RxList<DocumentApplication> applications = <DocumentApplication>[].obs;

	// Login logic
	void setPhoneNumber(String value) {
		phoneNumber.value = value;
		// OTP field visibility controlled by generateOtp() now
		if (value.length != 10) showOtpField.value = false;
	}

	void setOtp(String value) {
		otp.value = value;
	}

	void loginWithPhone() async {
		isLoading.value = true;
		await Future.delayed(const Duration(seconds: 1));
		// Simulate OTP sent
		isLoading.value = false;
		// On success, navigate or show message
		if (otp.value.length == 6) {
			Get.offAllNamed(AppRoutes.dashboard);
		}
	}

		// Generate OTP (simulated)
		Future<void> generateOtp() async {
			if (phoneNumber.value.length != 10) return;
			isLoading.value = true;
			await Future.delayed(const Duration(milliseconds: 800));
			isLoading.value = false;
			showOtpField.value = true;
		}

	// Signup logic
	void setRestaurantName(String value) => restaurantName.value = value;
	void setEmail(String value) => email.value = value.trim();
	void setPassword(String value) => password.value = value;
	void setConfirmPassword(String value) => confirmPassword.value = value;
	void toggleShowPassword() => showPassword.value = !showPassword.value;
	void toggleShowConfirmPassword() => showConfirmPassword.value = !showConfirmPassword.value;
	void toggleDining(bool value) => hasDining.value = value;
	void toggleLiquor(bool value) => hasLiquor.value = value;
	void setLocation(String value) => location.value = value;
	void setGstin(String value) => gstin.value = value;
	void setVat(String value) => vat.value = value;
	void setFssai(String value) => fssai.value = value;
	void setOtherDocs(String value) => otherDocs.value = value;

	bool get isSignupValid {
		final emailOk = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.value);
		final passOk = password.value.length >= 6 && password.value == confirmPassword.value;
		return phoneNumber.value.length == 10 && otp.value.length == 6 && restaurantName.value.isNotEmpty && emailOk && passOk;
	}

	void signup() async {
		isLoading.value = true;
		await Future.delayed(const Duration(seconds: 2));
		isLoading.value = false;
		// On success, navigate to dashboard
		Get.offAllNamed(AppRoutes.dashboard);
	}

		// Logout
		void logout() {
			// Clear volatile auth state (expand with tokens/session as needed)
			phoneNumber.value = '';
			otp.value = '';
			showOtpField.value = false;
			// Navigate to login
			Get.offAllNamed(AppRoutes.login);
		}

			// Apply for documents (stub for API integration)
			Future<void> applyForDocument(String type, {String? notes}) async {
				// Simulate API call
				isLoading.value = true;
				await Future.delayed(const Duration(milliseconds: 600));
				final ref = 'APP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
				applications.add(DocumentApplication(type: type, status: 'Submitted', reference: ref, notes: notes));
				isLoading.value = false;
			}
}

		class DocumentApplication {
			final String type; // e.g., GSTIN, VAT, FSSAI, Other
			String status; // Submitted, In Review, Approved, Rejected
			final String reference; // reference id
			final String? notes;
			DocumentApplication({required this.type, required this.status, required this.reference, this.notes});
		}
