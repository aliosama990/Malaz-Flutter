import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import '../models/emergency_audio_alert_model.dart';

class EmergencyAlertDetailsScreen extends StatefulWidget {
  const EmergencyAlertDetailsScreen({
    super.key,
    required this.alert,
  });

  final EmergencyAudioAlert alert;

  @override
  State<EmergencyAlertDetailsScreen> createState() =>
      _EmergencyAlertDetailsScreenState();
}

class _EmergencyAlertDetailsScreenState
    extends State<EmergencyAlertDetailsScreen> {
  static const Color _pageBackground = Color(0xFFF4F1FB);
  static const Color _headingColor = Color(0xFF2C2B4B);
  static const Color _mutedText = Color(0xFF8C89A8);
  static const Color _dividerColor = Color(0xFFE9E5FA);
  static const Color _dangerRed = Color(0xFFFF4F5E);
  static const Color _dangerRedDark = Color(0xFFE8394B);
  static const Color _purple = Color(0xFF8173C6);
  static const Color _cardShadow = Color(0x18766AAE);

  late final AudioPlayer _audioPlayer;
  String? _loadedAudioUrl;
  Duration _audioPosition = Duration.zero;
  Duration? _audioDuration;
  bool _isAudioPlaying = false;
  bool _isAudioCommandInProgress = false;
  bool _isAudioCompleted = false;

  EmergencyAudioAlert get alert => widget.alert;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.playerStateStream.listen((playerState) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isAudioPlaying =
            playerState.playing && playerState.processingState !=
                ProcessingState.completed;
        _isAudioCompleted =
            playerState.processingState == ProcessingState.completed;
      });
    });
    _audioPlayer.positionStream.listen((position) {
      if (!mounted) {
        return;
      }

      setState(() {
        _audioPosition = position;
      });
    });
    _audioPlayer.durationStream.listen((duration) {
      if (!mounted) {
        return;
      }

      setState(() {
        _audioDuration = duration;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Scaffold(
      backgroundColor: _pageBackground,
      body: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Container(
              color: Colors.white,
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    scaled(16),
                    scaled(16),
                    scaled(16),
                    scaled(28),
                  ),
                  child: _buildTopBar(context),
                ),
              ),
            ),
            Container(height: scaled(1), color: _dividerColor),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  scaled(16),
                  scaled(18),
                  scaled(16),
                  scaled(22),
                ),
                child: Column(
                  children: [
                    _buildEmergencyCard(context),
                    SizedBox(height: scaled(18)),
                    Row(
                      textDirection: TextDirection.ltr,
                      children: [
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.access_time_rounded,
                            title: _formatTime(alert.timestamp),
                            subtitle: 'الوقت',
                          ),
                        ),
                        SizedBox(width: scaled(10)),
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.location_on_outlined,
                            title: _shortLocationName,
                            subtitle: 'الموقع',
                          ),
                        ),
                        SizedBox(width: scaled(10)),
                        Expanded(
                          child: _buildInfoTile(
                            icon: Icons.child_care_rounded,
                            title: _displayChildName,
                            subtitle: 'الطفلة',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: scaled(18)),
                    _buildAudioCard(context),
                    SizedBox(height: scaled(32)),
                    _buildOpenLocationButton(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
  }

  String get _displayChildName {
    return alert.childName.trim().isEmpty ? 'الطفل' : alert.childName.trim();
  }

  String get _shortLocationName {
    final locationName = alert.locationName.trim();
    if (locationName.isEmpty) {
      return 'غير محدد';
    }

    return locationName;
  }

  Widget _buildTopBar(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return SizedBox(
      height: scaled(78),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _buildIconButton(
              icon: Icons.arrow_forward_rounded,
              onTap: () => Navigator.maybePop(context),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'تفاصيل التنبيه',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: scaled(25),
                  fontWeight: FontWeight.w900,
                  color: _headingColor,
                  height: 1.1,
                ),
              ),
              SizedBox(height: scaled(8)),
              Text(
                'نداء الطوارئ - $_displayChildName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: scaled(13),
                  fontWeight: FontWeight.w600,
                  color: _mutedText,
                  height: 1.1,
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: scaled(52),
              height: scaled(52),
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: _purple,
                shape: BoxShape.circle,
              ),
              child: Text(
                _displayChildName.characters.first,
                style: GoogleFonts.cairo(
                  fontSize: scaled(18),
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Builder(
      builder: (context) {
        final scale = _screenScale(context);
        double scaled(double value) => value * scale;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(scaled(10)),
            child: Ink(
              width: scaled(34),
              height: scaled(34),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(scaled(9)),
                border: Border.all(color: const Color(0xFFE8E6F2)),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF6F6B86),
                size: scaled(16),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmergencyCard(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Container(
      width: double.infinity,
      height: scaled(116),
      padding: EdgeInsets.fromLTRB(
        scaled(20),
        scaled(16),
        scaled(18),
        scaled(16),
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(scaled(18)),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [_dangerRed, _dangerRedDark],
        ),
        boxShadow: [
          BoxShadow(
            color: _dangerRed.withValues(alpha: 0.22),
            blurRadius: scaled(18),
            offset: Offset(0, scaled(9)),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: scaled(12),
            bottom: scaled(12),
            child: Container(
              width: scaled(52),
              height: scaled(52),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(scaled(12)),
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                size: scaled(32),
                color: Colors.white.withValues(alpha: 0.16),
              ),
            ),
          ),
          Positioned(
            left: scaled(0),
            top: scaled(18),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: scaled(8),
                vertical: scaled(3),
              ),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'SOS',
                style: GoogleFonts.cairo(
                  fontSize: scaled(12),
                  height: 1,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Positioned.fill(
            left: scaled(76),
            right: 0,
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'نداء طوارئ!',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: scaled(21.5),
                      height: 1.08,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: scaled(7)),
                  Text(
                    '$_displayChildName تحتاج مساعدة الآن',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: scaled(13),
                      height: 1.18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  SizedBox(height: scaled(12)),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(
                          Icons.calendar_month_rounded,
                          color: Colors.white.withValues(alpha: 0.84),
                          size: scaled(14),
                        ),
                        SizedBox(width: scaled(5)),
                        Flexible(
                          child: Text(
                            _formatDateTime(alert.timestamp),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: GoogleFonts.cairo(
                              fontSize: scaled(11.5),
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: Colors.white.withValues(alpha: 0.84),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Builder(
      builder: (context) {
        final scale = _screenScale(context);
        double scaled(double value) => value * scale;

        return Container(
          height: scaled(104),
          padding: EdgeInsets.symmetric(
            horizontal: scaled(8),
            vertical: scaled(10),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(scaled(9)),
            boxShadow: [
              BoxShadow(
                color: _cardShadow,
                blurRadius: scaled(14),
                offset: Offset(0, scaled(7)),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: _headingColor,
                size: scaled(22),
              ),
              SizedBox(height: scaled(7)),
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.rtl,
                    style: GoogleFonts.cairo(
                      fontSize: scaled(12.3),
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      color: _headingColor,
                    ),
                  ),
                ),
              ),
              SizedBox(height: scaled(5)),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: GoogleFonts.cairo(
                  fontSize: scaled(9.7),
                  height: 1,
                  fontWeight: FontWeight.w600,
                  color: _mutedText,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAudioCard(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return _buildWhiteCard(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: TextDirection.rtl,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.mic_rounded,
                color: _headingColor,
                size: scaled(14),
              ),
              SizedBox(width: scaled(5)),
              Expanded(
                child: Text(
                  'رسالة صوتية من الجهاز',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: GoogleFonts.cairo(
                    fontSize: scaled(13),
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                    color: _mutedText,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: scaled(9)),
          Row(
            textDirection: TextDirection.ltr,
            children: [
              Text(
                _audioTimeLabel,
                style: GoogleFonts.cairo(
                  fontSize: scaled(8.5),
                  fontWeight: FontWeight.w800,
                  color: _mutedText,
                ),
              ),
              SizedBox(width: scaled(9)),
              Expanded(child: _buildWaveform(context)),
              SizedBox(width: scaled(9)),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: _isAudioCommandInProgress
                      ? null
                      : _toggleAudioPlayback,
                  customBorder: const CircleBorder(),
                  child: Ink(
                    width: scaled(35),
                    height: scaled(35),
                    decoration: const BoxDecoration(
                      color: _purple,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _isAudioPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: scaled(23),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _toggleAudioPlayback() async {
    if (_isAudioCommandInProgress) {
      return;
    }

    final audioUrl = alert.resolvedAudioUrl.trim();
    if (audioUrl.isEmpty) {
      _showSnackBar('لا يوجد تسجيل صوتي متاح');
      return;
    }

    if (_audioPlayer.playing) {
      setState(() {
        _isAudioCommandInProgress = true;
      });

      try {
        await _audioPlayer.pause();
      } catch (_) {
        _showSnackBar('تعذر تشغيل التسجيل الصوتي');
      } finally {
        if (mounted) {
          setState(() {
            _isAudioCommandInProgress = false;
          });
        }
      }
      return;
    }

    setState(() {
      _isAudioCommandInProgress = true;
    });

    try {
      if (_loadedAudioUrl != audioUrl) {
        await _audioPlayer.setUrl(audioUrl);
        _loadedAudioUrl = audioUrl;
        _isAudioCompleted = false;
      }

      if (_isAudioCompleted ||
          _audioPlayer.processingState == ProcessingState.completed) {
        await _audioPlayer.seek(Duration.zero);
        _isAudioCompleted = false;
      }

      unawaited(
        _audioPlayer.play().catchError((_) {
          if (mounted) {
            _showSnackBar('تعذر تشغيل التسجيل الصوتي');
          }
        }),
      );
    } catch (_) {
      _showSnackBar('تعذر تشغيل التسجيل الصوتي');
    } finally {
      if (mounted) {
        setState(() {
          _isAudioCommandInProgress = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String get _audioTimeLabel {
    final duration = _audioDuration;
    if (duration == null) {
      return '${_formatAudioDuration(_audioPosition)} / --:--';
    }

    final safePosition =
        _audioPosition > duration ? duration : _audioPosition;
    return '${_formatAudioDuration(safePosition)} / '
        '${_formatAudioDuration(duration)}';
  }

  String _formatAudioDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildWaveform(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    final waveformProgress = _waveformProgress;
    const heights = <double>[
      12,
      18,
      14,
      23,
      17,
      15,
      25,
      13,
      20,
      16,
      22,
      14,
      19,
      16,
      24,
      12,
      18,
      15,
      21,
      13,
    ];

    return SizedBox(
      height: scaled(32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: heights.indexed.map(
          (entry) {
            final barIndex = entry.$1;
            final height = entry.$2;
            final barProgress = (barIndex + 1) / heights.length;
            final isActive = waveformProgress >= barProgress;

            return Container(
              width: scaled(4.6),
              height: scaled(height),
              decoration: BoxDecoration(
                color: isActive ? _purple : const Color(0xFFDAD2F7),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          },
        ).toList(growable: false),
      ),
    );
  }

  double get _waveformProgress {
    final duration = _audioDuration;
    if (duration == null || duration.inMilliseconds <= 0) {
      return 0;
    }

    return (_audioPosition.inMilliseconds / duration.inMilliseconds)
        .clamp(0.0, 1.0)
        .toDouble();
  }

  Widget _buildWhiteCard(
    BuildContext context, {
    required Widget child,
  }) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        scaled(13),
        scaled(12),
        scaled(13),
        scaled(12),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(scaled(11)),
        boxShadow: [
          BoxShadow(
            color: _cardShadow,
            blurRadius: scaled(14),
            offset: Offset(0, scaled(7)),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildOpenLocationButton(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return SizedBox(
      width: scaled(154),
      height: scaled(46),
      child: ElevatedButton(
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فتح الموقع غير متاح حالياً')),
          );
        },
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: const Color(0xFF8576C9),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(scaled(10)),
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'فتح الموقع',
              style: GoogleFonts.cairo(
                fontSize: scaled(13),
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(width: scaled(7)),
            SizedBox(
              width: scaled(16),
              height: scaled(16),
              child: Center(
                child: Icon(
                  Icons.location_on_rounded,
                  color: const Color(0xFFFF4F5E),
                  size: scaled(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime? value) {
    if (value == null) {
      return 'الوقت غير متاح';
    }

    final localValue = value.toLocal();
    const weekdays = <int, String>{
      DateTime.monday: 'الإثنين',
      DateTime.tuesday: 'الثلاثاء',
      DateTime.wednesday: 'الأربعاء',
      DateTime.thursday: 'الخميس',
      DateTime.friday: 'الجمعة',
      DateTime.saturday: 'السبت',
      DateTime.sunday: 'الأحد',
    };
    const months = <int, String>{
      1: 'يناير',
      2: 'فبراير',
      3: 'مارس',
      4: 'أبريل',
      5: 'مايو',
      6: 'يونيو',
      7: 'يوليو',
      8: 'أغسطس',
      9: 'سبتمبر',
      10: 'أكتوبر',
      11: 'نوفمبر',
      12: 'ديسمبر',
    };

    final hour = localValue.hour % 12 == 0 ? 12 : localValue.hour % 12;
    final minute = localValue.minute.toString().padLeft(2, '0');
    final period = localValue.hour < 12 ? 'ص' : 'م';
    final weekday = weekdays[localValue.weekday] ?? '';
    final month = months[localValue.month] ?? '';

    return '$weekday، ${localValue.day} $month ${localValue.year} — $hour:$minute $period';
  }

  String _formatTime(DateTime? value) {
    if (value == null) {
      return '--:--';
    }

    final localValue = value.toLocal();
    final hour = localValue.hour % 12 == 0 ? 12 : localValue.hour % 12;
    final minute = localValue.minute.toString().padLeft(2, '0');
    final period = localValue.hour < 12 ? 'ص' : 'م';

    return '$hour:$minute $period';
  }
}
