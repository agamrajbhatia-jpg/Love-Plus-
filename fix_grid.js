const fs = require('fs');
const gzsPath = 'c:/Users/agamr/Documents/CoupleApp/lib/screens/modes/game_zone_screen.dart';
let gzs = fs.readFileSync(gzsPath, 'utf8');

// 1. GridView.builder sizes
gzs = gzs.replace(/crossAxisSpacing: \d+,/g, 'crossAxisSpacing: 16,');
gzs = gzs.replace(/mainAxisSpacing: \d+,/g, 'mainAxisSpacing: 16,');
gzs = gzs.replace(/childAspectRatio: 0\.65,/g, 'childAspectRatio: 0.75,');

// 2. _GameCard overflow
const oldColumn = `        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.contain,
                child: Text(
                  icon,
                  style: const TextStyle(fontSize: 48),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)
                  ]
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),`;

const newColumn = `        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(icon, style: const TextStyle(fontSize: 48)),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)]
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withOpacity(0.9)),
                ),
              ),
            ),
          ],
        ),`;
gzs = gzs.replace(oldColumn, newColumn);

// _buildDeckButton Column
const oldDeckColumn = `        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(icon, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                title.replaceAll(' ', '\\n'),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)
                  ]
                ),
              ),
            ],
          ),
        ),`;

const newDeckColumn = `        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              flex: 3,
              child: FittedBox(
                fit: BoxFit.contain,
                child: Text(icon, style: const TextStyle(fontSize: 32)),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              flex: 2,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title.replaceAll(' ', '\\n'),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                    color: Colors.white,
                    shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)]
                  ),
                ),
              ),
            ),
          ],
        ),`;
gzs = gzs.replace(oldDeckColumn, newDeckColumn);

fs.writeFileSync(gzsPath, gzs, 'utf8');
console.log('Fixed grid and gamecard');
