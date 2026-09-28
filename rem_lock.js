const fs = require('fs');
const path = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(path, 'utf8');

const lockBlock = `                                    if (isLocked)
                                      Positioned.fill(
                                        child: Container(
                                          margin: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.65),
                                            borderRadius: BorderRadius.circular(24),
                                          ),
                                          child: const Center(
                                            child: Icon(Icons.lock, color: Colors.white, size: 48),
                                          ),
                                        ),
                                      ),`;
gzs = gzs.replace(lockBlock, '');
fs.writeFileSync(path, gzs, 'utf8');
console.log('Removed lock overlay');
