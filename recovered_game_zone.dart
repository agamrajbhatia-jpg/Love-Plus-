Created At: 2026-08-26T23:50:48+05:30
Completed At: 2026-08-26T23:50:49+05:30
File Path: `file:///c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart`
Total Lines: 668
Total Bytes: 25097
Showing lines 1 to 668
The following code has been modified to include a line number before every line, in the format: <line_number>: <original_line>. Please note that any changes targeting the original code should remove the line number, colon, and leading space.
1: import 'package:flutter/material.dart';
2: import 'package:google_fonts/google_fonts.dart';
3: import 'package:provider/provider.dart';
4: import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
5: import 'package:cloud_firestore/cloud_firestore.dart';
6: 
7: import '../../providers/app_state.dart';
8: import '../../widgets/glass_container.dart';
9: import '../../widgets/bouncing_button.dart';
10: import '../games/would_you_rather_screen.dart';
11: import '../games/how_well_do_you_know_me_screen.dart';
12: import '../games/scenario_scale_screen.dart';
13: import '../games/tic_tac_toe_screen.dart';
14: import '../games/how_mad_screen.dart';
15: import '../games/expose_us_screen.dart';
16: import '../games/live_card_game_screen.dart';
17: import '../games/ranking_date_ideas_screen.dart';
18: 
19: class GameZoneScreen extends StatefulWidget {
20:   const GameZoneScreen({super.key});
21: 
22:   @override
23:   State<GameZoneScreen> createState() => _GameZoneScreenState();
24: }
25: 
26: class _GameZoneScreenState extends State<GameZoneScreen> {
27: 
28:   void _showPremiumLock(BuildContext context) {
29:     showModalBottomSheet(
30:       context: context,
31:       backgroundColor: Colors.transparent,
32:       isScrollControlled: true,
33:       builder: (context) {
34:         return SafeArea(
35:           child: Container(
36:             margin: const EdgeInsets.all(16),
37:             padding: const EdgeInsets.all(24),
38:             decoration: BoxDecoration(
39:               color: const Color(0xFFFFE5EC), // Soft Pastel Pink
40:               borderRadius: BorderRadius.circular(30),
41:               boxShadow: [
42:                 BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)
43:               ],
44:             ),
45:             child: Column(
46:               mainAxisSize: MainAxisSize.min,
47:               children: [
48:                 const Text("🔒", style: TextStyle(fontSize: 48)),
49:                 const SizedBox(height: 16),
50:                 Text(
51:                   "Free Play Used Today!",
52:                   textAlign: TextAlign.center,
53:                   style: GoogleFonts.poppins(
54:                     fontSize: 22,
55:                     fontWeight: FontWeight.bold,
56:                     color: const Color(0xFFD81B60),
57:                   ),
58:                 ),
59:                 const SizedBox(height: 8),
60:                 Text(
61:                   "You've already played this game today. Come back tomorrow, or unlock endless fun!",
62:                   textAlign: TextAlign.center,
63:                   style: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
64:                 ),
65:                 const SizedBox(height: 24),
66:                 BouncingButton(
67:                   onTap: () => Navigator.pop(context),
68:                   child: Container(
69:                     width: double.infinity,
70:                     padding: const EdgeInsets.symmetric(vertical: 16),
71:                     decoration: BoxDecoration(
72:                       gradient: const LinearGradient(colors: [Color(0xFFFF9A9E), Color(0xFFFECFEF)]),
73:                       borderRadius: BorderRadius.circular(30),
74:                       boxShadow: [
75:                         BoxShadow(color: const Color(0xFFFF9A9E).withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))
76:                       ],
77:                     ),
78:                     child: Text(
79:                       "Upgrade to Premium for Unlimited Play ✨",
80:                       textAlign: TextAlign.center,
81:                       style: GoogleFonts.poppins(
82:                         fontSize: 14,
83:                         fontWeight: FontWeight.bold,
84:                         color: Colors.white,
85:                       ),
86:                     ),
87:                   ),
88:                 ),
89:                 const SizedBox(height: 12),
90:                 TextButton(
91:                   onPressed: () => Navigator.pop(context),
92:                   child: Text(
93:                     "Maybe later",
94:                     style: GoogleFonts.poppins(color: Colors.black54, fontWeight: FontWeight.bold),
95:                   ),
96:                 )
97:               ],
98:             ),
99:           ),
100:         );
101:       }
102:     );
103:   }
104: 
105:   Widget _buildDeckButton(BuildContext context, String title, String icon, List<Color> gradientColors) {
106:     return BouncingButton(
107:       onTap: () {
108:         Navigator.push(context, MaterialPageRoute(builder: (context) => LiveCardGameScreen(deckName: title)));
109:       },
110:       child: Container(
111:         padding: const EdgeInsets.all(16),
112:         decoration: BoxDecoration(
113:           gradient: LinearGradient(
114:             colors: gradientColors,
115:             begin: Alignment.topLeft,
116:             end: Alignment.bottomRight,
117:           ),
118:           borderRadius: BorderRadius.circular(24),
119:           boxShadow: [
120:             BoxShadow(color: gradientColors.first.withOpacity(0.5), blurRadius: 15, offset: const Offset(0, 5))
121:           ],
122:         ),
123:         child: Column(
124:           mainAxisAlignment: MainAxisAlignment.center,
125:           children: [
126:             Text(icon, style: const TextStyle(fontSize: 32)),
127:             const SizedBox(height: 4),
128:             Expanded(
129:               child: Center(
130:                 child: FittedBox(
131:                   fit: BoxFit.scaleDown,
132:                   child: Text(
133:                     title.replaceAll(' ', '\n'),
134:                     textAlign: TextAlign.center,
135:                     style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
136:                   ),
137:                 ),
138:               ),
139:             ),
140:           ],
141:         ),
142:       ),
143:     );
144:   }
145: 
146:   @override
147:   Widget build(BuildContext context) {
148:     final appState = context.watch<AppState>();
149: 
150:     final games = [
151:       {
152:         "title": "Would You Rather?",
153:         "subtitle": "Spicy & Sweet",
154:         "icon": "🔥🍬",
155:         "color": const Color(0xFFFF9A9E), // Pastel Pink
156:         "onTap": () {
157:           Navigator.push(context, MaterialPageRoute(builder: (context) => const WouldYouRatherScreen()));
158:         },
159:       },
160:       {
161:         "title": "How Well Do You Know Me?",
162:         "subtitle": "The Ultimate Test",
163:         "icon": "🧠💭",
164:         "color": const Color(0xFFA1C4FD), // Pastel Blue
165:         "onTap": () {
166:           Navigator.push(context, MaterialPageRoute(builder: (context) => const HowWellDoYouKnowMeScreen()));
167:         },
168:       },
169:       {
170:         "title": "Scenario Scale",
171:         "subtitle": "Rate situations 1-10",
172:         "icon": "⚖️",
173:         "color": const Color(0xFF4ECDC4), // Soft teal
174:         "onTap": () {
175:           Navigator.push(context, MaterialPageRoute(builder: (context) => const ScenarioScaleScreen()));
176:         },
177:       },
178:       {
179:         "title": "Tic-Tac-Toe",
180:         "subtitle": "Classic game",
181:         "icon": "❌⭕️",
182:         "color": const Color(0xFFa18cd1), // Muted purple
183:         "onTap": () {
184:           Navigator.push(context, MaterialPageRoute(builder: (context) => TicTacToeScreen(
185:             coupleId: appState.currentCoupleId,
186:             currentUserId: appState.currentUid,
187:           )));
188:         },
189:       },
190:       {
191:         "title": "How Mad?",
192:         "subtitle": "Rate it 1-10",
193:         "icon": "🤬",
194:         "color": const Color(0xFF8FD3F4), // Pastel cyan
195:         "onTap": () {
196:           Navigator.push(context, MaterialPageRoute(builder: (context) => const HowMadScreen()));
197:         },
198:       },
199:       {
200:         "title": "Expose Us!",
201:         "subtitle": "Who is more likely?",
202:         "icon": "🥊",
203:         "color": const Color(0xFFFFB6C1), // Light pink
204:         "onTap": () {
205:           Navigator.push(context, MaterialPageRoute(builder: (context) => const ExposeUsScreen()));
206:         },
207:       },
208:       {
209:         "title": "Blindly Ranking Date Ideas",
210:         "subtitle": "Daily sync game",
211:         "icon": "🏆",
212:         "color": const Color(0xFFAB47BC), // Purple
213:         "onTap": () {
214:           Navigator.push(context, MaterialPageRoute(builder: (context) => RankingDateIdeasScreen(
215:             coupleId: appState.currentCoupleId,
216:             currentUserId: appState.currentUid,
217:           )));
218:         },
219:       },
220:     ];
221: 
222:     return SafeArea(
223:       child: Stack(
224:         children: [
225:           SingleChildScrollView(
226:             physics: const BouncingScrollPhysics(),
227:             padding: const EdgeInsets.only(top: 80, left: 20, right: 20, bottom: 120),
228:             child: Column(
229:               crossAxisAlignment: CrossAxisAlignment.start,
230:               children: [
231:                 Text(
232:                   "Game Zone",
233:                   style: GoogleFonts.poppins(
234:                     fontSize: 32,
235:                     fontWeight: FontWeight.bold,
236:                     color: Colors.white,
237:                     shadows: [
238:                       Shadow(color: const Color(0xFFFF1493).withOpacity(0.5), blurRadius: 10)
239:                     ]
240:                   ),
241:                 ),
242:                 const SizedBox(height: 8),
243:                 Text(
244:                   "Challenge your partner to cute PvP games!",
245:                   style: GoogleFonts.poppins(
246:                     fontSize: 16,
247:                     color: Colors.white70,
248:                   ),
249:                 ),
250:                 const SizedBox(height: 30),
251:                 StreamBuilder<QuerySnapshot>(
252:                   stream: (appState.currentCoupleId != null && appState.currentUid != null)
253:                       ? FirebaseFirestore.instance
254:                           .collection('couples')
255:                           .doc(appState.currentCoupleId)
256:                           .collection('challenges')
257:                           .where('targetId', isEqualTo: appState.currentUid)
258:                           .where('status', isEqualTo: 'pending')
259:                           .snapshots()
260:                       : const Stream.empty(),
261:                   builder: (context, snapshot) {
262:                     if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
263:                       return const SizedBox.shrink();
264:                     }
265:                     
266:                     final docs = snapshot.data!.docs;
267:                     
268:                     return Column(
269:                       crossAxisAlignment: CrossAxisAlignment.start,
270:                       children: [
271:                         Text(
272:                           "New Challenges!",
273:                           style: GoogleFonts.poppins(
274:                             fontSize: 18,
275:                             fontWeight: FontWeight.bold,
276:                             color: Colors.white,
277:                           ),
278:                         ),
279:                         const SizedBox(height: 12),
280:                         SizedBox(
281:                           height: 120,
282:                           child: ListView.builder(
283:                             scrollDirection: Axis.horizontal,
284:                             physics: const BouncingScrollPhysics(),
285:                             itemCount: docs.length,
286:                             itemBuilder: (context, index) {
287:                               final data = docs[index].data() as Map<String, dynamic>;
288:                               // Merge doc id into data map
289:                               final challenge = {...data, 'id': docs[index].id};
290:                               
291:                               return GestureDetector(
292:                                 onTap: () {
293:                                   if (challenge['type'] == 'how_mad' || challenge['gameType'] == 'how_mad') {
294:                                     Navigator.push(
295:                                       context, 
296:                                       MaterialPageRoute(
297:                                         builder: (context) => HowMadScreen(challengeToPlay: challenge)
298:                                       )
299:                                     );
300:                                   } else if (challenge['type'] == 'scenario' || challenge['gameType'] == 'scenario') {
301:                                     Navigator.push(
302:                                       context, 
303:                                       MaterialPageRoute(
304:                                         builder: (context) => ScenarioScaleScreen(challengeToPlay: challenge)
305:                                       )
306:                                     );
307:                                   } else {
308:                                     Navigator.push(
309:                                       context, 
310:                                       MaterialPageRoute(
311:                                         builder: (context) => HowWellDoYouKnowMeScreen(challengeToPlay: challenge)
312:                                       )
313:                                     );
314:                                   }
315:                                 },
316:                                 child: Container(
317:                                   width: 160,
318:                                   margin: const EdgeInsets.only(right: 12),
319:                                   padding: const EdgeInsets.all(16),
320:                                   decoration: BoxDecoration(
321:                                     gradient: const LinearGradient(
322:                                       colors: [Color(0xFFA1C4FD), Color(0xFFC2E9FB)]
323:                                     ),
324:                                     borderRadius: BorderRadius.circular(20),
325:                                     boxShadow: [
326:                                       BoxShadow(
327:                                         color: const Color(0xFFA1C4FD).withOpacity(0.4), 
328:                                         blurRadius: 10, 
329:                                         offset: const Offset(0, 4)
330:                                       )
331:                                     ],
332:                                   ),
333:                                   child: Column(
334:                                     mainAxisAlignment: MainAxisAlignment.center,
335:                                     mainAxisSize: MainAxisSize.min,
336:                                     children: [
337:                                       const Flexible(
338:                                         child: Text("💌", style: TextStyle(fontSize: 32)),
339:                                       ),
340:                                       const SizedBox(height: 4),
341:                                       Flexible(
342:                                         child: Text(
343:                                           "New Challenge!",
344:                                           textAlign: TextAlign.center,
345:                                           maxLines: 2,
346:                                           overflow: TextOverflow.ellipsis,
347:                                           style: GoogleFonts.poppins(
348:                                             fontSize: 14,
349:                                             fontWeight: FontWeight.bold,
350:                                             color: Colors.white,
351:                                           ),
352:                                         ),
353:                                       ),
354:                                     ],
355:                                   ),
356:                                 ),
357:                               );
358:                             },
359:                           ),
360:                         ),
361:                         const SizedBox(height: 30),
362:                       ],
363:                     );
364:                   }
365:                 ),
366:                 const SizedBox(height: 10),
367:                 Text(
368:                   "Couple Cards",
369:                   style: GoogleFonts.poppins(
370:                     fontSize: 18,
371:                     fontWeight: FontWeight.bold,
372:                     color: Colors.white,
373:                   ),
374:                 ),
375:                 const SizedBox(height: 12),
376:                 GridView.count(
377:                   shrinkWrap: true,
378:                   physics: const NeverScrollableScrollPhysics(),
379:                   crossAxisCount: 2,
380:                   crossAxisSpacing: 16,
381:                   mainAxisSpacing: 16,
382:                   childAspectRatio: 0.85,
383:                   children: [
384:                     _buildDeckButton(context, 'Icebreakers & Fun', '🎈', const [Color(0xFFFF9A9E), Color(0xFFFECFEF)]),
385:                     _buildDeckButton(context, 'Deep Dive Talk', '❤️‍🔥', const [Color(0xFFE55D87), Color(0xFF5FC3E4)]),
386:                     _buildDeckButton(context, 'Playful Challenges', '🃏', const [Color(0xFF00F0FF), Color(0xFF00B4DB)]),
387:                     _buildDeckButton(context, 'Spontaneous Date Ideas', '🌌', const [Color(0xFFA1C4FD), Color(0xFFC2E9FB)]),
388:                   ],
389:                 ),
390:                 const SizedBox(height: 30),
391:                 Text(
392:                   "Game Library",
393:                   style: GoogleFonts.poppins(
394:                     fontSize: 18,
395:                     fontWeight: FontWeight.bold,
396:                     color: Colors.white,
397:                   ),
398:                 ),
399:                 const SizedBox(height: 12),
400:                 AnimationLimiter(
401:                   child: GridView.builder(
402:                     shrinkWrap: true,
403:                     physics: const NeverScrollableScrollPhysics(),
404:                     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
405:                       crossAxisCount: 2,
406:                       crossAxisSpacing: 24,
407:                       mainAxisSpacing: 24,
408:                       childAspectRatio: 0.65,
409:                     ),
410:                     itemCount: games.length,
411:                     itemBuilder: (context, index) {
412:                       final game = games[index];
413:                       return AnimationConfiguration.staggeredGrid(
414:                         position: index,
415:                         duration: const Duration(milliseconds: 500),
416:                         columnCount: 2,
417:                         child: ScaleAnimation(
418:                           child: FadeInAnimation(
419:                             child: _GameCard(
420:                               title: game['title'] as String,
421:                               subtitle: game['subtitle'] as String,
422:                               icon: game['icon'] as String,
423:                               color: game['color'] as Color,
424:                               onTapAction: game['onTap'] as VoidCallback?,
425:                             ),
426:                           ),
427:                         ),
428:                       );
429:                     },
430:                   ),
431:                 ),
432:               ],
433:             ),
434:           ),
435:           
436:           // Persistent Scoreboard Widget
437:           Positioned(
438:             top: 10,
439:             right: 20,
440:             child: _ScoreboardWidget(
441:               userScore: appState.userGameScore,
442:               partnerScore: appState.partnerGameScore,
443:               partnerName: appState.partnerName ?? "Partner",
444:             ),
445:           ),
446:         ],
447:       ),
448:     );
449:   }
450: }
451: 
452: class _ScoreboardWidget extends StatelessWidget {
453:   final int userScore;
454:   final int partnerScore;
455:   final String partnerName;
456: 
457:   const _ScoreboardWidget({
458:     required this.userScore,
459:     required this.partnerScore,
460:     required this.partnerName,
461:   });
462: 
463:   @override
464:   Widget build(BuildContext context) {
465:     return GlassContainer(
466:       blur: 20,
467:       borderRadius: 30,
468:       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
469:       color: Colors.white.withOpacity(0.15),
470:       child: Row(
471:         mainAxisSize: MainAxisSize.min,
472:         children: [
473:           _ScorePill(name: "You", score: userScore, color: const Color(0xFFFF6B6B)),
474:           const SizedBox(width: 8),
475:           Text(
476:             "⚔️",
477:             style: const TextStyle(fontSize: 14),
478:           ),
479:           const SizedBox(width: 8),
480:           _ScorePill(name: partnerName, score: partnerScore, color: const Color(0xFF4ECDC4)),
481:         ],
482:       ),
483:     );
484:   }
485: }
486: 
487: class _ScorePill extends StatelessWidget {
488:   final String name;
489:   final int score;
490:   final Color color;
491: 
492:   const _ScorePill({required this.name, required this.score, required this.color});
493: 
494:   @override
495:   Widget build(BuildContext context) {
496:     return Column(
497:       mainAxisSize: MainAxisSize.min,
498:       children: [
499:         Text(
500:           name,
501:           style: GoogleFonts.poppins(
502:             fontSize: 10,
503:             fontWeight: FontWeight.bold,
504:             color: Colors.white70,
505:           ),
506:         ),
507:         Row(
508:           children: [
509:             Text(
510:               "$score",
511:               style: GoogleFonts.poppins(
512:                 fontSize: 22,
513:                 fontWeight: FontWeight.w900,
514:                 color: Colors.white,
515:                 shadows: [Shadow(color: color, blurRadius: 12)]
516:               ),
517:             ),
518:             const SizedBox(width: 4),
519:             const Icon(Icons.favorite, color: Colors.pinkAccent, size: 14),
520:           ],
521:         )
522:       ],
523:     );
524:   }
525: }
526: 
527: class _GameCard extends StatelessWidget {
528:   final String title;
529:   final String subtitle;
530:   final String icon;
531:   final Color color;
532:   final VoidCallback? onTapAction;
533: 
534:   const _GameCard({
535:     required this.title,
536:     required this.subtitle,
537:     required this.icon,
538:     required this.color,
539:     this.onTapAction,
540:   });
541: 
542:   @override
543:   Widget build(BuildContext context) {
544:     return BouncingButton(
545:       onTap: () {
546:         if (onTapAction != null) {
547:           onTapAction!();
548:         } else {
549:           showDialog(
550:             context: context,
551:             barrierColor: Colors.black12,
552:             builder: (dialogContext) {
553:               Future.delayed(const Duration(seconds: 2), () {
554:                 if (dialogContext.mounted) Navigator.pop(dialogContext);
555:               });
556:               return SafeArea(
557:                 child: Align(
558:                   alignment: Alignment.bottomCenter,
559:                   child: Padding(
560:                     padding: const EdgeInsets.only(bottom: 120.0),
561:                     child: Material(
562:                       color: Colors.transparent,
563:                       child: Container(
564:                         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
565:                         decoration: BoxDecoration(
566:                           color: color.withOpacity(0.9),
567:                           borderRadius: BorderRadius.circular(30),
568:                           boxShadow: [
569:                             BoxShadow(
570:                               color: color.withOpacity(0.5),
571:                               blurRadius: 15,
572:                               offset: const Offset(0, 5),
573:                             )
574:                           ],
575:                         ),
576:                         child: Text(
577:                           "Loading $title...",
578:                           textAlign: TextAlign.center,
579:                           style: GoogleFonts.poppins(
580:                             fontSize: 16,
581:                             fontWeight: FontWeight.bold,
582:                             color: Colors.white,
583:                           ),
584:                         ),
585:                       ),
586:                     ),
587:                   ),
588:                 ),
589:               );
590:             }
591:           );
592:         }
593:       },
594:       child: Container(
595:         decoration: BoxDecoration(
596:           borderRadius: BorderRadius.circular(24),
597:           gradient: LinearGradient(
598:             begin: Alignment.topLeft,
599:             end: Alignment.bottomRight,
600:             colors: [
601:               color.withOpacity(0.9),
602:               color.withOpacity(0.5),
603:             ],
604:           ),
605:           boxShadow: [
606:             BoxShadow(
607:               color: color.withOpacity(0.4),
608:               blurRadius: 15,
609:               offset: const Offset(0, 8),
610:             )
611:           ]
612:         ),
613:         padding: const EdgeInsets.all(16.0),
614:         child: Column(
615:           mainAxisAlignment: MainAxisAlignment.center,
616:           children: [
617:             Expanded(
618:               flex: 3,
619:               child: FittedBox(
620:                 fit: BoxFit.scaleDown,
621:                 child: Text(icon, style: const TextStyle(fontSize: 48)),
622:               ),
623:             ),
624:             const SizedBox(height: 4),
625:             Expanded(
626:               flex: 2,
627:               child: Center(
628:                 child: FittedBox(
629:                   fit: BoxFit.scaleDown,
630:                   child: Text(
631:                     title,
632:                     textAlign: TextAlign.center,
633:                     maxLines: 2,
634:                     style: GoogleFonts.poppins(
635:                       fontSize: 14,
636:                       fontWeight: FontWeight.bold,
637:                       height: 1.1,
638:                       color: Colors.white,
639:                       shadows: [
640:                         Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)
641:                       ]
642:                     ),
643:                   ),
644:                 ),
645:               ),
646:             ),
647:             const SizedBox(height: 2),
648:             Expanded(
649:               flex: 1,
650:               child: FittedBox(
651:                 fit: BoxFit.scaleDown,
652:                 child: Text(
653:                   subtitle,
654:                   textAlign: TextAlign.center,
655:                   style: GoogleFonts.poppins(
656:                     fontSize: 11,
657:                     color: Colors.white.withOpacity(0.9),
658:                   ),
659:                 ),
660:               ),
661:             ),
662:           ],
663:         ),
664:       ),
665:     );
666:   }
667: }
668: 
The above content shows the entire, complete file contents of the requested file.
