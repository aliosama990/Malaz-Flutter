import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/child_mode.dart';
import '../providers/auth_provider.dart';
import '../widgets/reference_parent_header.dart';

class RecommendationsScreen extends StatefulWidget {
  const RecommendationsScreen({
    super.key,
    required this.child,
  });

  final ChildModel child;

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  static const Color _pageBackground = Color(0xFFF3F1FA);
  static const Color _primaryPurple = Color(0xFF7B6ACE);
  static const Color _titleColor = Color(0xFF342B67);
  static const Color _bodyColor = Color(0xFF9087B5);
  static const Color _surfaceCardColor = Colors.white;
  static const Color _dividerColor = Color(0xFFF0ECF8);

  static const _RecommendationFilter _defaultFilter = _RecommendationFilter.all;

  late final List<_RecommendationItem> _recommendations;
  _RecommendationFilter _selectedFilter = _defaultFilter;
  final Set<String> _savedRecommendationIds = <String>{};

  @override
  void initState() {
    super.initState();
    _recommendations = _buildRecommendations(widget.child);
  }

  double _screenScale(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final widthScale = (screenSize.width / 393).clamp(0.88, 1.0).toDouble();
    final heightScale = (screenSize.height / 852).clamp(0.82, 1.0).toDouble();
    return widthScale < heightScale ? widthScale : heightScale;
  }

  String get _childName {
    final rawName = widget.child.name.trim();
    return rawName.isEmpty ? 'طفلك' : rawName;
  }

  bool get _isFemale => widget.child.gender == 1;

  String get _childWasVerb => _isFemale ? 'كانت' : 'كان';

  String get _hydrationNeedVerb => _isFemale ? 'محتاجة' : 'محتاج';

  List<_RecommendationItem> get _visibleRecommendations {
    if (_selectedFilter == _RecommendationFilter.all) {
      return _recommendations;
    }

    return _recommendations
        .where((item) => item.filter == _selectedFilter)
        .toList(growable: false);
  }

  void _toggleSaved(String id) {
    setState(() {
      if (_savedRecommendationIds.contains(id)) {
        _savedRecommendationIds.remove(id);
      } else {
        _savedRecommendationIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _pageBackground,
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    scaled(16),
                    scaled(16),
                    scaled(16),
                    scaled(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInsightCard(),
                      SizedBox(height: scaled(18)),
                      _buildFilterChips(),
                      SizedBox(height: scaled(14)),
                      ..._visibleRecommendations.map(
                        (item) => Padding(
                          padding: EdgeInsets.only(bottom: scaled(16)),
                          child: _buildRecommendationCard(item),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final authProvider = context.watch<AuthProvider>();
    final rawUserName = authProvider.user?.name.trim();
    final userName =
        rawUserName == null || rawUserName.isEmpty ? 'ولي الأمر' : rawUserName;

    return ReferenceParentHeader(
      userName: userName,
      subtitle: 'نصائح مخصصة بناءً على بيانات $_childName اليوم',
      parentGender: authProvider.user?.parentGender,
      showBackButton: true,
    );
  }

  Widget _buildInsightCard() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return SizedBox(
      height: scaled(104),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          scaled(15),
          scaled(15),
          scaled(15),
          scaled(15),
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF9F4FF),
              Color(0xFFFFF0E8),
            ],
          ),
          borderRadius: BorderRadius.circular(scaled(22)),
          border: Border.all(
            color: const Color(0xFFDCD4F5),
            width: scaled(1.0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0x110E092A),
              blurRadius: scaled(15),
              offset: Offset(0, scaled(7)),
            ),
          ],
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: scaled(52),
              height: scaled(52),
              decoration: BoxDecoration(
                color: _primaryPurple,
                borderRadius: BorderRadius.circular(scaled(15)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x24191851),
                    blurRadius: scaled(13),
                    offset: Offset(0, scaled(7)),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '🤖',
                style: TextStyle(fontSize: scaled(26)),
              ),
            ),
            SizedBox(width: scaled(12)),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ملاز AI - تحليل اليوم',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.cairo(
                      fontSize: scaled(14),
                      fontWeight: FontWeight.w800,
                      color: _primaryPurple,
                    ),
                  ),
                  SizedBox(height: scaled(8)),
                  Text(
                    _buildInsightSummary(widget.child),
                    textAlign: TextAlign.right,
                    maxLines: 3,
                    style: GoogleFonts.cairo(
                      fontSize: scaled(13.5),
                      fontWeight: FontWeight.w700,
                      color: _titleColor,
                      height: 1.56,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;
    const chips = <_RecommendationFilter>[
      _RecommendationFilter.all,
      _RecommendationFilter.health,
      _RecommendationFilter.safety,
      _RecommendationFilter.behavior,
    ];

    return Wrap(
      textDirection: TextDirection.rtl,
      alignment: WrapAlignment.start,
      spacing: scaled(7),
      runSpacing: scaled(10),
      children: chips
          .map(
            (filter) => _buildFilterChip(
              filter: filter,
              selected: _selectedFilter == filter,
            ),
          )
          .toList(growable: false),
    );
  }

  Widget _buildFilterChip({
    required _RecommendationFilter filter,
    required bool selected,
  }) {
    final scheme = _filterColorScheme(filter, selected);
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(scaled(20)),
        onTap: () => setState(() => _selectedFilter = filter),
        child: SizedBox(
          height: scaled(40),
          child: Ink(
            padding: EdgeInsets.symmetric(horizontal: scaled(14)),
            decoration: BoxDecoration(
              color: scheme.background,
              borderRadius: BorderRadius.circular(scaled(20)),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: const Color(0x261E164C),
                        blurRadius: scaled(13),
                        offset: Offset(0, scaled(7)),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: const Color(0x0F1E164C),
                        blurRadius: scaled(10),
                        offset: Offset(0, scaled(5)),
                      ),
                    ],
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  filter.label,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  style: GoogleFonts.cairo(
                    fontSize: scaled(13.5),
                    fontWeight: FontWeight.w800,
                    color: scheme.foreground,
                  ),
                ),
                SizedBox(width: scaled(6)),
                Text(
                  filter.symbol,
                  style: TextStyle(
                    fontSize: scaled(
                      filter == _RecommendationFilter.all ? 16 : 14,
                    ),
                    color: scheme.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(_RecommendationItem item) {
    final isSaved = _savedRecommendationIds.contains(item.id);
    final scale = _screenScale(context);
    double scaled(double value) => value * scale;

    return Container(
      padding: EdgeInsets.fromLTRB(
        scaled(16),
        scaled(14),
        scaled(16),
        scaled(16),
      ),
      decoration: BoxDecoration(
        color: _surfaceCardColor,
        borderRadius: BorderRadius.circular(scaled(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x120F0A2A),
            blurRadius: scaled(20),
            offset: Offset(0, scaled(10)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: scaled(12),
                vertical: scaled(7),
              ),
              decoration: BoxDecoration(
                color: item.badgeBackground,
                borderRadius: BorderRadius.circular(scaled(15)),
              ),
              child: Text(
                '${item.badgeSymbol} ${item.badgeLabel}',
                textAlign: TextAlign.right,
                style: GoogleFonts.cairo(
                  fontSize: scaled(12.5),
                  fontWeight: FontWeight.w800,
                  color: item.badgeForeground,
                ),
              ),
            ),
          ),
          SizedBox(height: scaled(14)),
          Text(
            item.title,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: scaled(18),
              fontWeight: FontWeight.w800,
              color: _titleColor,
              height: 1.35,
            ),
          ),
          SizedBox(height: scaled(10)),
          Text(
            item.body,
            textAlign: TextAlign.right,
            style: GoogleFonts.cairo(
              fontSize: scaled(13.5),
              fontWeight: FontWeight.w600,
              color: _bodyColor,
              height: 1.82,
            ),
          ),
          SizedBox(height: scaled(16)),
          Divider(
            color: _dividerColor,
            thickness: scaled(1.0),
            height: 1,
          ),
          SizedBox(height: scaled(14)),
          Row(
            textDirection: TextDirection.rtl,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Wrap(
                  textDirection: TextDirection.rtl,
                  alignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: scaled(15),
                      color: const Color(0xFFC3BDD8),
                    ),
                    Text(
                      '${item.timeLabel}  •  ${item.author}',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.cairo(
                        fontSize: scaled(11.8),
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFB8B0D2),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: scaled(12)),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(scaled(18)),
                  onTap: () => _toggleSaved(item.id),
                  child: Ink(
                    padding: EdgeInsets.symmetric(
                      horizontal: scaled(16),
                      vertical: scaled(8),
                    ),
                    decoration: BoxDecoration(
                      color: isSaved ? _primaryPurple : const Color(0xFFEDE7FB),
                      borderRadius: BorderRadius.circular(scaled(18)),
                    ),
                    child: Row(
                      textDirection: TextDirection.rtl,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isSaved ? 'تم الحفظ' : 'حفظ',
                          textAlign: TextAlign.right,
                          style: GoogleFonts.cairo(
                            fontSize: scaled(12.5),
                            fontWeight: FontWeight.w800,
                            color: isSaved
                                ? Colors.white
                                : const Color(0xFF8B7BD0),
                          ),
                        ),
                        SizedBox(width: scaled(5)),
                        Text(
                          isSaved ? '✓' : '📝',
                          style: TextStyle(
                            fontSize: scaled(isSaved ? 12 : 13),
                            color: isSaved
                                ? Colors.white
                                : const Color(0xFF8B7BD0),
                          ),
                        ),
                      ],
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

  String _buildInsightSummary(ChildModel child) {
    final linkedDevice = child.deviceId.trim().isNotEmpty;

    if (linkedDevice) {
      return 'لاحظت أن $_childName $_childWasVerb نشيط${_isFemale ? 'ة' : ''} جدًا اليوم (نبض قلب مرتفع)، فيه توصيات مهمة ليكي 👇';
    }

    switch (child.condition) {
      case ChildCondition.adhd:
        return 'لاحظت أن $_childName $_childWasVerb نشيط${_isFemale ? 'ة' : ''} جدًا اليوم، فيه توصيات مهمة ليكي 👇';
      case ChildCondition.autism:
        return 'رتبت توصيات اليوم بناءً على روتين $_childName الحالي، عشان تكون الأنشطة أهدى وأسهل عليكي 👇';
      case ChildCondition.normal:
      case null:
        return 'بناءً على بيانات $_childName اليوم، فيه توصيات صحية وتربوية وأمنية مهمة ليكي 👇';
    }
  }

  List<_RecommendationItem> _buildRecommendations(ChildModel child) {
    final age = child.age < 1 ? 1 : child.age;
    final deviceId = child.deviceId.trim();
    final hydrationRange = age <= 4
        ? '5-6'
        : age <= 8
            ? '6-8'
            : '8-10';

    final behaviorRecommendation = switch (child.condition) {
      ChildCondition.adhd => _RecommendationItem(
          id: 'behavior',
          filter: _RecommendationFilter.behavior,
          badgeLabel: 'نصيحة تربوية',
          badgeSymbol: '🟠',
          badgeBackground: const Color(0xFFFFF0E6),
          badgeForeground: const Color(0xFFFF9642),
          title: 'كيف تتعاملي مع فرط الحركة بشكل إيجابي؟',
          body:
              'بناءً على ملف $_childName، إليك 3 نصائح عملية: ① خصصي وقتًا للحركة الحرة قبل المذاكرة. ② استخدمي ألعاب التركيز. ③ المكافآت الفورية أفضل من التأجيل. 🌟',
          author: 'خبير تربوي AI',
          timeLabel: 'اليوم',
        ),
      ChildCondition.autism => _RecommendationItem(
          id: 'behavior',
          filter: _RecommendationFilter.behavior,
          badgeLabel: 'نصيحة تربوية',
          badgeSymbol: '🟠',
          badgeBackground: const Color(0xFFFFF0E6),
          badgeForeground: const Color(0xFFFF9642),
          title: 'كيف تدعمي الروتين اليومي بهدوء أكبر؟',
          body:
              'بناءً على ملف $_childName، ثبتي الخطوات اليومية بوضوح: ① اخبريه مسبقًا بما سيحدث. ② استخدمي إشارات بصرية بسيطة. ③ حافظي على ترتيب متكرر للأنشطة الأساسية. 🌟',
          author: 'خبير تربوي AI',
          timeLabel: 'اليوم',
        ),
      ChildCondition.normal || null => _RecommendationItem(
          id: 'behavior',
          filter: _RecommendationFilter.behavior,
          badgeLabel: 'نصيحة تربوية',
          badgeSymbol: '🟠',
          badgeBackground: const Color(0xFFFFF0E6),
          badgeForeground: const Color(0xFFFF9642),
          title: 'كيف تدعمي تركيز $_childName خلال اليوم؟',
          body:
              'بحسب عمر $_childName ($age سنوات)، من الأفضل: ① نشاط قصير في البداية. ② مهمة واحدة واضحة كل مرة. ③ مكافأة صغيرة بعد الإنجاز لتعزيز الاستمرار. 🌟',
          author: 'خبير تربوي AI',
          timeLabel: 'اليوم',
        ),
    };

    final healthRecommendation = _RecommendationItem(
      id: 'health',
      filter: _RecommendationFilter.health,
      badgeLabel: 'توصية صحية',
      badgeSymbol: '💚',
      badgeBackground: const Color(0xFFDDF8F0),
      badgeForeground: const Color(0xFF39C499),
      title: '$_childName $_hydrationNeedVerb تشرب مية أكثر اليوم!',
      body:
          'لاحظنا أن نشاط $_childName كان مرتفعًا لفترة طويلة اليوم، وده يدل على مجهود بدني أعلى. تأكدي ${_isFemale ? 'إنها' : 'إنه'} شرب على الأقل $hydrationRange أكواب مية خلال اليوم لتعويض السوائل. 🥤',
      author: 'د. نور AI',
      timeLabel: 'منذ ساعتين',
    );

    final safetyRecommendation = _RecommendationItem(
      id: 'safety',
      filter: _RecommendationFilter.safety,
      badgeLabel: 'تنبيه أمان',
      badgeSymbol: '🔵',
      badgeBackground: const Color(0xFFEAF2FF),
      badgeForeground: const Color(0xFF4382E6),
      title: deviceId.isEmpty
          ? 'اربطي جهاز $_childName لرفع مستوى الأمان'
          : 'راجعي أمان جهاز $_childName اليوم',
      body: deviceId.isEmpty
          ? 'ملف $_childName لا يحتوي حاليًا على جهاز مرتبط. ربط الجهاز يسهّل متابعة الموقع واستقبال التنبيهات المهمة بسرعة عند الحاجة. 🔵'
          : 'الجهاز المرتبط بـ $_childName (${_compactDeviceId(deviceId)}) يحتاج مراجعة سريعة اليوم: تأكدي من الشحن، وراجعي المناطق الآمنة، وحدّثي التنبيهات ليظل التتبع جاهزًا طوال اليوم. 🔵',
      author: 'مساعد الأمان AI',
      timeLabel: 'قبل قليل',
    );

    return <_RecommendationItem>[
      behaviorRecommendation,
      healthRecommendation,
      safetyRecommendation,
    ];
  }

  String _compactDeviceId(String deviceId) {
    if (deviceId.length <= 8) {
      return deviceId;
    }

    return '${deviceId.substring(0, 4)}...${deviceId.substring(deviceId.length - 4)}';
  }

  _FilterChipColors _filterColorScheme(
    _RecommendationFilter filter,
    bool selected,
  ) {
    if (selected) {
      return const _FilterChipColors(
        background: _primaryPurple,
        foreground: Colors.white,
      );
    }

    return switch (filter) {
      _RecommendationFilter.all => const _FilterChipColors(
          background: Colors.white,
          foreground: _primaryPurple,
        ),
      _RecommendationFilter.health => const _FilterChipColors(
          background: Colors.white,
          foreground: Color(0xFF39C499),
        ),
      _RecommendationFilter.safety => const _FilterChipColors(
          background: Colors.white,
          foreground: Color(0xFF4382E6),
        ),
      _RecommendationFilter.behavior => const _FilterChipColors(
          background: Colors.white,
          foreground: Color(0xFFFF9642),
        ),
    };
  }
}

enum _RecommendationFilter {
  all('الكل', '✨'),
  health('صحة', '💚'),
  safety('أمان', '🔵'),
  behavior('سلوك', '🟠');

  const _RecommendationFilter(this.label, this.symbol);

  final String label;
  final String symbol;
}

class _RecommendationItem {
  const _RecommendationItem({
    required this.id,
    required this.filter,
    required this.badgeLabel,
    required this.badgeSymbol,
    required this.badgeBackground,
    required this.badgeForeground,
    required this.title,
    required this.body,
    required this.author,
    required this.timeLabel,
  });

  final String id;
  final _RecommendationFilter filter;
  final String badgeLabel;
  final String badgeSymbol;
  final Color badgeBackground;
  final Color badgeForeground;
  final String title;
  final String body;
  final String author;
  final String timeLabel;
}

class _FilterChipColors {
  const _FilterChipColors({
    required this.background,
    required this.foreground,
  });

  final Color background;
  final Color foreground;
}
