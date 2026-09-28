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
  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.uid).get();
      
      // Initialize real-time listening on the AppState level
      if (mounted) {
        context.read<AppState>().listenToUserDoc(widget.uid);
      }

      if (!doc.exists) {
        // Fallback if the user profile is incomplete
        if (mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
        }
        return;
      }
      
      final data = doc.data() as Map<String, dynamic>? ?? {};
      if (mounted) {
        context.read<AppState>().syncUserFromFirestore(widget.uid, data);
        final isLinked = data['coupleId'] != null;
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => isLinked ? const HomeScreen() : const OnboardingScreen()));
      }
    } catch (e) {
      print('Loading Error: $e');
      if (mounted) {
        // Fallback routing in the catch block
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: RomanticLoadingOverlay(customMessage: "Loading your love story..."));
  }
}`;

code = code.replace(oldRoot, newRoot);
fs.writeFileSync(path, code, 'utf8');
console.log('Fixed RootScreen with pushReplacement');
