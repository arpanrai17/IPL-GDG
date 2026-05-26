import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ──────────────────────────────────────────────────────────────────
// Design System — Colors & Text
// ──────────────────────────────────────────────────────────────────
class AppColors {
  static const navy       = Color(0xFF060B18);
  static const navyLight  = Color(0xFF0D1526);
  static const navyCard   = Color(0xFF111B2E);
  static const blue       = Color(0xFF00D4FF);
  static const gold       = Color(0xFFFFD700);
  static const purple     = Color(0xFF8B5CF6);
  static const green      = Color(0xFF00FF88);
  static const coral      = Color(0xFFFF4060);
  static const border     = Color(0xFF1E2D45);
  static const textMuted  = Color(0xFF6B7E99);
  static const white      = Colors.white;
}

// ──────────────────────────────────────────────────────────────────
// Glassmorphism Card
// ──────────────────────────────────────────────────────────────────
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Color? borderColor;
  final Color? glowColor;
  final double? width;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = 20,
    this.borderColor,
    this.glowColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.navyCard.withOpacity(0.85),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? AppColors.border, width: 1),
        boxShadow: glowColor != null
            ? [BoxShadow(color: glowColor!.withOpacity(0.12), blurRadius: 24, spreadRadius: 0)]
            : [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16)],
      ),
      child: child,
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Gradient Text
// ──────────────────────────────────────────────────────────────────
class GradText extends StatelessWidget {
  final String text;
  final List<Color> colors;
  final double fontSize;
  final FontWeight fontWeight;
  final TextAlign? textAlign;

  const GradText(
    this.text, {
    super.key,
    this.colors = const [AppColors.blue, AppColors.purple],
    this.fontSize = 18,
    this.fontWeight = FontWeight.w800,
    this.textAlign,
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(colors: colors).createShader(bounds),
      child: Text(
        text,
        textAlign: textAlign,
        style: GoogleFonts.outfit(
          fontSize: fontSize,
          fontWeight: fontWeight,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Neon Badge
// ──────────────────────────────────────────────────────────────────
class NeonBadge extends StatelessWidget {
  final String label;
  final Color color;

  const NeonBadge(this.label, {super.key, this.color = AppColors.blue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(50),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Pulsing Dot
// ──────────────────────────────────────────────────────────────────
class PulsingDot extends StatefulWidget {
  final Color color;
  const PulsingDot({super.key, this.color = AppColors.blue});
  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
  late final Animation<double> _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_ctrl);

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color)),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Thinking Dots
// ──────────────────────────────────────────────────────────────────
class ThinkingDots extends StatefulWidget {
  const ThinkingDots({super.key});
  @override
  State<ThinkingDots> createState() => _ThinkingDotsState();
}

class _ThinkingDotsState extends State<ThinkingDots> with TickerProviderStateMixin {
  late final List<AnimationController> _ctrls = List.generate(3, (i) =>
    AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..repeat(reverse: true, period: Duration(milliseconds: 600 + i * 200)));
  late final List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _anims = _ctrls.map((c) => Tween<double>(begin: 0.0, end: -8.0).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut))).toList();
    for (var i = 0; i < _ctrls.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () { if (mounted) _ctrls[i].repeat(reverse: true); });
    }
  }

  @override
  void dispose() { for (final c in _ctrls) c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => AnimatedBuilder(
        animation: _anims[i],
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _anims[i].value),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: 7, height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.blue.withOpacity(0.8)),
          ),
        ),
      )),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// AppButton
// ──────────────────────────────────────────────────────────────────
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  final double? width;
  final EdgeInsetsGeometry? padding;
  final bool outlined;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.color = AppColors.blue,
    this.textColor = AppColors.navy,
    this.width,
    this.padding,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: width,
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        decoration: BoxDecoration(
          gradient: outlined ? null : LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          color: outlined ? Colors.transparent : null,
          borderRadius: BorderRadius.circular(14),
          border: outlined ? Border.all(color: color.withOpacity(0.5)) : null,
          boxShadow: outlined ? null : [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            color: outlined ? color : textColor,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────
// Chat Bubble
// ──────────────────────────────────────────────────────────────────
class ChatBubble extends StatelessWidget {
  final String text;
  final String sender;
  final String avatar;
  final bool isUser;
  final Color? accentColor;

  const ChatBubble({
    super.key,
    required this.text,
    required this.sender,
    required this.avatar,
    this.isUser = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.blue;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Center(child: Text(avatar, style: const TextStyle(fontSize: 16))),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(sender, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isUser
                        ? AppColors.gold.withOpacity(0.08)
                        : color.withOpacity(0.06),
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(18),
                      topRight:    const Radius.circular(18),
                      bottomLeft:  Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: Border.all(
                      color: isUser ? AppColors.gold.withOpacity(0.2) : color.withOpacity(0.15),
                    ),
                  ),
                  child: Text(
                    text,
                    style: GoogleFonts.inter(fontSize: 13.5, height: 1.55, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 10),
        ],
      ),
    );
  }
}
