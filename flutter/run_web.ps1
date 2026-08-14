# Runs the Flutter web app on a FIXED port so password-reset emails sent by the
# backend always point at a running app. Keep this port in sync with
# RESET_LINK_URI in backend/.env (default http://localhost:57087).
flutter run -d chrome --web-port 57087
