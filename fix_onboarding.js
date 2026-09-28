const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/onboarding_screen.dart';
let code = fs.readFileSync(path, 'utf8');

if (!code.includes('import \'home_screen.dart\';')) {
  code = code.replace(
    'import \'../providers/app_state.dart\';',
    `import '../providers/app_state.dart';
import 'home_screen.dart';`
  );
}

if (!code.includes('if (appState.isLinked)')) {
  code = code.replace(
    'final appState = context.watch<AppState>();',
    `final appState = context.watch<AppState>();

    // Automatic routing when partner links
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (appState.isLinked && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    });`
  );
  fs.writeFileSync(path, code, 'utf8');
  console.log('Fixed OnboardingScreen');
} else {
  console.log('Already fixed');
}
