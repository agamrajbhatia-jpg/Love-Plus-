const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(path, 'utf8');

const oldGameCard = `                                    _GameCard(
                                      title: gameTitle,
                                      subtitle: game['subtitle'] as String,
                                      icon: game['icon'] as String,
                                      color: game['color'] as Color,
                                      onTapAction: game['onTap'] as VoidCallback?,
                                    ),`;

const newGameCard = `                                    _GameCard(
                                      title: gameTitle,
                                      subtitle: game['subtitle'] as String,
                                      icon: game['icon'] as String,
                                      color: game['color'] as Color,
                                      onTapAction: () {
                                        if (gameTitle.toLowerCase().contains('would you rather')) {
                                          _handleGameTap(gameTitle, () {
                                            Navigator.push(context, MaterialPageRoute(builder: (context) => const WouldYouRatherScreen()));
                                          });
                                          return;
                                        }
                                        final VoidCallback? tapAction = game['onTap'] as VoidCallback?;
                                        if (tapAction != null) {
                                          tapAction();
                                        }
                                      },
                                    ),`;

gzs = gzs.replace(oldGameCard, newGameCard);
fs.writeFileSync(path, gzs, 'utf8');
console.log('Fixed GameCard routing');
