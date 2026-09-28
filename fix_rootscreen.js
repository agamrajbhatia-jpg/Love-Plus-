const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/main.dart';
let code = fs.readFileSync(path, 'utf8');

const oldRoot = `class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: RomanticLoadingOverlay(customMessage: "Warming up..."));
        }
        
        if (!authSnapshot.hasData) {
          return const AuthScreen();
        }
        
        final uid = authSnapshot.data!.uid;
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: RomanticLoadingOverlay(customMessage: "Loading your love story..."));
            }
            
            if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
              return const Scaffold(body: RomanticLoadingOverlay());
            }

            final data = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
            
            WidgetsBinding.instance.addPostFrameCallback((_) {
              context.read<AppState>().syncUserFromFirestore(uid, data);
            });

            final isLinked = data['coupleId'] != null;
            return isLinked ? const HomeScreen() : const OnboardingScreen();
          },
        );
      }
    );
  }
}`;

const newRoot = `class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: RomanticLoadingOverlay(customMessage: "Warming up..."));
        }
        
        if (!authSnapshot.hasData) {
          return const AuthScreen();
        }
        
        return _DataInitHandler(uid: authSnapshot.data!.uid);
      }
    );
  }
}

class _DataInitHandler extends StatefulWidget {
  final String uid;
  const _DataInitHandler({required this.uid});

  @override
  State<_DataInitHandler> createState() => _DataInitHandlerState();
}

class _DataInitHandlerState extends State<_DataInitHandler> {
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      if (!doc.exists) {
        // Fallback if the user profile is incomplete
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Loading Error: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isError = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: RomanticLoadingOverlay(customMessage: "Loading your love story..."));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(widget.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting && !userSnapshot.hasData) {
          return const Scaffold(body: RomanticLoadingOverlay(customMessage: "Loading your love story..."));
        }
        
        if (userSnapshot.hasError || _isError) {
          // Fallback routing
          return const OnboardingScreen();
        }
        
        if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
          // Fallback routing if user profile is incomplete
          return const OnboardingScreen();
        }

        final data = userSnapshot.data!.data() as Map<String, dynamic>? ?? {};
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<AppState>().syncUserFromFirestore(widget.uid, data);
        });

        // Our equivalent routing method
        final isLinked = data['coupleId'] != null;
        return isLinked ? const HomeScreen() : const OnboardingScreen();
      },
    );
  }
}`;

if (code.includes('class RootScreen extends StatelessWidget')) {
  const startIndex = code.indexOf('class RootScreen extends StatelessWidget');
  // I need to replace from startIndex down to the end of RootScreen
  // I will just use regex or literal replace. 
  // Let's use the literal replace, it should work if it matches perfectly.
}
code = code.replace(oldRoot, newRoot);
fs.writeFileSync(path, code, 'utf8');
console.log('Fixed RootScreen');
