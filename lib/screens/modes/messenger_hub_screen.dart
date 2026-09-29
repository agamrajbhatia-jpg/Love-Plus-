import 'dart:async';
import 'dart:math';
import 'dart:io';
import 'dart:ui';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:audioplayers/audioplayers.dart';

import '../../providers/app_state.dart';

class MessengerHubScreen extends StatefulWidget {
  const MessengerHubScreen({super.key});

  @override
  State<MessengerHubScreen> createState() => _MessengerHubScreenState();
}

class _MessengerHubScreenState extends State<MessengerHubScreen> {
  final TextEditingController _msgController = TextEditingController();
  bool _isGiftMode = false;
  String? _replyingTo;
  bool get _isTyping => _msgController.text.isNotEmpty;

  bool _isUploadingMedia = false;

  @override
  void initState() {
    super.initState();
    _msgController.addListener(() {
      setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().markMessagesAsRead();
      }
    });
  }

  @override
  void dispose() {
    _msgController.dispose();
    super.dispose();
  }

  void _showThemeBottomSheet(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A).withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose Ambiance', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ...appState.availableThemes.map((theme) {
              bool isSelected = appState.chatTheme?.id == theme.id;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  appState.setChatTheme(theme);
                  Navigator.pop(context);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? theme.accentColor : Colors.white10, width: isSelected ? 2.5 : 1.0),
                    boxShadow: isSelected ? [BoxShadow(color: theme.accentColor.withOpacity(0.3), blurRadius: 12, spreadRadius: 2)] : [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Background Gradient
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: theme.backgroundColors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                          ),
                        ),
                        // Mini bubbles preview
                        Positioned(
                          right: 12, top: 12,
                          child: Container(
                            width: 60, height: 16,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: theme.userBubbleColors),
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8), bottomLeft: Radius.circular(8), bottomRight: Radius.circular(2)),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 12, top: 36,
                          child: Container(
                            width: 50, height: 16,
                            decoration: BoxDecoration(
                              color: theme.partnerBubbleColors.first,
                              border: Border.all(color: theme.partnerBorderColor ?? Colors.transparent, width: 1),
                              borderRadius: const BorderRadius.only(topLeft: Radius.circular(8), topRight: Radius.circular(8), bottomLeft: Radius.circular(2), bottomRight: Radius.circular(8)),
                            ),
                          ),
                        ),
                        // Foreground Info
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                              begin: Alignment.bottomCenter, end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16, bottom: 12, right: 16,
                          child: Row(
                            children: [
                              Text(theme.emoji, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(theme.name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              if (isSelected)
                                Icon(Icons.check_circle, color: theme.accentColor, size: 22),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  void _showSettingsBottomSheet(BuildContext context, AppState appState) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A).withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Chat Settings', style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.done_all, color: Colors.blueAccent),
                  title: Text('Read Receipts', style: GoogleFonts.poppins(color: Colors.white)),
                  subtitle: Text('Show when messages have been seen', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                  trailing: Switch(
                    value: appState.readReceiptsEnabled,
                    activeColor: Colors.blueAccent,
                    onChanged: (val) {
                      setModalState(() => appState.toggleReadReceipts(val));
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final theme = appState.chatTheme ?? appState.availableThemes.first;
    final partnerName = appState.partnerName ?? 'Partner';

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _DynamicBackground(theme: theme),
          SafeArea(
            child: Column(
              children: [
                _buildIGHeader(theme, partnerName, appState),
                Expanded(
                  child: RepaintBoundary(
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 32),
                      physics: const BouncingScrollPhysics(),
                      itemCount: appState.messages.length,
                      itemBuilder: (context, index) {
                        final msg = appState.messages[index];
                        final isLastUserMessage = msg.isUser && index == appState.messages.indexWhere((m) => m.isUser);
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildMessageItem(context, msg, theme, appState),
                            if (isLastUserMessage)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12.0, right: 8.0, top: 4.0),
                                child: (appState.readReceiptsEnabled && msg.isRead)
                                    ? Text('Seen \u2713\u2713', textAlign: TextAlign.right, style: GoogleFonts.poppins(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold, shadows: [const Shadow(color: Colors.blueAccent, blurRadius: 8)]))
                                    : Text('Delivered \u2713', textAlign: TextAlign.right, style: GoogleFonts.poppins(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                              ),
                            const SizedBox(height: 12),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                if (_replyingTo != null) _buildReplyBanner(),
                if (appState.isPartnerTyping)
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0, bottom: 8.0),
                    child: Row(
                      children: [
                        Text('$partnerName is typing', style: GoogleFonts.poppins(color: theme.accentColor, fontSize: 12, fontStyle: FontStyle.italic)),
                        const SizedBox(width: 2),
                        _AnimatedDots(color: theme.accentColor),
                      ],
                    ),
                  ),
                _buildIGInputBar(appState, theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIGHeader(ChatTheme theme, String partnerName, AppState appState) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B132B).withOpacity(0.5),
            border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.1))),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.accentColor.withOpacity(0.5),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(partnerName, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 4)]
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Active now', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.palette, color: Colors.white, size: 24),
                onPressed: () => _showThemeBottomSheet(context, appState),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 24),
                onPressed: () => _showSettingsBottomSheet(context, appState),
              )
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildMessageItem(BuildContext context, ChatMessage msg, ChatTheme theme, AppState appState) {
    final bool useDarkText = false;
    
    Widget bubble;
    if (msg.type == 'time_capsule') {
      bubble = _TimeCapsuleBubble(theme: theme);
    } else if (msg.type == 'gift') {
      bubble = _GiftMessageBubble(msg: msg, theme: theme, useDarkText: useDarkText);
    } else if (msg.type == 'audio') {
      bubble = _AudioMessageBubble(msg: msg, theme: theme);
    } else if (msg.type == 'love_board_post' || (msg.type == 'system' && msg.text.contains('just posted'))) {
      String displayTxt;
      if (msg.realSenderId == appState.currentUid) {
        displayTxt = "You just posted a ${msg.purpose ?? 'Love'} letter.";
      } else {
        displayTxt = "${appState.partnerName ?? 'Your partner'} just posted a ${msg.purpose ?? 'Love'} letter.";
      }
      bubble = _buildStyledBubble(ChatMessage(
        id: msg.id, text: displayTxt, isUser: false, timestamp: msg.timestamp, type: 'system', isLiked: msg.isLiked, isRead: msg.isRead
      ), theme, useDarkText);
    } else {
      bubble = _buildStyledBubble(msg, theme, useDarkText);
    }

    return Dismissible(
      key: ValueKey(msg.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.reply, color: Colors.white54, size: 24),
      ),
      confirmDismiss: (direction) async {
        setState(() => _replyingTo = msg.text.isNotEmpty ? msg.text : 'Media');
        return false;
      },
      child: GestureDetector(
        onDoubleTap: () => appState.toggleLike(msg.id),
        child: Align(
          alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              bubble,
              if (msg.isLiked)
                Positioned(
                  bottom: -10, 
                  right: msg.isUser ? -10 : -10,
                  child: const _ParticleHeartBurst(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyledBubble(ChatMessage msg, ChatTheme theme, bool useDarkText) {
    Widget content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (msg.replyingToText != null)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.only(left: 8),
            decoration: BoxDecoration(border: Border(left: BorderSide(color: useDarkText ? Colors.black26 : Colors.white54, width: 2))),
            child: Text(msg.replyingToText!, style: GoogleFonts.poppins(color: useDarkText ? Colors.black54 : Colors.white70, fontSize: 11, fontStyle: FontStyle.italic)),
          ),
        if (msg.type == 'image' && msg.imageUrl != null)
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.0),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20), 
              child: GestureDetector(
                onTap: () {
                  Navigator.push(context, PageRouteBuilder(
                    pageBuilder: (context, animation, secondaryAnimation) => FullScreenImageViewer(imageUrl: msg.imageUrl!, tag: msg.id),
                    transitionsBuilder: (context, animation, secondaryAnimation, child) {
                      return FadeTransition(opacity: animation, child: child);
                    },
                  ));
                },
                child: Hero(
                  tag: msg.id,
                  child: CachedNetworkImage(
                    imageUrl: msg.imageUrl!, 
                    width: 220, 
                    height: 220,
                    fit: BoxFit.cover,
                    placeholder: (context, url) {
                      return Shimmer.fromColors(
                        baseColor: Colors.white.withOpacity(0.1),
                        highlightColor: Colors.white.withOpacity(0.3),
                        child: Container(width: 220, height: 220, color: Colors.white),
                      );
                    },
                    errorWidget: (context, url, error) {
                      return Container(
                        width: 220, height: 220,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: theme.userBubbleColors.map((c) => c.withOpacity(0.3)).toList()),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.favorite_outline, color: Colors.white54, size: 40),
                              const SizedBox(height: 8),
                              Text('Photo Saved', style: GoogleFonts.poppins(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              )
            ),
          )
        else if (msg.type == 'secret_ink')
          _SecretInkBubble(text: msg.text, useDarkText: useDarkText)
        else
          Text(msg.text, style: GoogleFonts.poppins(color: msg.isUser ? theme.userTextColor : theme.partnerTextColor, fontSize: 15, fontWeight: FontWeight.w400)),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(24),
          topRight: const Radius.circular(24),
          bottomLeft: msg.isUser ? const Radius.circular(24) : const Radius.circular(6),
          bottomRight: msg.isUser ? const Radius.circular(6) : const Radius.circular(24),
        ),
        gradient: LinearGradient(
          colors: msg.isUser 
              ? theme.userBubbleColors
              : theme.partnerBubbleColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: msg.isUser ? Colors.transparent : (theme.partnerBorderColor ?? Colors.transparent),
          width: 1.0,
        ),
        boxShadow: msg.isUser ? [
          BoxShadow(
            color: theme.userShadowColor.withOpacity(0.35),
            blurRadius: 16,
            spreadRadius: -2,
            offset: const Offset(0, 4),
          )
        ] : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(24),
          topRight: const Radius.circular(24),
          bottomLeft: msg.isUser ? const Radius.circular(24) : const Radius.circular(6),
          bottomRight: msg.isUser ? const Radius.circular(6) : const Radius.circular(24),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: msg.type == 'image' ? 4 : 18, 
              vertical: msg.type == 'image' ? 4 : 12
            ),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _buildReplyBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1)))),
      child: Row(
        children: [
          const Icon(Icons.reply, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text('Replying to: $_replyingTo', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
          IconButton(icon: const Icon(Icons.close, color: Colors.white70, size: 20), onPressed: () => setState(() => _replyingTo = null), padding: EdgeInsets.zero, constraints: const BoxConstraints())
        ],
      ),
    );
  }

  Widget _buildIGInputBar(AppState appState, ChatTheme theme) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
        child: RepaintBoundary(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: theme.backgroundColors.first.withOpacity(0.4),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _isUploadingMedia
                      ? const Padding(padding: EdgeInsets.all(8), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2)))
                      : _buildInputIcon(Icons.add_photo_alternate_rounded, () async {
                          final picker = ImagePicker();
                          final xFile = await picker.pickImage(source: ImageSource.gallery);
                          if (xFile != null) {
                            setState(() => _isUploadingMedia = true);
                            final url = await appState.uploadImage(File(xFile.path));
                            setState(() => _isUploadingMedia = false);
                            if (url != null) {
                              appState.addMessage(ChatMessage(
                                id: DateTime.now().toString(), text: '', isUser: true, type: 'image', imageUrl: url,
                              ));
                            }
                          }
                        }, color: Colors.white70, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2), 
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _isGiftMode ? const Color(0xFFFFD700).withOpacity(0.5) : Colors.white.withOpacity(0.05), 
                            width: 1.5
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _msgController,
                                style: GoogleFonts.poppins(color: Colors.white, fontSize: 15),
                                maxLines: 4,
                                minLines: 1,
                                decoration: InputDecoration(
                                  hintText: _isGiftMode ? 'Write a secret gift note...' : 'Message...',
                                  hintStyle: GoogleFonts.poppins(color: _isGiftMode ? const Color(0xFFFFD700).withOpacity(0.6) : Colors.white38, fontSize: 15),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildInputIcon(Icons.card_giftcard, () {
                              setState(() => _isGiftMode = !_isGiftMode);
                              HapticFeedback.lightImpact();
                            }, color: _isGiftMode ? const Color(0xFFFFD700) : Colors.white54),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: () {
                        if (_msgController.text.isNotEmpty) {
                          appState.addMessage(ChatMessage(
                            id: DateTime.now().toString(), text: _msgController.text, isUser: true, 
                            type: _isGiftMode ? 'gift' : 'text', replyingToText: _replyingTo
                          ));
                          _msgController.clear();
                          setState(() { _replyingTo = null; _isGiftMode = false; });
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isGiftMode 
                                ? [const Color(0xFFFFD700), const Color(0xFFFFA500)] 
                                : (_isTyping ? [theme.accentColor, theme.userShadowColor] : [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.05)])
                            ),
                            boxShadow: _isTyping ? [
                              BoxShadow(
                                color: _isGiftMode ? const Color(0xFFFFD700).withOpacity(0.4) : theme.userShadowColor.withOpacity(0.4), 
                                blurRadius: 12, spreadRadius: 2
                              )
                            ] : [],
                          ),
                          child: Icon(Icons.send_rounded, color: _isTyping ? Colors.white : Colors.white38, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputIcon(IconData icon, VoidCallback onTap, {Color color = Colors.white, double size = 24}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );
  }
}

class _AnimatedDots extends StatefulWidget {
  final Color color;
  const _AnimatedDots({this.color = Colors.white70});
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}
class _AnimatedDotsState extends State<_AnimatedDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat();
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
        String dots = '';
        if (_controller.value < 0.33) dots = '.';
        else if (_controller.value < 0.66) dots = '..';
        else dots = '...';
        return SizedBox(width: 16, child: Text(dots, style: GoogleFonts.poppins(color: widget.color, fontSize: 12, fontWeight: FontWeight.bold)));
      },
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;
  final String tag;
  const FullScreenImageViewer({super.key, required this.imageUrl, required this.tag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: Hero(
                tag: tag,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator(color: Colors.white54)),
                ),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _GiftMessageBubble extends StatefulWidget {
  final ChatMessage msg;
  final ChatTheme theme;
  final bool useDarkText;
  const _GiftMessageBubble({required this.msg, required this.theme, required this.useDarkText});
  @override
  State<_GiftMessageBubble> createState() => _GiftMessageBubbleState();
}
class _GiftMessageBubbleState extends State<_GiftMessageBubble> {
  void _openGift() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Gift',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(color: Colors.black.withOpacity(0.5)),
              ),
              Center(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: widget.theme.backgroundColors.first.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [BoxShadow(color: widget.theme.accentColor.withOpacity(0.4), blurRadius: 40, spreadRadius: 10)],
                          border: Border.all(color: widget.theme.accentColor.withOpacity(0.5), width: 2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.card_giftcard, color: widget.theme.accentColor, size: 60),
                            const SizedBox(height: 24),
                            Text(widget.msg.text, style: GoogleFonts.poppins(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            const SizedBox(height: 32),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Close', style: GoogleFonts.poppins(color: Colors.white54)),
                            )
                          ],
                        ),
                      ),
                    );
                  }
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _openGift,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(colors: [widget.theme.accentColor.withOpacity(0.4), widget.theme.userShadowColor.withOpacity(0.2)]),
          border: Border.all(color: widget.theme.accentColor.withOpacity(0.5), width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard, color: Colors.white),
            const SizedBox(width: 12),
            Text('Tap to open gift', style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _AudioMessageBubble extends StatefulWidget {
  final ChatMessage msg;
  final ChatTheme theme;
  const _AudioMessageBubble({required this.msg, required this.theme});
  @override
  State<_AudioMessageBubble> createState() => _AudioMessageBubbleState();
}
class _AudioMessageBubbleState extends State<_AudioMessageBubble> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    if (widget.msg.imageUrl != null) {
      _player.setSourceUrl(widget.msg.imageUrl!);
    }
    _player.onPlayerStateChanged.listen((state) {
      if (mounted) setState(() => _isPlaying = state == PlayerState.playing);
    });
    _player.onPositionChanged.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });
    _player.onDurationChanged.listen((dur) {
      if (mounted) setState(() => _duration = dur);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: widget.msg.isUser ? widget.theme.accentColor.withOpacity(0.2) : Colors.white.withOpacity(0.1),
        border: Border.all(color: widget.msg.isUser ? widget.theme.accentColor.withOpacity(0.5) : Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () {
              if (_isPlaying) _player.pause();
              else _player.resume();
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(shape: BoxShape.circle, color: widget.theme.accentColor),
              child: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: widget.theme.accentColor,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
              ),
              child: Slider(
                min: 0,
                max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                value: _position.inMilliseconds.toDouble().clamp(0.0, _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0),
                onChanged: (val) {
                  _player.seek(Duration(milliseconds: val.toInt()));
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(widget.msg.text, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SecretInkBubble extends StatefulWidget {
  final String text;
  final bool useDarkText;
  const _SecretInkBubble({required this.text, required this.useDarkText});
  @override
  State<_SecretInkBubble> createState() => _SecretInkBubbleState();
}
class _SecretInkBubbleState extends State<_SecretInkBubble> {
  bool _revealed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => setState(() => _revealed = true),
      onLongPressEnd: (_) => setState(() => _revealed = false),
      child: Stack(
        children: [
          AnimatedOpacity(
            duration: const Duration(milliseconds: 300),
            opacity: _revealed ? 1.0 : 0.0,
            child: Text(widget.text, style: GoogleFonts.poppins(color: widget.useDarkText ? Colors.black87 : Colors.white, fontSize: 15)),
          ),
          if (!_revealed)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  color: widget.useDarkText ? Colors.black12 : Colors.white24,
                  child: Center(child: Text('Hold to reveal', style: GoogleFonts.poppins(color: widget.useDarkText ? Colors.black54 : Colors.white70, fontSize: 10, fontWeight: FontWeight.bold))),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TimeCapsuleBubble extends StatelessWidget {
  final ChatTheme theme;
  const _TimeCapsuleBubble({required this.theme});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.userBubbleColors.first.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_clock, color: Colors.white70, size: 36),
          const SizedBox(height: 8),
          Text('Opens in 2 hours', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold))
        ],
      ),
    );
  }
}

class _ParticleHeartBurst extends StatefulWidget {
  const _ParticleHeartBurst();
  @override
  State<_ParticleHeartBurst> createState() => _ParticleHeartBurstState();
}
class _ParticleHeartBurstState extends State<_ParticleHeartBurst> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
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
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Floating burst
            if (_controller.value < 1.0)
              Transform.translate(
                offset: Offset(0, -50 * _controller.value),
                child: Opacity(
                  opacity: 1.0 - _controller.value,
                  child: Transform.scale(
                    scale: 1.0 + _controller.value,
                    child: const Text('ÃƒÆ’Ã†â€™Ãƒâ€šÃ‚Â°ÃƒÆ’Ã¢â‚¬Â¦Ãƒâ€šÃ‚Â¸ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â‚¬Å¾Ã‚Â¢ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ÃƒÂ¢Ã¢â€šÂ¬Ã…â€œ', style: TextStyle(fontSize: 32)),
                  ),
                ),
              ),
            // Persistent badge
            Transform.scale(
              scale: CurvedAnimation(parent: _controller, curve: Curves.elasticOut).value,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent,
                  border: Border.all(color: Colors.white, width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.5), blurRadius: 8)],
                ),
                child: const Icon(Icons.favorite, color: Colors.white, size: 12),
              ),
            ),
          ],
        );
      },
    );
  }
}



class _DynamicBackground extends StatefulWidget {
  final ChatTheme theme;
  const _DynamicBackground({required this.theme});
  @override
  State<_DynamicBackground> createState() => _DynamicBackgroundState();
}
class _DynamicBackgroundState extends State<_DynamicBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat();
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle(_rnd.nextDouble(), _rnd.nextDouble(), _rnd.nextDouble() * 0.5 + 0.2, _rnd.nextDouble() * 2 * pi, _rnd.nextDouble() * 2.0 + 1.0));
    }
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
        return Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(
              painter: _BackgroundPainter(widget.theme, _particles, _controller.value),
              child: Container(),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(color: Colors.transparent),
            ),
          ],
        );
      },
    );
  }
}

class _Particle {
  double x, y, speed, angle, size;
  _Particle(this.x, this.y, this.speed, this.angle, this.size);
}

class _BackgroundPainter extends CustomPainter {
  final ChatTheme theme;
  final List<_Particle> particles;
  final double time;

  _BackgroundPainter(this.theme, this.particles, this.time);

  @override
  void paint(Canvas canvas, Size size) {
    if (theme.id == 'sunset_aurora') {
      _paintSunsetAurora(canvas, size);
    } else if (theme.id == 'cyber_bloom') {
      _paintCyberBloom(canvas, size);
    } else {
      _paintEnchantedSakura(canvas, size);
    }
  }

  void _paintSunsetAurora(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        colors: theme.backgroundColors,
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final Paint glowPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);
    glowPaint.shader = RadialGradient(
      colors: [theme.accentColor.withOpacity(0.3), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.2, size.height * (0.8 + 0.2 * sin(time * pi))), radius: size.width));
    canvas.drawRect(Offset.zero & size, glowPaint);

    final Paint particlePaint = Paint()..color = theme.accentColor.withOpacity(0.4);
    for (var p in particles) {
      double px = (p.x * size.width + sin(time * 2 * pi + p.angle) * 30) % size.width;
      double py = (p.y * size.height - (time * p.speed * size.height)) % size.height;
      if (py < 0) py += size.height;
      canvas.drawCircle(Offset(px, py), p.size * 3.0, particlePaint);
    }
  }

  void _paintEnchantedSakura(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        colors: theme.backgroundColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final Paint glowPaint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    glowPaint.shader = RadialGradient(
      colors: [theme.accentColor.withOpacity(0.2), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.8, size.height * 0.3), radius: size.width * 0.8));
    canvas.drawRect(Offset.zero & size, glowPaint);

    final Paint particlePaint = Paint()..color = theme.accentColor.withOpacity(0.6);
    for (var p in particles) {
      double px = (p.x * size.width + (time * p.speed * 100) + sin(time * 4 * pi + p.angle) * 40) % size.width;
      double py = (p.y * size.height + (time * p.speed * size.height * 0.5)) % size.height;
      
      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(time * pi + p.angle);
      Path petal = Path();
      petal.moveTo(0, -p.size * 2);
      petal.quadraticBezierTo(p.size * 2, -p.size, p.size, p.size * 2);
      petal.quadraticBezierTo(0, p.size, -p.size, p.size * 2);
      petal.quadraticBezierTo(-p.size * 2, -p.size, 0, -p.size * 2);
      canvas.drawPath(petal, particlePaint);
      canvas.restore();
    }
  }

  void _paintCyberBloom(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()..color = theme.backgroundColors.first;
    canvas.drawRect(Offset.zero & size, bgPaint);

    double pulse = (sin(time * 2 * pi) + 1) / 2; // 0 to 1

    final Paint glowPaint1 = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    glowPaint1.shader = RadialGradient(
      colors: [theme.accentColor.withOpacity(0.4 + 0.2 * pulse), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.2, size.height * 0.2), radius: size.width * 0.8));
    canvas.drawRect(Offset.zero & size, glowPaint1);

    final Paint glowPaint2 = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);
    glowPaint2.shader = RadialGradient(
      colors: [theme.userShadowColor.withOpacity(0.4 + 0.2 * (1-pulse)), Colors.transparent],
    ).createShader(Rect.fromCircle(center: Offset(size.width * 0.8, size.height * 0.8), radius: size.width * 0.8));
    canvas.drawRect(Offset.zero & size, glowPaint2);

    final Paint particlePaint = Paint()..color = Colors.white.withOpacity(0.15);
    for (var p in particles) {
      double px = (p.x * size.width) % size.width;
      double py = (p.y * size.height - (time * p.speed * size.height)) % size.height;
      if (py < 0) py += size.height;
      canvas.drawRect(Rect.fromCenter(center: Offset(px, py), width: p.size, height: p.size * 4), particlePaint);
    }
  }

  @override
  bool shouldRepaint(_BackgroundPainter oldDelegate) => time != oldDelegate.time || theme != oldDelegate.theme;
}



