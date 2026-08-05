import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/main_shell.dart';
import '../../core/widgets/placeholder_screen.dart';
import 'route_names.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/phone_verification_screen.dart';
import '../../features/auth/presentation/screens/pin_lock_screen.dart';
import '../../features/auth/presentation/screens/biometric_auth_screen.dart';
import '../../features/results/presentation/screens/test_result_list_screen.dart';
import '../../features/results/presentation/screens/test_result_detail_screen.dart';
import '../../features/symptom/presentation/screens/symptom_medication_screen.dart';
import '../../features/symptom/presentation/screens/symptom_record_form_screen.dart';
import '../../features/symptom/presentation/screens/symptom_record_list_screen.dart';
import '../../features/appointment/presentation/screens/appointment_list_screen.dart';
import '../../features/appointment/presentation/screens/appointment_detail_screen.dart';
import '../../features/chatbot/presentation/screens/chat_screen.dart';
import '../../features/intake/presentation/screens/intake_intro_screen.dart';
import '../../features/intake/presentation/screens/intake_form_screen.dart';
import '../../features/intake/presentation/screens/intake_question_list_screen.dart';
import '../../features/intake/presentation/screens/intake_completed_screen.dart';
import '../../features/convenience/presentation/screens/patient_qr_screen.dart';
import '../../features/convenience/presentation/screens/notification_list_screen.dart';
import '../../features/convenience/presentation/screens/settings_screen.dart';
import '../../features/convenience/presentation/screens/more_screen.dart';
import '../../features/convenience/presentation/screens/profile_screen.dart';
import '../../features/appointment/presentation/screens/appointment_create_screen.dart';
import '../../features/auth/presentation/screens/guardian_login_screen.dart';
import '../../features/auth/presentation/screens/guardian_home_screen.dart';
import '../../features/settings/presentation/screens/guardian_link_screen.dart';
import '../../features/auth/presentation/screens/guardian_results_screen.dart';
import '../../features/auth/presentation/screens/guardian_appointments_screen.dart';
import '../../features/auth/presentation/screens/guardian_symptoms_screen.dart';



final GoRouter appRouter = GoRouter(
  initialLocation: RouteNames.splash,
  routes: [
    GoRoute(
      path: RouteNames.splash,
      builder: (context, state) {
        return const SplashScreen();
      },
    ),

    GoRoute(
      path: RouteNames.login,
      builder: (context, state) {
        return const LoginScreen();
      },
    ),


    GoRoute(
      path: RouteNames.guardianLogin,
      builder: (context, state) {
        return const GuardianLoginScreen();
      },
    ),

    GoRoute(
      path: RouteNames.guardianHome,
      builder: (context, state) {
        return const GuardianHomeScreen();
      },
    ),

    GoRoute(
      path: RouteNames.guardianResults,
      builder: (context, state) {
        return const GuardianResultsScreen();
      },
    ),

    GoRoute(
      path: RouteNames.guardianAppointments,
      builder: (context, state) {
        return const GuardianAppointmentsScreen();
      },
    ),

    GoRoute(
      path: RouteNames.guardianSymptoms,
      builder: (context, state) {
        return const GuardianSymptomsScreen();
      },
    ),

    GoRoute(
      path: RouteNames.guardianLink,
      builder: (context, state) {
        return const GuardianLinkScreen();
      },
    ),

    GoRoute(
      path: RouteNames.phoneVerification,
      builder: (context, state) {
        return const PhoneVerificationScreen();
      },
    ),

    GoRoute(
      path: RouteNames.biometricAuth,
      builder: (context, state) {
        return const BiometricAuthScreen();
      },
    ),

    GoRoute(
      path: RouteNames.pinLock,
      builder: (context, state) {
        return const PinLockScreen();
      },
    ),



    ShellRoute(
      builder: (context, state, child) {
        return MainShell(
          child: child,
        );
      },
      routes: [
       GoRoute(
        path: RouteNames.symptoms,
        builder: (context, state) {
          return const SymptomMedicationScreen();
        },
      ),
        GoRoute(
          path: RouteNames.appointments,
          builder: (context, state) {
            return const AppointmentListScreen();
          },
        ),

        GoRoute(
          path: RouteNames.appointmentCreate,
          builder: (context, state) {
            return const AppointmentCreateScreen();
          },
        ),

        GoRoute(
          path: RouteNames.appointmentDetail,
          builder: (context, state) {
            final appointmentId =
                state.pathParameters['appointmentId'] ?? '';

            return AppointmentDetailScreen(
              appointmentId: appointmentId,
            );
          },
        ),
        GoRoute(
          path: RouteNames.home,
          builder: (context, state) {
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: RouteNames.results,
          builder: (context, state) {
            return const TestResultListScreen();
          },
        ),

        GoRoute(
          path: RouteNames.resultDetail,
          builder: (context, state) {
            final resultId = state.pathParameters['resultId'] ?? '';

            return TestResultDetailScreen(
              resultId: resultId,
            );
          },
        ),
        GoRoute(
          path: RouteNames.more,
          builder: (context, state) {
            return const MoreScreen();
          },
        ),
      ],
    ),

    GoRoute(
      path: RouteNames.symptomRecordForm,
      builder: (context, state) {
        return const SymptomRecordFormScreen();
      },
    ),

    GoRoute(
      path: RouteNames.symptomRecordList,
      builder: (context, state) {
        return const SymptomRecordListScreen();
      },
    ),

    GoRoute(
      path: RouteNames.medication,
      builder: (context, state) {
        return const PlaceholderScreen(
          title: '복약관리',
        );
      },
    ),

    GoRoute(
      path: RouteNames.chatbot,
      builder: (context, state) {
        return const ChatScreen();
      },
    ),

    GoRoute(
      path: RouteNames.notifications,
      builder: (context, state) {
        return const NotificationListScreen();
      },
    ),

    GoRoute(
      path: RouteNames.patientQr,
      builder: (context, state) {
        return const PatientQrScreen();
      },
    ),

    GoRoute(
      path: RouteNames.intakeForm,
      builder: (context, state) {
        return IntakeIntroScreen(
          onStart: () {
            context.push(RouteNames.intakeFormWrite);
          },
          onCompleted: () {
            context.push(RouteNames.intakeAnswers);
          },
        );
      },
    ),

    GoRoute(
      path: RouteNames.intakeFormWrite,
      builder: (context, state) {
        return IntakeFormScreen(
          onCompleted: () {
            context.go(RouteNames.intakeCompleted);
          },
        );
      },
    ),

    GoRoute(
      path: RouteNames.intakeCompleted,
      builder: (context, state) {
        return IntakeCompletedScreen(
          onViewAnswers: () {
            context.push(RouteNames.intakeAnswers);
          },
          onGoHome: () {
            context.go(RouteNames.home);
          },
        );
      },
    ),

    GoRoute(
      path: RouteNames.intakeAnswers,
      builder: (context, state) {
        return IntakeQuestionListScreen(
          onEdit: () {
            context.push(RouteNames.intakeFormWrite);
          },
        );
      },
    ),
    

    GoRoute(
      path: RouteNames.profile,
      builder: (context, state) {
        return const ProfileScreen();
      },
    ),

    GoRoute(
      path: RouteNames.settings,
      builder: (context, state) {
        return const SettingsScreen();
      },
    ),
  ],
);
