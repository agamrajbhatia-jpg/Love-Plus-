// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:math';
import 'package:universal_html/html.dart' as html;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/glass_container.dart';
import '../../widgets/bouncing_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';

class DatesScreen extends StatefulWidget {
  const DatesScreen({super.key});

  @override
  State<DatesScreen> createState() => _DatesScreenState();
}

class _DatesScreenState extends State<DatesScreen> with TickerProviderStateMixin {
  // Calendar State
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  
  // Onboarding State
  bool _isFirstTime = true;
  int _onboardingStep = 1; // 1: Meetup Prompt, 2: Quote, 3: Birthday Prompt, 4: Relationship Start
  
  // Milestones State
  DateTime? _nextMeetupDate;
  DateTime? _userBirthday;
  final DateTime _partnerBirthday = DateTime.now().add(const Duration(days: 20)); // Mocked
  DateTime? _relationshipStartDate;
  List<DateTime> _anniversaries = [];

  // Audio State
  html.AudioElement? _currentAudio;
  String? _activeOverlayType; // 'meetup', 'birthday', 'anniversary'
  String _activeOverlayText = '';

  // Timer & Animations
  Timer? _countdownTimer;
  Duration _timeLeft = Duration.zero;
  
  late AnimationController _heartPulseController;
  late AnimationController _neonRingController; // Pulse for Meetup grid cell
  late AnimationController _bounceController;   // Bounce for Birthdays
  late AnimationController _rotateController;   // Rotate for Anniversaries

  @override
  void initState() {
    super.initState();
    _heartPulseController = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _neonRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _loadSavedDates();
  }

  Future<void> _loadSavedDates() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Try Firestore first for cross-device sync
    try {
      final appState = context.read<AppState>();
      if (appState.currentCoupleId != null) {
        final doc = await FirebaseFirestore.instance
            .collection('couples')
            .doc(appState.currentCoupleId)
            .collection('calendar_dates')
            .doc('milestones')
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          setState(() {
            if (data['meetup_date'] != null) _nextMeetupDate = DateTime.parse(data['meetup_date']);
            if (data['user_bday_${appState.currentUid}'] != null) _userBirthday = DateTime.parse(data['user_bday_${appState.currentUid}']);
            if (data['rel_start'] != null) {
              _relationshipStartDate = DateTime.parse(data['rel_start']);
              _calculateAnniversaries();
            }
            if (_nextMeetupDate != null && _relationshipStartDate != null) {
              _isFirstTime = false;
              _startCountdown();
            }
          });
          return; // Firestore succeeded, skip SharedPreferences
        }
      }
    } catch (_) {}
    
    // Fallback to SharedPreferences
    setState(() {
      final meetupStr = prefs.getString('meetup_date');
      if (meetupStr != null) _nextMeetupDate = DateTime.parse(meetupStr);
      
      final bdayStr = prefs.getString('user_bday');
      if (bdayStr != null) _userBirthday = DateTime.parse(bdayStr);
      
      final relStr = prefs.getString('rel_start');
      if (relStr != null) {
        _relationshipStartDate = DateTime.parse(relStr);
        _calculateAnniversaries();
      }
      
      if (meetupStr != null && relStr != null) {
        _isFirstTime = false;
        _startCountdown();
      }
    });
  }

  Future<void> _saveDates() async {
    final prefs = await SharedPreferences.getInstance();
    if (_nextMeetupDate != null) await prefs.setString('meetup_date', _nextMeetupDate!.toIso8601String());
    if (_userBirthday != null) await prefs.setString('user_bday', _userBirthday!.toIso8601String());
    if (_relationshipStartDate != null) await prefs.setString('rel_start', _relationshipStartDate!.toIso8601String());
    
    // Sync to Firestore for cross-device visibility
    try {
      final appState = context.read<AppState>();
      if (appState.currentCoupleId != null) {
        final Map<String, dynamic> syncData = {};
        if (_nextMeetupDate != null) syncData['meetup_date'] = _nextMeetupDate!.toIso8601String();
        if (_userBirthday != null) syncData['user_bday_${appState.currentUid}'] = _userBirthday!.toIso8601String();
        if (_relationshipStartDate != null) syncData['rel_start'] = _relationshipStartDate!.toIso8601String();
        
        await FirebaseFirestore.instance
            .collection('couples')
            .doc(appState.currentCoupleId)
            .collection('calendar_dates')
            .doc('milestones')
            .set(syncData, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  void _calculateAnniversaries() {
    if (_relationshipStartDate == null) return;
    _anniversaries.clear();
    
    final start = _relationshipStartDate!;
    
    // 1. Add the exact start date so the genesis is always marked!
    _anniversaries.add(start);
    
    // 2. Add 6-month and yearly intervals for the next 40 years
    for (int i = 1; i <= 80; i++) {
      _anniversaries.add(DateTime(start.year, start.month + (i * 6), start.day));
    }
  }

  void _startCountdown() {
    if (_nextMeetupDate == null) return;
    _updateTimeLeft();
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeLeft());
  }

  void _updateTimeLeft() {
    if (_nextMeetupDate == null) return;
    final now = DateTime.now();
    if (_nextMeetupDate!.isAfter(now)) {
      if (mounted) {
        setState(() {
          _timeLeft = _nextMeetupDate!.difference(now);
        });
      }
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _heartPulseController.dispose();
    _neonRingController.dispose();
    _bounceController.dispose();
    _rotateController.dispose();
    _stopAudio();
    super.dispose();
  }

  // --- AUDIO & OVERLAYS ---

  void _stopAudio() {
    if (_currentAudio != null) {
      _currentAudio!.pause();
      _currentAudio!.remove();
      _currentAudio = null;
    }
  }

  void _playAudio(String url) {
    _stopAudio();
    _currentAudio = html.AudioElement()
      ..src = url
      ..autoplay = true
      ..loop = true;
    html.document.body?.append(_currentAudio!);
  }

  Timer? _overlayTimer;

  void _triggerSensoryOverlay(String type, String text) {
    setState(() {
      _activeOverlayType = type;
      _activeOverlayText = text;
    });
    
    _overlayTimer?.cancel();
    _overlayTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) _dismissOverlay();
    });

    if (type == 'meetup') {
      // Cinematic romance hook
      _playAudio('https://actions.google.com/sounds/v1/water/rain_on_roof.ogg'); // placeholder
    } else if (type == 'birthday') {
      // Cute lofi chime
      _playAudio('https://actions.google.com/sounds/v1/alarms/spaceship_alarm.ogg'); // placeholder
    } else if (type == 'anniversary') {
      // Magical harp
      _playAudio('https://actions.google.com/sounds/v1/science_fiction/spaceship_door_opening.ogg'); // placeholder
    }
  }

  void _dismissOverlay() {
    setState(() {
      _activeOverlayType = null;
    });
    _stopAudio();
  }

  // --- MODAL ACTION HANDLERS ---
  
  Future<void> _selectMeetupDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _nextMeetupDate = picked;
        _onboardingStep = 3;
        _focusedDay = picked; // Focus calendar immediately on new date
      });
      _startCountdown();
      _saveDates();
    }
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _userBirthday = picked;
        _onboardingStep = 4;
        _focusedDay = picked; // Focus calendar immediately on new date
      });
      _saveDates();
    }
  }

  Future<void> _selectRelationshipStart() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 100)),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _relationshipStartDate = picked;
        _calculateAnniversaries();
        _isFirstTime = false; // Onboarding Complete
        _focusedDay = picked; // Focus calendar immediately on genesis date
      });
      _saveDates();
    }
  }

  // --- UI BUILDERS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Main Content
          SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, top: 40.0, bottom: 120.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_nextMeetupDate != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'OUR CALENDAR',
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_calendar, color: Colors.white70),
                        onPressed: () {
                          setState(() {
                            _isFirstTime = true;
                            _onboardingStep = 1;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildHeroCountdown(),
                  const SizedBox(height: 40),
                ] else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'OUR CALENDAR',
                        style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_calendar, color: Colors.white70),
                        onPressed: () {
                          setState(() {
                            _isFirstTime = true;
                            _onboardingStep = 1;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
                _buildCalendar(),
                const SizedBox(height: 16),
                _buildSensoryOverlay(),
                const SizedBox(height: 16),
                Text(
                  'Upcoming Moments',
                  style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                ),
                const SizedBox(height: 24),
                _buildDynamicEventsStream(),
              ],
            ),
          ),
          ),
          
          if (_isFirstTime) _buildOnboardingOverlay(),
        ],
      ),
      floatingActionButton: _isFirstTime ? null : _buildPremiumFAB(),
    );
  }

  Widget _buildHeroCountdown() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFF4D6D).withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: const Color(0xFFFF4D6D).withOpacity(0.2), blurRadius: 30, spreadRadius: -5)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned(
                right: -20,
                bottom: -20,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.9, end: 1.2).animate(CurvedAnimation(parent: _heartPulseController, curve: Curves.easeInOutSine)),
                  child: Icon(Icons.favorite, size: 150, color: const Color(0xFFFF4D6D).withOpacity(0.15)),
                ),
              ),
              Column(
                children: [
                  Text('OUR NEXT VISIT', style: GoogleFonts.spaceGrotesk(fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 4, color: Colors.white70)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildTimeBlock(_timeLeft.inDays.toString(), 'DAYS'),
                      Text(':', style: GoogleFonts.spaceGrotesk(fontSize: 32, color: Colors.white54, fontWeight: FontWeight.bold)),
                      _buildTimeBlock((_timeLeft.inHours % 24).toString().padLeft(2, '0'), 'HOURS'),
                      Text(':', style: GoogleFonts.spaceGrotesk(fontSize: 32, color: Colors.white54, fontWeight: FontWeight.bold)),
                      _buildTimeBlock((_timeLeft.inMinutes % 60).toString().padLeft(2, '0'), 'MINS'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeBlock(String value, String label) {
    return Flexible(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          children: [
            Text(value, style: GoogleFonts.spaceGrotesk(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white, height: 1.0)),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2, color: const Color(0xFFFF4D6D)))
          ],
        ),
      ),
    );
  }

  // --- CALENDAR RENDERING ---

  Widget _buildCalendar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF4D6D).withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        borderRadius: 30,
        child: Stack(
          children: [
            const Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(30)),
                child: DriftingParticles(),
              ),
            ),
            TableCalendar(
              firstDay: DateTime.utc(2020, 10, 16),
              lastDay: DateTime.utc(2030, 3, 14),
              focusedDay: _focusedDay,
              rowHeight: 60, // Better breathing room
              daysOfWeekHeight: 30,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: (selectedDay, focusedDay) {
                HapticFeedback.lightImpact();
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
                _checkAndTriggerSensoryEvent(selectedDay);
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                weekendStyle: GoogleFonts.poppins(color: const Color(0xFFFF4D6D), fontWeight: FontWeight.bold, fontSize: 13),
              ),
              calendarStyle: CalendarStyle(
                defaultTextStyle: GoogleFonts.poppins(color: Colors.white),
                weekendTextStyle: GoogleFonts.poppins(color: Colors.white),
                outsideTextStyle: GoogleFonts.poppins(color: Colors.white24),
                selectedDecoration: const BoxDecoration(color: Colors.transparent),
                todayDecoration: const BoxDecoration(color: Colors.transparent),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white70),
                rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white70),
                headerPadding: const EdgeInsets.only(bottom: 16),
              ),
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) => _buildCustomDayCell(day, false),
                todayBuilder: (context, day, focusedDay) => _buildCustomDayCell(day, false) ?? _buildStandardDay(day, isToday: true),
                selectedBuilder: (context, day, focusedDay) => _buildCustomDayCell(day, true) ?? _buildStandardDay(day, isSelected: true),
                outsideBuilder: (context, day, focusedDay) => _buildStandardDay(day, isOutside: true),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStandardDay(DateTime day, {bool isToday = false, bool isSelected = false, bool isOutside = false}) {
    Color textColor = isOutside ? Colors.white24 : Colors.white;
    
    return Container(
      margin: const EdgeInsets.all(6.0),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        border: isToday 
            ? Border.all(color: Colors.white38, width: 1.5)
            : Border.all(color: Colors.transparent, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '${day.day}', 
        maxLines: 1,
        softWrap: false,
        style: GoogleFonts.poppins(color: textColor, fontWeight: FontWeight.w600, fontSize: 15)
      ),
    );
  }

  void _checkAndTriggerSensoryEvent(DateTime day) {
    if (_nextMeetupDate != null && isSameDay(day, _nextMeetupDate)) {
      _triggerSensoryOverlay('meetup', 'Meeting on ${day.month}/${day.day}! ❤️');
      return;
    }
    
    bool isUserBday = _userBirthday != null && day.month == _userBirthday!.month && day.day == _userBirthday!.day;
    if (isUserBday) {
      _triggerSensoryOverlay('birthday', 'Happy Birthday You! 🎂');
      return;
    }
    
    bool isPartnerBday = day.month == _partnerBirthday.month && day.day == _partnerBirthday.day;
    if (isPartnerBday) {
      _triggerSensoryOverlay('birthday', 'Happy Birthday Partner! 🎂');
      return;
    }

    for (var ann in _anniversaries) {
      if (isSameDay(ann, day)) {
        _triggerSensoryOverlay('anniversary', 'Happy Anniversary! ✨');
        return;
      }
    }
  }

  Widget? _buildCustomDayCell(DateTime day, bool isSelected) {
    bool isMeetup = _nextMeetupDate != null && isSameDay(day, _nextMeetupDate);
    bool isUserBday = _userBirthday != null && day.month == _userBirthday!.month && day.day == _userBirthday!.day;
    bool isPartnerBday = day.month == _partnerBirthday.month && day.day == _partnerBirthday.day;
    bool isAnniversary = _anniversaries.any((ann) => isSameDay(ann, day));

    if (isAnniversary) {
      return AnimatedBuilder(
        animation: Listenable.merge([_rotateController, _heartPulseController]),
        builder: (context, child) {
          return ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.04).animate(
              CurvedAnimation(parent: _heartPulseController, curve: Curves.easeInOutSine)
            ),
            child: Container(
              margin: const EdgeInsets.all(4.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18), // Distinct shape
                gradient: SweepGradient(
                  colors: const [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFF8C00), Color(0xFFFFD700)],
                  transform: GradientRotation(_rotateController.value * 2 * 3.14159),
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFFD700).withOpacity(0.5), blurRadius: 12, spreadRadius: 2)
                ]
              ),
              child: Padding(
                padding: const EdgeInsets.all(2.0),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16), 
                    color: const Color(0xFF1A1A1A),
                    border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 1.5),
                  ),
                  child: Text(
                    '${day.day}', 
                    maxLines: 1,
                    softWrap: false,
                    style: GoogleFonts.poppins(color: const Color(0xFFFFD700), fontWeight: FontWeight.bold, fontSize: 16)
                  ),
                ),
              ),
            ),
          );
        }
      );
    }

    if (isMeetup || isUserBday || isPartnerBday) {
      return Container(
        margin: const EdgeInsets.all(6.0),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF872657).withOpacity(0.4), // Deep berry
              const Color(0xFFB76E79).withOpacity(0.4), // Frosted rose-gold
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFB76E79).withOpacity(isSelected ? 0.8 : 0.4), 
            width: 1.5
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB76E79).withOpacity(isSelected ? 0.3 : 0.15),
              blurRadius: isSelected ? 15 : 10,
              spreadRadius: 1,
            )
          ]
        ),
        child: Text(
          '${day.day}', 
          maxLines: 1,
          softWrap: false,
          style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
        ),
      );
    }

    return null; 
  }

  // --- SENSORY OVERLAY ---

  Widget _buildSensoryOverlay() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      child: _activeOverlayType == null 
        ? const SizedBox.shrink()
        : TweenAnimationBuilder(
            key: ValueKey(_activeOverlayText),
            duration: const Duration(milliseconds: 700),
            tween: Tween<double>(begin: 0, end: 1),
            curve: Curves.easeOutCubic,
            builder: (context, double val, child) {
              return Transform.translate(
                offset: Offset(0, 30 * (1 - val)),
                child: Transform.scale(
                  scale: 0.95 + (0.05 * val),
                  child: Opacity(
                    opacity: val.clamp(0.0, 1.0),
                    child: child,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                onTap: _dismissOverlay,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: _activeOverlayType == 'anniversary' 
                          ? [const Color(0xFFFFD700).withOpacity(0.2), const Color(0xFFFFA500).withOpacity(0.1)]
                          : [const Color(0xFFFF4D6D).withOpacity(0.3), const Color(0xFFB76E79).withOpacity(0.15)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: _activeOverlayType == 'anniversary' 
                          ? const Color(0xFFFFD700).withOpacity(0.6) 
                          : const Color(0xFFFF4D6D).withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _activeOverlayType == 'anniversary' 
                            ? const Color(0xFFFFD700).withOpacity(0.3) 
                            : const Color(0xFFFF4D6D).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: _activeOverlayType == 'anniversary' ? const Color(0xFFFFD700).withOpacity(0.2) : const Color(0xFFFF4D6D).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _activeOverlayType == 'anniversary' ? Icons.star_rounded : Icons.favorite_rounded,
                                color: _activeOverlayType == 'anniversary' ? const Color(0xFFFFD700) : const Color(0xFFFF4D6D),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Memory Preview', 
                                    style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500)
                                  ),
                                  Text(
                                    _activeOverlayText,
                                    style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
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

  // --- ONBOARDING MODALS ---

  Widget _buildOnboardingOverlay() {
    return Positioned.fill(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            color: Colors.black.withOpacity(0.4),
            padding: const EdgeInsets.all(32),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 600),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeIn,
                transitionBuilder: (child, animation) {
                  return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
                },
                child: _buildOnboardingStepContent(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOnboardingStepContent() {
    if (_onboardingStep == 1) {
      return GlassContainer(
        key: const ValueKey(1),
        padding: const EdgeInsets.all(32),
        borderRadius: 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✈️', style: TextStyle(fontSize: 48, fontFamilyFallback: ['Apple Color Emoji', 'Noto Color Emoji'])),
            const SizedBox(height: 16),
            Text('When are you\nmeeting next?', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
            const SizedBox(height: 32),
            BouncingButton(
              onTap: _selectMeetupDate,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFF4D6D), Color(0xFFFF7A00)]), borderRadius: BorderRadius.circular(20)),
                child: Center(child: Text('Choose a Date 📅', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
            ),
            const SizedBox(height: 16),
            BouncingButton(
              onTap: () => setState(() => _onboardingStep = 2),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Center(child: Text('Not sure as of now 🥺', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70))),
              ),
            ),
          ],
        ),
      );
    } else if (_onboardingStep == 2) {
      return GlassContainer(
        key: const ValueKey(2),
        padding: const EdgeInsets.all(32),
        borderRadius: 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite, color: Color(0xFFFF4D6D), size: 48),
            const SizedBox(height: 24),
            Text('"Distance means so little\nwhen someone means so much."', textAlign: TextAlign.center, style: GoogleFonts.playfairDisplay(fontSize: 22, fontStyle: FontStyle.italic, color: Colors.white, height: 1.4)),
            const SizedBox(height: 40),
            BouncingButton(
              onTap: () => setState(() => _onboardingStep = 3),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 32),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('Continue', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    } else if (_onboardingStep == 3) {
      return GlassContainer(
        key: const ValueKey(3),
        padding: const EdgeInsets.all(32),
        borderRadius: 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎂', style: TextStyle(fontSize: 48, fontFamilyFallback: ['Apple Color Emoji', 'Noto Color Emoji'])),
            const SizedBox(height: 16),
            Text('When is your\nbirthday?', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
            const SizedBox(height: 32),
            BouncingButton(
              onTap: _selectBirthday,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF8EC5FC), Color(0xFFE0C3FC)]), borderRadius: BorderRadius.circular(20)),
                child: Center(child: Text('Pick Date', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
            ),
          ],
        ),
      );
    } else {
      return GlassContainer(
        key: const ValueKey(4),
        padding: const EdgeInsets.all(32),
        borderRadius: 40,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💍', style: TextStyle(fontSize: 48, fontFamilyFallback: ['Apple Color Emoji', 'Noto Color Emoji'])),
            const SizedBox(height: 16),
            Text('When did your\nrelationship start?', textAlign: TextAlign.center, style: GoogleFonts.poppins(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2)),
            const SizedBox(height: 32),
            BouncingButton(
              onTap: _selectRelationshipStart,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFB8860B)]), borderRadius: BorderRadius.circular(20)),
                child: Center(child: Text('Pick Date', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
            ),
          ],
        ),
      );
    }
  }

  // --- MISC ---

  Widget _buildDynamicEventsStream() {
    final appState = context.read<AppState>();
    final coupleId = appState.currentCoupleId;
    if (coupleId == null) return const SizedBox.shrink();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('calendar_events').snapshots(),
      builder: (context, snapshot) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        List<Map<String, dynamic>> events = [];

        if (_nextMeetupDate != null && !_nextMeetupDate!.isBefore(today)) {
          events.add({'title': 'Next Meetup ❤️', 'date': _nextMeetupDate!, 'color': const Color(0xFFFF4D6D)});
        }
        if (_userBirthday != null) {
          DateTime nextUserBday = DateTime(today.year, _userBirthday!.month, _userBirthday!.day);
          if (nextUserBday.isBefore(today)) nextUserBday = DateTime(today.year + 1, _userBirthday!.month, _userBirthday!.day);
          events.add({'title': 'Your Birthday 🎂', 'date': nextUserBday, 'color': const Color(0xFFFF4D6D)});
        }
        DateTime nextPartnerBday = DateTime(today.year, _partnerBirthday.month, _partnerBirthday.day);
        if (nextPartnerBday.isBefore(today)) nextPartnerBday = DateTime(today.year + 1, _partnerBirthday.month, _partnerBirthday.day);
        events.add({'title': 'Partner\'s Birthday 🎂', 'date': nextPartnerBday, 'color': const Color(0xFFFF4D6D)});

        if (_relationshipStartDate != null) {
          for (var ann in _anniversaries) {
            if (!ann.isBefore(today)) {
              int intervalMonths = (ann.year - _relationshipStartDate!.year) * 12 + (ann.month - _relationshipStartDate!.month);
              double years = intervalMonths / 12.0;
              String labelText = (years % 1 == 0) ? '${years.toInt()} Year Anniversary 💍' : '${years.toStringAsFixed(1)} Year Anniversary 💍';
              events.add({'title': labelText, 'date': ann, 'color': const Color(0xFFFFD700)});
            }
          }
        }

        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['date'] != null) {
              final date = (data['date'] as Timestamp).toDate();
              if (!date.isBefore(today)) {
                events.add({'title': data['title'] ?? 'Event', 'date': date, 'color': const Color(0xFF4A90E2)});
              }
            }
          }
        }

        events.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
        final limitedEvents = events.take(5).toList();

        return Column(
          children: limitedEvents.map((e) {
            final date = e['date'] as DateTime;
            final diff = date.difference(today).inDays;
            String dateStr = diff == 0 ? 'Today!' : diff == 1 ? 'Tomorrow' : 'In $diff Days - ${date.month}/${date.day}';
            return Padding(
              padding: const EdgeInsets.only(bottom: 20.0),
              child: _buildEventCard(e['title'], dateStr, e['color'], () => _checkAndTriggerSensoryEvent(date)),
            );
          }).toList(),
        );
      },
    );
  }

  void _showAddEventDialog() {
    final TextEditingController titleController = TextEditingController();
    DateTime? selectedDate = _selectedDay ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E2A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text('Add Calendar Event', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Event Title',
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(
                      'Date: ${selectedDate!.month}/${selectedDate!.day}/${selectedDate!.year}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    trailing: const Icon(Icons.calendar_today, color: Color(0xFFFF4D6D)),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate!,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (picked != null) {
                        setStateDialog(() {
                          selectedDate = picked;
                        });
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4D6D)),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty) return;
                    final appState = context.read<AppState>();
                    if (appState.currentCoupleId != null) {
                      await FirebaseFirestore.instance
                          .collection('couples')
                          .doc(appState.currentCoupleId)
                          .collection('calendar_events')
                          .add({
                        'title': titleController.text.trim(),
                        'date': Timestamp.fromDate(selectedDate!),
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Add Event', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          }
        );
      }
    );
  }

  Widget _buildEventCard(String title, String date, Color color, VoidCallback onTap) {
    return BouncingButton(
      onTap: onTap,
      child: GlassContainer(
        color: Colors.white.withOpacity(0.05),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.5))),
              child: Icon(Icons.event, color: color),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white), overflow: TextOverflow.ellipsis),
                  Text(date, style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70), overflow: TextOverflow.ellipsis),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFAB() {
    return BouncingButton(
      onTap: _showAddEventDialog,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFF4D6D), Color(0xFFFF7A00)]),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: const Color(0xFFFF4D6D).withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

class DriftingParticles extends StatefulWidget {
  const DriftingParticles({super.key});
  @override
  State<DriftingParticles> createState() => _DriftingParticlesState();
}

class _DriftingParticlesState extends State<DriftingParticles> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = List.generate(20, (index) => _Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ParticlePainter(_particles, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  final Random random = Random();
  late double x, y, speed, size;
  _Particle() {
    _reset(random.nextDouble());
  }
  void _reset(double startY) {
    x = random.nextDouble();
    y = startY;
    speed = 0.05 + random.nextDouble() * 0.1;
    size = 1 + random.nextDouble() * 2.5;
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFF4D6D).withOpacity(0.3);
    for (var p in particles) {
      double currentY = p.y - (progress * p.speed * 10);
      if (currentY < 0) {
        p._reset(1.1);
        currentY = p.y;
      }
      canvas.drawCircle(Offset(p.x * size.width, currentY * size.height), p.size, paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
