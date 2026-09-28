const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/onboarding_screen.dart';
let code = fs.readFileSync(path, 'utf8');

const oldTap = `onTap: () {
                            setState(() => _showCodeGeneration = true);
                            context.read<AppState>().generateCode();
                          },`;

const newTap = `onTap: () async {
                            setState(() {
                              _showCodeGeneration = true;
                              // We could add _isGeneratingCode here, but user asked to reset _showCodeGeneration on error
                            });
                            try {
                              await context.read<AppState>().generateCode();
                            } catch (e) {
                              if (mounted) {
                                setState(() {
                                  _showCodeGeneration = false;
                                });
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ));
                              }
                            }
                          },`;

if (code.includes(oldTap)) {
  code = code.replace(oldTap, newTap);
  fs.writeFileSync(path, code, 'utf8');
  console.log('Fixed OnboardingScreen code generation error handling');
} else {
  console.log('Could not find oldTap in OnboardingScreen');
}
