import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:webview_flutter/webview_flutter.dart';

const _supabaseUrl = 'https://cgnpscogzqvrvaopwhhm.supabase.co';
const _anonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNnbnBzY29nenF2cnZhb3B3aGhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgwNDMzMjQsImV4cCI6MjA5MzYxOTMyNH0.sGHksNYA1A_4Dn9anzNK7NKKqp6SzeQEMk91R0lOkCs';
final _siteUri = Uri.parse('https://merolaganiacademy.com/');

const _brandTeal = Color(0xFF3F9EA4);
const _brandTealDark = Color(0xFF256D73);
const _brandGold = Color(0xFFF4C94D);
const _brandInk = Color(0xFF142333);
const _mutedInk = Color(0xFF667085);
const _surface = Color(0xFFF6FBFA);
const _line = Color(0xFFE4ECEB);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: _surface,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const MerolaganiAcademyApp());
}

class MerolaganiAcademyApp extends StatefulWidget {
  const MerolaganiAcademyApp({super.key});

  @override
  State<MerolaganiAcademyApp> createState() => _MerolaganiAcademyAppState();
}

class _MerolaganiAcademyAppState extends State<MerolaganiAcademyApp> {
  late final AcademyApi _api;
  late final AuthController _auth;

  @override
  void initState() {
    super.initState();
    _api = AcademyApi(http.Client());
    _auth = AuthController(_api)..restore();
  }

  @override
  void dispose() {
    _api.close();
    _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Merolagani Academy',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _brandTeal,
          primary: _brandTeal,
          secondary: _brandGold,
          surface: _surface,
        ),
        scaffoldBackgroundColor: _surface,
        textTheme: ThemeData.light().textTheme.apply(
          bodyColor: _brandInk,
          displayColor: _brandInk,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _surface,
          foregroundColor: _brandInk,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: _brandTealDark,
          unselectedItemColor: _mutedInk,
          type: BottomNavigationBarType.fixed,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _brandTeal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        useMaterial3: true,
      ),
      home: AcademyShell(api: _api, auth: _auth),
    );
  }
}

class AcademyShell extends StatefulWidget {
  const AcademyShell({required this.api, required this.auth, super.key});

  final AcademyApi api;
  final AuthController auth;

  @override
  State<AcademyShell> createState() => _AcademyShellState();
}

class _AcademyShellState extends State<AcademyShell> {
  var _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      HomeTab(
        api: widget.api,
        auth: widget.auth,
        onOpenCourses: () => _setTab(1),
        onOpenAccount: _openAccount,
      ),
      CoursesTab(
        api: widget.api,
        auth: widget.auth,
        onOpenAccount: _openAccount,
      ),
      LearnTab(api: widget.api, auth: widget.auth, onOpenAccount: _openAccount),
      VerifyTab(api: widget.api),
      AccountTab(auth: widget.auth),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const _HeaderLogo(),
        actions: [
          IconButton(
            tooltip: 'Open website',
            onPressed: () => _openExternal(_siteUri),
            icon: const Icon(Icons.open_in_browser_rounded),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: _setTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_fill_rounded),
            label: 'Learn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.verified_rounded),
            label: 'Verify',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }

  void _setTab(int value) => setState(() => _index = value);

  void _openAccount() {
    Navigator.of(context).popUntil((route) => route.isFirst);
    _setTab(4);
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({
    required this.api,
    required this.auth,
    required this.onOpenCourses,
    required this.onOpenAccount,
    super.key,
  });

  final AcademyApi api;
  final AuthController auth;
  final VoidCallback onOpenCourses;
  final VoidCallback onOpenAccount;

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  late Future<HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchHomeData();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        final next = widget.api.fetchHomeData();
        setState(() => _future = next);
        await next;
      },
      child: FutureBuilder<HomeData>(
        future: _future,
        builder: (context, snapshot) {
          final data = snapshot.data ?? HomeData.empty();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            children: [
              _HeroPanel(
                courseCount: data.courses.length,
                onBrowse: widget.onOpenCourses,
              ),
              const SizedBox(height: 18),
              const _FeatureGrid(),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Explore by category',
                subtitle: 'Choose a topic and start learning.',
                trailing: snapshot.connectionState == ConnectionState.waiting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              if (snapshot.hasError)
                _InlineError(
                  message: 'Could not load live categories.',
                  onRetry: _reload,
                )
              else
                _CategoryWrap(categories: data.categories),
              const SizedBox(height: 24),
              _SectionHeader(
                title: 'Featured courses',
                subtitle: 'Free courses currently published.',
                actionLabel: 'View all',
                onAction: widget.onOpenCourses,
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _CourseSkeletonList()
              else if (snapshot.hasError)
                _InlineError(
                  message: 'Could not load live courses.',
                  onRetry: _reload,
                )
              else if (data.courses.isEmpty)
                const _EmptyState(
                  icon: Icons.menu_book_outlined,
                  title: 'No courses published yet',
                  message: 'Published courses will appear here automatically.',
                )
              else
                ...data.courses
                    .take(3)
                    .map(
                      (course) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CourseCard(
                          course: course,
                          onTap: () => _openCourse(context, course),
                        ),
                      ),
                    ),
              const SizedBox(height: 12),
              const _CalloutPanel(),
            ],
          );
        },
      ),
    );
  }

  void _reload() {
    setState(() => _future = widget.api.fetchHomeData());
  }

  void _openCourse(BuildContext context, Course course) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseDetailScreen(
          api: widget.api,
          auth: widget.auth,
          course: course,
          onOpenAccount: widget.onOpenAccount,
        ),
      ),
    );
  }
}

class CoursesTab extends StatefulWidget {
  const CoursesTab({
    required this.api,
    required this.auth,
    required this.onOpenAccount,
    super.key,
  });

  final AcademyApi api;
  final AuthController auth;
  final VoidCallback onOpenAccount;

  @override
  State<CoursesTab> createState() => _CoursesTabState();
}

class _CoursesTabState extends State<CoursesTab> {
  late Future<HomeData> _future;
  final _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchHomeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<HomeData>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data ?? HomeData.empty();
        final filtered = _filterCourses(data.courses);

        return RefreshIndicator(
          onRefresh: () async {
            final next = widget.api.fetchHomeData();
            setState(() => _future = next);
            await next;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            children: [
              const _ScreenIntro(
                icon: Icons.menu_book_rounded,
                title: 'Browse courses',
                subtitle: 'Find live courses from Merolagani Academy.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Search courses',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _line),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _line),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: const Text('All'),
                        selected: _selectedCategory == null,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = null),
                      ),
                    ),
                    ...data.categories.map(
                      (category) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(category.name),
                          selected: _selectedCategory == category.slug,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = category.slug),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState == ConnectionState.waiting)
                const _CourseSkeletonList()
              else if (snapshot.hasError)
                _InlineError(
                  message: 'Courses could not be loaded.',
                  onRetry: () =>
                      setState(() => _future = widget.api.fetchHomeData()),
                )
              else if (filtered.isEmpty)
                const _EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'No matching courses',
                  message: 'Try another search term or category.',
                )
              else
                ...filtered.map(
                  (course) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CourseCard(
                      course: course,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CourseDetailScreen(
                            api: widget.api,
                            auth: widget.auth,
                            course: course,
                            onOpenAccount: widget.onOpenAccount,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  List<Course> _filterCourses(List<Course> courses) {
    final query = _searchController.text.trim().toLowerCase();
    return courses.where((course) {
      final categoryMatches =
          _selectedCategory == null ||
          course.category?.slug == _selectedCategory;
      final text = '${course.title} ${course.subtitle} ${course.description}'
          .toLowerCase();
      return categoryMatches && (query.isEmpty || text.contains(query));
    }).toList();
  }
}

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({
    required this.api,
    required this.auth,
    required this.course,
    required this.onOpenAccount,
    super.key,
  });

  final AcademyApi api;
  final AuthController auth;
  final Course course;
  final VoidCallback onOpenAccount;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  late Future<CourseDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchCourseDetail(widget.course.slug);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.course.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: FutureBuilder<CourseDetail>(
        future: _future,
        builder: (context, snapshot) {
          final detail =
              snapshot.data ?? CourseDetail.fromCourse(widget.course);
          return RefreshIndicator(
            onRefresh: () async {
              final next = widget.api.fetchCourseDetail(widget.course.slug);
              setState(() => _future = next);
              await next;
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _CourseHeroImage(course: detail.course),
                const SizedBox(height: 18),
                if (detail.course.category != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _Pill(
                      text: detail.course.category!.name,
                      color: _brandTeal,
                    ),
                  ),
                const SizedBox(height: 10),
                Text(
                  detail.course.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.08,
                    letterSpacing: 0,
                  ),
                ),
                if (detail.course.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    detail.course.subtitle,
                    style: const TextStyle(
                      color: _mutedInk,
                      fontSize: 16,
                      height: 1.35,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _MetricChip(
                      icon: Icons.signal_cellular_alt_rounded,
                      label: detail.course.levelLabel,
                    ),
                    _MetricChip(
                      icon: Icons.play_lesson_rounded,
                      label: '${detail.lessonCount} lessons',
                    ),
                    _MetricChip(
                      icon: Icons.timer_rounded,
                      label: detail.course.durationLabel,
                    ),
                    const _MetricChip(
                      icon: Icons.workspace_premium_rounded,
                      label: 'Certificate',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: widget.auth,
                  builder: (context, _) {
                    final isSignedIn = widget.auth.isSignedIn;
                    return FilledButton.icon(
                      onPressed: detail.sections.isEmpty
                          ? null
                          : () {
                              if (!isSignedIn) {
                                widget.onOpenAccount();
                                return;
                              }
                              _openLearningScreen(context, detail);
                            },
                      icon: Icon(
                        isSignedIn
                            ? Icons.play_arrow_rounded
                            : Icons.lock_open_rounded,
                      ),
                      label: Text(
                        isSignedIn ? 'Start learning' : 'Sign in to start',
                      ),
                    );
                  },
                ),
                const SizedBox(height: 18),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 3),
                if (snapshot.hasError)
                  _InlineError(
                    message:
                        'Live course detail could not load. Showing the cached summary.',
                    onRetry: () => setState(
                      () => _future = widget.api.fetchCourseDetail(
                        widget.course.slug,
                      ),
                    ),
                  ),
                if (detail.course.description.isNotEmpty) ...[
                  const _DetailHeading('Description'),
                  Text(
                    detail.course.description,
                    style: const TextStyle(
                      color: _mutedInk,
                      height: 1.5,
                      fontSize: 15,
                    ),
                  ),
                ],
                if (detail.course.learningOutcomes.isNotEmpty) ...[
                  const _DetailHeading("What you'll learn"),
                  ...detail.course.learningOutcomes.map(
                    (item) => _CheckLine(text: item),
                  ),
                ],
                if (detail.course.requirements.isNotEmpty) ...[
                  const _DetailHeading('Requirements'),
                  ...detail.course.requirements.map(
                    (item) => _BulletLine(text: item),
                  ),
                ],
                const _DetailHeading('Curriculum'),
                if (detail.sections.isEmpty)
                  const _EmptyState(
                    icon: Icons.play_lesson_outlined,
                    title: 'Curriculum not available',
                    message: 'Lessons will appear here after publishing.',
                  )
                else
                  ...detail.sections.map((section) {
                    return _SectionCard(
                      section: section,
                      onLessonTap: (lesson) =>
                          _showLesson(context, detail, lesson),
                    );
                  }),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLesson(BuildContext context, CourseDetail detail, Lesson lesson) {
    if (!widget.auth.isSignedIn && !lesson.isPreview) {
      widget.onOpenAccount();
      return;
    }
    _openLearningScreen(context, detail, initialLessonId: lesson.id);
  }

  void _openLearningScreen(
    BuildContext context,
    CourseDetail detail, {
    String? initialLessonId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CourseLearningScreen(
          api: widget.api,
          auth: widget.auth,
          detail: detail,
          initialLessonId: initialLessonId,
          onOpenAccount: widget.onOpenAccount,
        ),
      ),
    );
  }
}

class CourseLearningScreen extends StatefulWidget {
  const CourseLearningScreen({
    required this.api,
    required this.auth,
    required this.detail,
    required this.onOpenAccount,
    this.initialLessonId,
    super.key,
  });

  final AcademyApi api;
  final AuthController auth;
  final CourseDetail detail;
  final VoidCallback onOpenAccount;
  final String? initialLessonId;

  @override
  State<CourseLearningScreen> createState() => _CourseLearningScreenState();
}

class _CourseLearningScreenState extends State<CourseLearningScreen> {
  late Lesson _selectedLesson;

  @override
  void initState() {
    super.initState();
    _selectedLesson =
        widget.detail.lessonById(widget.initialLessonId) ??
        widget.detail.firstLesson;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.auth,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: _surface,
          appBar: AppBar(
            title: Text(
              widget.detail.course.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: _LearningVideoPanel(
                    key: ValueKey(
                      '${_selectedLesson.id}-${widget.auth.isSignedIn}',
                    ),
                    api: widget.api,
                    auth: widget.auth,
                    course: widget.detail.course,
                    lesson: _selectedLesson,
                    onOpenAccount: widget.onOpenAccount,
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    children: [
                      _SelectedLessonSummary(lesson: _selectedLesson),
                      _LessonResourcesPanel(
                        resources: _selectedLesson.resources,
                      ),
                      _LessonQuizPanel(
                        key: ValueKey('quiz-${_selectedLesson.id}'),
                        api: widget.api,
                        auth: widget.auth,
                        lesson: _selectedLesson,
                      ),
                      const _DetailHeading('Course content'),
                      ...widget.detail.sections.map(
                        (section) => _LearningSectionCard(
                          section: section,
                          selectedLessonId: _selectedLesson.id,
                          onLessonTap: (lesson) {
                            setState(() => _selectedLesson = lesson);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LearningVideoPanel extends StatefulWidget {
  const _LearningVideoPanel({
    required this.api,
    required this.auth,
    required this.course,
    required this.lesson,
    required this.onOpenAccount,
    super.key,
  });

  final AcademyApi api;
  final AuthController auth;
  final Course course;
  final Lesson lesson;
  final VoidCallback onOpenAccount;

  @override
  State<_LearningVideoPanel> createState() => _LearningVideoPanelState();
}

class _LearningVideoPanelState extends State<_LearningVideoPanel> {
  Future<VideoPlayerSource>? _future;
  String? _watchSessionId;
  var _furthest = Duration.zero;
  var _lastPosition = Duration.zero;
  var _totalWatchedMillis = 0;
  var _lastSyncAt = DateTime.fromMillisecondsSinceEpoch(0);
  var _skipAttempts = 0;
  bool _creatingWatchSession = false;
  bool _markingComplete = false;

  @override
  void initState() {
    super.initState();
    if (widget.auth.isSignedIn) _load();
  }

  @override
  void didUpdateWidget(covariant _LearningVideoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lesson.id != widget.lesson.id ||
        oldWidget.auth.isSignedIn != widget.auth.isSignedIn) {
      _watchSessionId = null;
      _furthest = Duration.zero;
      _lastPosition = Duration.zero;
      _totalWatchedMillis = 0;
      _lastSyncAt = DateTime.fromMillisecondsSinceEpoch(0);
      _skipAttempts = 0;
      if (widget.auth.isSignedIn) {
        _load();
      } else {
        setState(() => _future = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.auth.isRestoring) {
      return const ColoredBox(
        color: Colors.black,
        child: _PlayerMessage(
          icon: Icons.lock_clock_rounded,
          title: 'Checking session',
          message: 'Getting your learning access ready...',
          showProgress: true,
        ),
      );
    }

    if (!widget.auth.isSignedIn) {
      return ColoredBox(
        color: Colors.black,
        child: _PlayerMessage(
          icon: Icons.lock_open_rounded,
          title: 'Sign in to watch',
          message:
              'Your video, quiz progress, and certificates are connected to your account.',
          buttonLabel: 'Go to account',
          onPressed: widget.onOpenAccount,
        ),
      );
    }

    if (!widget.lesson.hasVideo) {
      return const ColoredBox(
        color: Colors.black,
        child: _PlayerMessage(
          icon: Icons.videocam_off_rounded,
          title: 'Video not connected',
          message: 'This lesson video has not been published yet.',
        ),
      );
    }

    final future = _future;
    if (future == null) {
      return const ColoredBox(
        color: Colors.black,
        child: _PlayerMessage(
          icon: Icons.play_circle_fill_rounded,
          title: 'Loading video',
          message: 'Preparing your lesson video...',
          showProgress: true,
        ),
      );
    }

    return FutureBuilder<VideoPlayerSource>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ColoredBox(
            color: Colors.black,
            child: _PlayerMessage(
              icon: Icons.play_circle_fill_rounded,
              title: 'Loading video',
              message: 'Preparing your lesson video...',
              showProgress: true,
            ),
          );
        }

        if (snapshot.hasError) {
          return ColoredBox(
            color: Colors.black,
            child: _PlayerMessage(
              icon: Icons.error_outline_rounded,
              title: 'Could not load video',
              message: snapshot.error.toString().replaceFirst(
                'Exception: ',
                '',
              ),
              buttonLabel: 'Retry',
              onPressed: _load,
            ),
          );
        }

        final source = snapshot.data;
        if (source == null) {
          return ColoredBox(
            color: Colors.black,
            child: _PlayerMessage(
              icon: Icons.error_outline_rounded,
              title: 'Player unavailable',
              message: 'The video URL was not returned.',
              buttonLabel: 'Retry',
              onPressed: _load,
            ),
          );
        }

        return LessonVideoPlayer(
          source: source,
          onProgress: _handleVideoProgress,
        );
      },
    );
  }

  void _load() {
    setState(() {
      _future = _fetchPlayerSource();
    });
  }

  Future<VideoPlayerSource> _fetchPlayerSource() async {
    if (widget.lesson.videoUrl.isNotEmpty) {
      return VideoPlayerSource.fromUrl(widget.lesson.videoUrl);
    }
    final token = await widget.auth.validAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('Please sign in again to watch videos.');
    }
    try {
      return await widget.api.fetchBunnyPlayerSource(
        lessonId: widget.lesson.id,
        accessToken: token,
      );
    } on AuthExpiredException {
      final refreshedToken = await widget.auth.validAccessToken(
        forceRefresh: true,
      );
      if (refreshedToken == null || refreshedToken.isEmpty) {
        throw Exception('Your session expired. Please sign in again.');
      }
      return widget.api.fetchBunnyPlayerSource(
        lessonId: widget.lesson.id,
        accessToken: refreshedToken,
      );
    }
  }

  void _handleVideoProgress(
    Duration position,
    Duration duration,
    bool completed,
  ) {
    if (!widget.auth.isSignedIn || duration.inSeconds <= 0) return;
    if (position > _furthest) _furthest = position;
    final delta = position - _lastPosition;
    if (delta.inSeconds > 10) {
      _skipAttempts += 1;
    } else if (delta.inMilliseconds > 0) {
      _totalWatchedMillis += delta.inMilliseconds;
    }
    _lastPosition = position;
    final now = DateTime.now();
    if (!completed && now.difference(_lastSyncAt).inSeconds < 12) return;
    _lastSyncAt = now;
    unawaited(_syncProgress(position, duration, completed));
  }

  Future<void> _syncProgress(
    Duration position,
    Duration duration,
    bool completed,
  ) async {
    try {
      final token = await widget.auth.validAccessToken();
      final session = widget.auth.session;
      if (token == null || session == null || session.userId.isEmpty) return;

      var watchSessionId = _watchSessionId;
      if (watchSessionId == null && !_creatingWatchSession) {
        _creatingWatchSession = true;
        watchSessionId = await widget.api.createWatchSession(
          accessToken: token,
          userId: session.userId,
          courseId: widget.course.id,
          lessonId: widget.lesson.id,
          durationSeconds: duration.inSeconds,
        );
        _watchSessionId = watchSessionId;
        _creatingWatchSession = false;
      }

      if (watchSessionId == null) return;
      await widget.api.updateWatchSession(
        accessToken: token,
        watchSessionId: watchSessionId,
        totalSecondsWatched: (_totalWatchedMillis / 1000).round(),
        furthestSeconds: _furthest.inSeconds,
        durationSeconds: duration.inSeconds,
        skipAttempts: _skipAttempts,
        completed: completed,
      );

      if (completed && !_markingComplete) {
        _markingComplete = true;
        await widget.api.markLessonComplete(
          accessToken: token,
          lessonId: widget.lesson.id,
        );
      }
    } catch (_) {
      _creatingWatchSession = false;
      _markingComplete = false;
    }
  }
}

class LessonVideoPlayer extends StatelessWidget {
  const LessonVideoPlayer({
    required this.source,
    required this.onProgress,
    super.key,
  });

  final VideoPlayerSource source;
  final void Function(Duration position, Duration duration, bool completed)
  onProgress;

  @override
  Widget build(BuildContext context) {
    if (source.kind == VideoPlayerSourceKind.embedded) {
      return EmbeddedBunnyPlayer(source: source, onProgress: onProgress);
    }
    return NativeVideoPlayer(source: source, onProgress: onProgress);
  }
}

class EmbeddedBunnyPlayer extends StatefulWidget {
  const EmbeddedBunnyPlayer({
    required this.source,
    required this.onProgress,
    super.key,
  });

  final VideoPlayerSource source;
  final void Function(Duration position, Duration duration, bool completed)
  onProgress;

  @override
  State<EmbeddedBunnyPlayer> createState() => _EmbeddedBunnyPlayerState();
}

class _EmbeddedBunnyPlayerState extends State<EmbeddedBunnyPlayer> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = _buildController(widget.source.uri);
  }

  @override
  void didUpdateWidget(covariant EmbeddedBunnyPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source.uri != widget.source.uri) {
      setState(() {
        _loading = true;
        _error = null;
      });
      unawaited(_controller.loadRequest(widget.source.uri));
    }
  }

  WebViewController _buildController(Uri uri) {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'LessonVideoProgress',
        onMessageReceived: _handleProgressMessage,
      )
      ..setUserAgent(
        'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
        '(KHTML, like Gecko) Chrome/125 Mobile Safari/537.36',
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _error = null;
              });
            }
          },
          onPageFinished: (_) {
            _installProgressBridge();
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              setState(() {
                _loading = false;
                _error = error.description;
              });
            }
          },
        ),
      )
      ..loadRequest(uri);
  }

  void _installProgressBridge() {
    unawaited(
      _controller
          .runJavaScript('''
        (function () {
          if (window.__merolaganiProgressBridgeInstalled) return;
          window.__merolaganiProgressBridgeInstalled = true;
          function reportProgress() {
            var video = document.querySelector('video');
            if (!video || !isFinite(video.duration) || video.duration <= 0) {
              return;
            }
            LessonVideoProgress.postMessage(JSON.stringify({
              position: video.currentTime || 0,
              duration: video.duration || 0,
              completed: !!video.ended
            }));
          }
          setInterval(reportProgress, 1000);
          document.addEventListener('play', reportProgress, true);
          document.addEventListener('pause', reportProgress, true);
          document.addEventListener('ended', reportProgress, true);
        })();
      ''')
          .catchError((_) {}),
    );
  }

  void _handleProgressMessage(JavaScriptMessage message) {
    try {
      final payload = jsonDecode(message.message);
      if (payload is! Map<String, dynamic>) return;
      final positionSeconds = (payload['position'] as num?)?.toDouble();
      final durationSeconds = (payload['duration'] as num?)?.toDouble();
      final completed = payload['completed'] == true;
      if (positionSeconds == null ||
          durationSeconds == null ||
          durationSeconds <= 0) {
        return;
      }
      widget.onProgress(
        Duration(milliseconds: (positionSeconds * 1000).round()),
        Duration(milliseconds: (durationSeconds * 1000).round()),
        completed,
      );
    } catch (_) {
      // Ignore malformed WebView bridge messages; playback should continue.
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    if (error != null) {
      return ColoredBox(
        color: Colors.black,
        child: _PlayerMessage(
          icon: Icons.error_outline_rounded,
          title: 'Playback failed',
          message: error,
        ),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: Colors.black,
          child: WebViewWidget(controller: _controller),
        ),
        if (_loading)
          const ColoredBox(
            color: Colors.black,
            child: _PlayerMessage(
              icon: Icons.play_circle_fill_rounded,
              title: 'Loading video',
              message: 'Opening Bunny video player...',
              showProgress: true,
            ),
          ),
      ],
    );
  }
}

class NativeVideoPlayer extends StatefulWidget {
  const NativeVideoPlayer({
    required this.source,
    required this.onProgress,
    super.key,
  });

  final VideoPlayerSource source;
  final void Function(Duration position, Duration duration, bool completed)
  onProgress;

  @override
  State<NativeVideoPlayer> createState() => _NativeVideoPlayerState();
}

class _NativeVideoPlayerState extends State<NativeVideoPlayer> {
  VideoPlayerController? _controller;
  Future<void>? _initializeFuture;
  bool _showControls = true;
  bool _completedSent = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(covariant NativeVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source.uri != widget.source.uri) {
      _disposeController();
      _completedSent = false;
      _initialize();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  void _initialize() {
    final controller = VideoPlayerController.networkUrl(
      widget.source.uri,
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
    )..addListener(_onControllerTick);
    _controller = controller;
    _initializeFuture = controller.initialize().then((_) {
      if (mounted) setState(() {});
    });
    setState(() {});
  }

  void _disposeController() {
    final controller = _controller;
    if (controller == null) return;
    controller.removeListener(_onControllerTick);
    controller.dispose();
    _controller = null;
  }

  void _onControllerTick() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final value = controller.value;
    final duration = value.duration;
    final position = value.position;
    final completed =
        duration.inSeconds > 0 &&
        position.inSeconds >= duration.inSeconds - 2 &&
        !value.isPlaying;
    if (completed && _completedSent) return;
    if (completed) _completedSent = true;
    widget.onProgress(position, duration, completed);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) return const ColoredBox(color: Colors.black);

    return FutureBuilder<void>(
      future: _initializeFuture,
      builder: (context, snapshot) {
        final value = controller.value;
        if (snapshot.connectionState != ConnectionState.done) {
          return const ColoredBox(
            color: Colors.black,
            child: _PlayerMessage(
              icon: Icons.play_circle_fill_rounded,
              title: 'Loading video',
              message: 'Preparing native video playback...',
              showProgress: true,
            ),
          );
        }

        if (snapshot.hasError) {
          return ColoredBox(
            color: Colors.black,
            child: _PlayerMessage(
              icon: Icons.error_outline_rounded,
              title: 'Playback failed',
              message:
                  snapshot.error?.toString().replaceFirst('Exception: ', '') ??
                  'The video stream could not be played on this device.',
            ),
          );
        }

        if (value.hasError) {
          return ColoredBox(
            color: Colors.black,
            child: _PlayerMessage(
              icon: Icons.error_outline_rounded,
              title: 'Playback failed',
              message:
                  value.errorDescription ??
                  'The video stream could not be played on this device.',
            ),
          );
        }

        return GestureDetector(
          onTap: () => setState(() => _showControls = !_showControls),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(
                color: Colors.black,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: value.aspectRatio == 0
                        ? 16 / 9
                        : value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                ),
              ),
              if (_showControls)
                ColoredBox(
                  color: Colors.black26,
                  child: Stack(
                    children: [
                      Center(
                        child: IconButton.filled(
                          iconSize: 42,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black54,
                            foregroundColor: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              value.isPlaying
                                  ? controller.pause()
                                  : controller.play();
                            });
                          },
                          icon: Icon(
                            value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                        ),
                      ),
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 10,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            VideoProgressIndicator(
                              controller,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: _brandGold,
                                bufferedColor: Colors.white38,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(value.position),
                                  style: const TextStyle(color: Colors.white),
                                ),
                                Text(
                                  _formatDuration(value.duration),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

enum VideoPlayerSourceKind { nativeStream, embedded }

class VideoPlayerSource {
  const VideoPlayerSource(this.uri, {required this.kind});

  factory VideoPlayerSource.fromUrl(
    String value, {
    VideoPlayerSourceKind? kind,
  }) {
    final uri = Uri.parse(value);
    return VideoPlayerSource(uri, kind: kind ?? _inferVideoSourceKind(uri));
  }

  final Uri uri;
  final VideoPlayerSourceKind kind;
}

VideoPlayerSourceKind _inferVideoSourceKind(Uri uri) {
  final value = uri.toString().toLowerCase();
  final path = uri.path.toLowerCase();
  if (path.endsWith('.m3u8') ||
      path.endsWith('.mp4') ||
      path.endsWith('.mov') ||
      value.contains('playlist.m3u8') ||
      value.contains('manifest/video.m3u8')) {
    return VideoPlayerSourceKind.nativeStream;
  }
  return VideoPlayerSourceKind.embedded;
}

String _formatDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final minutes = totalSeconds ~/ 60;
  final seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

class _SelectedLessonSummary extends StatelessWidget {
  const _SelectedLessonSummary({required this.lesson});

  final Lesson lesson;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MetricChip(
                icon: Icons.timer_rounded,
                label: lesson.durationLabel,
              ),
              const _MetricChip(
                icon: Icons.play_circle_fill_rounded,
                label: 'Video lesson',
              ),
              if (lesson.quizzes.isNotEmpty)
                _MetricChip(
                  icon: Icons.quiz_rounded,
                  label: '${lesson.quizzes.length} quiz',
                ),
              if (lesson.isPreview)
                const _MetricChip(
                  icon: Icons.visibility_rounded,
                  label: 'Preview',
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            lesson.title,
            style: const TextStyle(
              color: _brandInk,
              fontSize: 23,
              fontWeight: FontWeight.w900,
              height: 1.14,
            ),
          ),
          if (lesson.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              lesson.description,
              style: const TextStyle(
                color: _mutedInk,
                height: 1.45,
                fontSize: 15,
              ),
            ),
          ],
          if (lesson.content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              lesson.content,
              style: const TextStyle(
                color: _mutedInk,
                height: 1.5,
                fontSize: 15,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LessonResourcesPanel extends StatelessWidget {
  const _LessonResourcesPanel({required this.resources});

  final List<LessonResource> resources;

  @override
  Widget build(BuildContext context) {
    if (resources.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DetailHeading('Resources'),
        ...resources.map(
          (resource) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: _line),
              ),
              tileColor: Colors.white,
              leading: const Icon(Icons.attach_file_rounded),
              title: Text(resource.title),
              subtitle: Text(resource.fileTypeLabel),
              trailing: const Icon(Icons.open_in_new_rounded),
              onTap: resource.url.isEmpty
                  ? null
                  : () => _openExternal(Uri.parse(resource.url)),
            ),
          ),
        ),
      ],
    );
  }
}

class _LessonQuizPanel extends StatefulWidget {
  const _LessonQuizPanel({
    required this.api,
    required this.auth,
    required this.lesson,
    super.key,
  });

  final AcademyApi api;
  final AuthController auth;
  final Lesson lesson;

  @override
  State<_LessonQuizPanel> createState() => _LessonQuizPanelState();
}

class _LessonQuizPanelState extends State<_LessonQuizPanel> {
  final Map<String, Set<int>> _answers = {};
  final Map<String, String> _messages = {};
  final Set<String> _submitting = {};
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final quizzes = widget.lesson.quizzes;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DetailHeading('Quiz'),
        if (quizzes.isEmpty)
          const _EmptyState(
            icon: Icons.quiz_outlined,
            title: 'No quiz attached yet',
            message: 'Quiz questions from the website will appear here.',
          )
        else
          ...quizzes.map(_buildQuiz),
      ],
    );
  }

  Widget _buildQuiz(LessonQuiz quiz) {
    final score = _checked ? _scoreQuiz(quiz) : null;
    final message = _messages[quiz.id];
    final submitting = _submitting.contains(quiz.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quiz.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            'Passing score: ${quiz.passingScore}%',
            style: const TextStyle(color: _mutedInk),
          ),
          const SizedBox(height: 14),
          ...quiz.questions.map(
            (question) => _QuestionBlock(
              question: question,
              selectedIndexes: _answers[question.id] ?? const <int>{},
              checked: _checked && quiz.showCorrectAnswers,
              onChanged: (index, selected) {
                setState(() {
                  final next = {...?_answers[question.id]};
                  if (question.isMultipleAnswer) {
                    selected ? next.add(index) : next.remove(index);
                  } else {
                    next
                      ..clear()
                      ..add(index);
                  }
                  _answers[question.id] = next;
                  _checked = false;
                });
              },
            ),
          ),
          const SizedBox(height: 8),
          if (score != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Score: ${score.earned}/${score.total} (${score.percent}%)',
                style: TextStyle(
                  color: score.passed(quiz)
                      ? _brandTealDark
                      : Colors.orange.shade800,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          if (message != null) ...[
            Text(
              message,
              style: const TextStyle(color: _mutedInk, height: 1.35),
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: submitting ? null : () => _handleQuizAction(quiz),
              icon: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      widget.auth.isSignedIn
                          ? Icons.cloud_done_rounded
                          : Icons.fact_check_rounded,
                    ),
              label: Text(
                widget.auth.isSignedIn ? 'Submit quiz' : 'Check answers',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQuizAction(LessonQuiz quiz) async {
    final score = _scoreQuiz(quiz);
    if (!_allQuestionsAnswered(quiz)) {
      setState(() {
        _checked = true;
        _messages[quiz.id] = 'Answer all questions before submitting.';
      });
      return;
    }

    if (!widget.auth.isSignedIn) {
      setState(() {
        _checked = true;
        _messages[quiz.id] = 'Sign in to save quiz progress.';
      });
      return;
    }

    setState(() {
      _checked = true;
      _submitting.add(quiz.id);
      _messages.remove(quiz.id);
    });

    try {
      final token = await widget.auth.validAccessToken();
      final session = widget.auth.session;
      if (token == null || session == null || session.userId.isEmpty) {
        throw Exception('Please sign in again to submit this quiz.');
      }
      await widget.api.submitQuizAttempt(
        accessToken: token,
        userId: session.userId,
        quiz: quiz,
        answers: _answersForQuiz(quiz),
        score: score,
      );
      if (!mounted) return;
      setState(() {
        _messages[quiz.id] = score.passed(quiz)
            ? 'Quiz submitted. Passing score reached.'
            : 'Quiz submitted. Review the lesson and try again.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages[quiz.id] = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() => _submitting.remove(quiz.id));
      }
    }
  }

  bool _allQuestionsAnswered(LessonQuiz quiz) {
    return quiz.questions.every((question) {
      return (_answers[question.id] ?? const <int>{}).isNotEmpty;
    });
  }

  Map<String, dynamic> _answersForQuiz(LessonQuiz quiz) {
    return {
      for (final question in quiz.questions)
        question.id: {
          'selectedIndexes': (_answers[question.id] ?? const <int>{}).toList()
            ..sort(),
          'selectedOptions': [
            for (final index in (_answers[question.id] ?? const <int>{}))
              if (index >= 0 && index < question.options.length)
                question.options[index],
          ],
        },
    };
  }

  QuizScore _scoreQuiz(LessonQuiz quiz) {
    var earned = 0;
    var total = 0;
    for (final question in quiz.questions) {
      final points = question.points <= 0 ? 1 : question.points;
      total += points;
      final selected = _answers[question.id] ?? const <int>{};
      if (selected.length == question.correctAnswerIndexes.length &&
          selected.containsAll(question.correctAnswerIndexes)) {
        earned += points;
      }
    }
    return QuizScore(earned: earned, total: total);
  }
}

class QuizScore {
  const QuizScore({required this.earned, required this.total});

  final int earned;
  final int total;

  int get percent => total <= 0 ? 0 : ((earned / total) * 100).round();

  bool passed(LessonQuiz quiz) => percent >= quiz.passingScore;
}

class _QuestionBlock extends StatelessWidget {
  const _QuestionBlock({
    required this.question,
    required this.selectedIndexes,
    required this.checked,
    required this.onChanged,
  });

  final QuizQuestion question;
  final Set<int> selectedIndexes;
  final bool checked;
  final void Function(int index, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.question,
            style: const TextStyle(fontWeight: FontWeight.w800, height: 1.35),
          ),
          const SizedBox(height: 10),
          ...question.options.asMap().entries.map((entry) {
            final index = entry.key;
            final selected = selectedIndexes.contains(index);
            final correct = question.correctAnswerIndexes.contains(index);
            final color = checked
                ? correct
                      ? _brandTealDark
                      : selected
                      ? Colors.red.shade700
                      : _mutedInk
                : _brandInk;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => onChanged(index, !selected),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: selected
                        ? _brandTeal.withAlpha(24)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: checked && correct
                          ? _brandTeal
                          : selected
                          ? _brandTeal
                          : _line,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        question.isMultipleAnswer
                            ? selected
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded
                            : selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_unchecked_rounded,
                        color: color,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(color: color),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (checked && question.explanation.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              question.explanation,
              style: const TextStyle(color: _mutedInk, height: 1.4),
            ),
          ],
        ],
      ),
    );
  }
}

class _LearningSectionCard extends StatelessWidget {
  const _LearningSectionCard({
    required this.section,
    required this.selectedLessonId,
    required this.onLessonTap,
  });

  final CourseSection section;
  final String selectedLessonId;
  final ValueChanged<Lesson> onLessonTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(radius: 18),
      child: ExpansionTile(
        initiallyExpanded: section.lessons.any(
          (lesson) => lesson.id == selectedLessonId,
        ),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          section.title,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text('${section.lessons.length} lessons'),
        children: section.lessons.map((lesson) {
          final selected = lesson.id == selectedLessonId;
          return ListTile(
            selected: selected,
            selectedTileColor: _brandTeal.withAlpha(18),
            leading: Icon(
              selected
                  ? Icons.play_circle_fill_rounded
                  : Icons.play_circle_outline_rounded,
              color: selected ? _brandTealDark : _mutedInk,
            ),
            title: Text(lesson.title),
            subtitle: Text(
              [
                lesson.durationLabel,
                if (lesson.quizzes.isNotEmpty) '${lesson.quizzes.length} quiz',
                if (lesson.resources.isNotEmpty)
                  '${lesson.resources.length} resources',
              ].join(' • '),
            ),
            trailing: lesson.isPreview
                ? const Icon(Icons.visibility_rounded, color: _brandTealDark)
                : null,
            onTap: () => onLessonTap(lesson),
          );
        }).toList(),
      ),
    );
  }
}

class _PlayerMessage extends StatelessWidget {
  const _PlayerMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.buttonLabel,
    this.onPressed,
    this.showProgress = false,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? buttonLabel;
  final VoidCallback? onPressed;
  final bool showProgress;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = 16.0;
        final width = (constraints.maxWidth - padding * 2)
            .clamp(0.0, 520.0)
            .toDouble();
        final compact = constraints.maxHeight < 260;

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(padding),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: Colors.white, size: compact ? 34 : 40),
                    SizedBox(height: compact ? 8 : 12),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: compact ? 18 : 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: compact ? 6 : 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        height: 1.35,
                      ),
                    ),
                    if (showProgress) ...[
                      SizedBox(height: compact ? 12 : 16),
                      const SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(strokeWidth: 2.4),
                      ),
                    ],
                    if (buttonLabel != null && onPressed != null) ...[
                      SizedBox(height: compact ? 12 : 16),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                        ),
                        onPressed: onPressed,
                        child: Text(buttonLabel!),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class LearnTab extends StatefulWidget {
  const LearnTab({
    required this.api,
    required this.auth,
    required this.onOpenAccount,
    super.key,
  });

  final AcademyApi api;
  final AuthController auth;
  final VoidCallback onOpenAccount;

  @override
  State<LearnTab> createState() => _LearnTabState();
}

class _LearnTabState extends State<LearnTab> {
  late Future<HomeData> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.api.fetchHomeData();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.auth,
      builder: (context, _) {
        if (!widget.auth.isSignedIn) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            children: [
              const _ScreenIntro(
                icon: Icons.play_circle_fill_rounded,
                title: 'My learning',
                subtitle:
                    'Sign in to track progress, continue lessons, and earn certificates.',
              ),
              const SizedBox(height: 16),
              _ActionPanel(
                icon: Icons.lock_open_rounded,
                title: 'Create your free account',
                message:
                    'Learning progress is connected to your Merolagani Academy account.',
                buttonLabel: 'Go to account',
                onPressed: widget.onOpenAccount,
              ),
              const SizedBox(height: 20),
              FutureBuilder<HomeData>(
                future: _future,
                builder: (context, snapshot) {
                  final courses = snapshot.data?.courses ?? const <Course>[];
                  if (courses.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionHeader(
                        title: 'Available learning paths',
                        subtitle: 'You can browse before signing in.',
                      ),
                      const SizedBox(height: 12),
                      ...courses.map(
                        (course) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: CourseCard(
                            course: course,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => CourseDetailScreen(
                                  api: widget.api,
                                  auth: widget.auth,
                                  course: course,
                                  onOpenAccount: widget.onOpenAccount,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        }

        return FutureBuilder<HomeData>(
          future: _future,
          builder: (context, snapshot) {
            final courses = snapshot.data?.courses ?? const <Course>[];
            return RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                children: [
                  _ScreenIntro(
                    icon: Icons.school_rounded,
                    title: 'Welcome back',
                    subtitle:
                        widget.auth.session?.email ??
                        'Continue your learning path.',
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      Expanded(
                        child: _ProgressSummaryCard(
                          icon: Icons.menu_book_rounded,
                          value: 'Free',
                          label: 'Learning access',
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _ProgressSummaryCard(
                          icon: Icons.workspace_premium_rounded,
                          value: 'Certs',
                          label: 'On completion',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const _SectionHeader(
                    title: 'Continue learning',
                    subtitle: 'Choose any published course to continue.',
                  ),
                  const SizedBox(height: 12),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const _CourseSkeletonList()
                  else if (snapshot.hasError)
                    const _EmptyState(
                      icon: Icons.cloud_off_rounded,
                      title: 'Could not load learning data',
                      message: 'Pull to refresh and try again.',
                    )
                  else if (courses.isEmpty)
                    const _EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: 'No learning paths yet',
                      message: 'Published courses will appear here.',
                    )
                  else
                    ...courses.map(
                      (course) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: CourseCard(
                          course: course,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => CourseDetailScreen(
                                api: widget.api,
                                auth: widget.auth,
                                course: course,
                                onOpenAccount: widget.onOpenAccount,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _reload() async {
    final next = widget.api.fetchHomeData();
    setState(() => _future = next);
    await next;
  }
}

class VerifyTab extends StatefulWidget {
  const VerifyTab({required this.api, super.key});

  final AcademyApi api;

  @override
  State<VerifyTab> createState() => _VerifyTabState();
}

class _VerifyTabState extends State<VerifyTab> {
  final _controller = TextEditingController();
  Future<CertificateResult?>? _future;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        const _ScreenIntro(
          icon: Icons.verified_rounded,
          title: 'Verify certificate',
          subtitle:
              'Check whether a Merolagani Academy certificate is genuine.',
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
            hintText: 'Example: MLA-MOUXUBQI',
            labelText: 'Certificate number',
            prefixIcon: const Icon(Icons.badge_rounded),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
          onSubmitted: (_) => _verify(),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _verify,
          icon: const Icon(Icons.search_rounded),
          label: const Text('Verify'),
        ),
        const SizedBox(height: 18),
        if (_future != null)
          FutureBuilder<CertificateResult?>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _LoadingPanel(label: 'Checking certificate...');
              }
              if (snapshot.hasError) {
                return _InlineError(
                  message: 'Certificate verification failed.',
                  onRetry: _verify,
                );
              }
              final result = snapshot.data;
              if (result == null) {
                return const _EmptyState(
                  icon: Icons.cancel_rounded,
                  title: 'Certificate not found',
                  message: 'Please check the certificate number and try again.',
                );
              }
              return _CertificateCard(result: result);
            },
          ),
      ],
    );
  }

  void _verify() {
    final number = _controller.text.trim().toUpperCase();
    if (number.isEmpty) return;
    setState(() => _future = widget.api.verifyCertificate(number));
  }
}

class AccountTab extends StatefulWidget {
  const AccountTab({required this.auth, super.key});

  final AuthController auth;

  @override
  State<AccountTab> createState() => _AccountTabState();
}

class _AccountTabState extends State<AccountTab> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  bool _signUp = false;
  bool _busy = false;
  bool _obscurePassword = true;
  String? _message;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _fullName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.auth,
      builder: (context, _) {
        if (widget.auth.isRestoring) {
          return const Center(child: CircularProgressIndicator());
        }

        if (widget.auth.isSignedIn) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            children: [
              const _ScreenIntro(
                icon: Icons.person_rounded,
                title: 'Account',
                subtitle: 'Manage your Merolagani Academy session.',
              ),
              const SizedBox(height: 16),
              _ProfilePanel(
                email: widget.auth.session?.email ?? 'Signed in',
                onSignOut: widget.auth.signOut,
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            _ScreenIntro(
              icon: _signUp ? Icons.person_add_rounded : Icons.login_rounded,
              title: _signUp ? 'Create free account' : 'Log in',
              subtitle: _signUp
                  ? 'Start tracking your course progress.'
                  : 'Access your Merolagani Academy learning profile.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  if (_signUp) ...[
                    TextField(
                      controller: _fullName,
                      textInputAction: TextInputAction.next,
                      textCapitalization: TextCapitalization.words,
                      autofillHints: const [AutofillHints.name],
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _password,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_rounded
                              : Icons.visibility_off_rounded,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  if (_message != null) ...[
                    Text(
                      _message!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _message!.toLowerCase().contains('success')
                            ? _brandTealDark
                            : Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_signUp ? 'Sign up free' : 'Log in'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _signUp = !_signUp;
                            _message = null;
                          }),
                    child: Text(
                      _signUp
                          ? 'Already have an account? Log in'
                          : 'Need an account? Sign up free',
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    final email = _email.text.trim();
    final password = _password.text;
    if (email.isEmpty || password.length < 6) {
      setState(() => _message = 'Enter a valid email and password.');
      return;
    }

    setState(() {
      _busy = true;
      _message = null;
    });

    try {
      if (_signUp) {
        final result = await widget.auth.signUp(
          email: email,
          password: password,
          fullName: _fullName.text.trim(),
        );
        setState(() => _message = result);
      } else {
        await widget.auth.signIn(email: email, password: password);
      }
    } catch (error) {
      setState(
        () => _message = error.toString().replaceFirst('Exception: ', ''),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class AuthExpiredException implements Exception {
  const AuthExpiredException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AcademyApi {
  AcademyApi(this._client);

  final http.Client _client;

  void close() => _client.close();

  Future<HomeData> fetchHomeData() async {
    final values = await Future.wait([fetchCourses(), fetchCategories()]);
    return HomeData(
      courses: values[0] as List<Course>,
      categories: values[1] as List<Category>,
    );
  }

  Future<List<Course>> fetchCourses() async {
    final rows = await _getList(
      _restUri('courses', {
        'select':
            'id,slug,title,subtitle,description,thumbnail_url,duration_minutes,duration_seconds,level,is_published,created_at,category:categories(id,name,slug,description),lessons(count)',
        'is_published': 'eq.true',
        'order': 'created_at.desc',
      }),
    );
    return rows.map((row) => Course.fromJson(row)).toList();
  }

  Future<List<Category>> fetchCategories() async {
    final rows = await _getList(
      _restUri('categories', {
        'select': 'id,name,slug,description',
        'order': 'name.asc',
      }),
    );
    return rows.map((row) => Category.fromJson(row)).toList();
  }

  Future<CourseDetail> fetchCourseDetail(String slug) async {
    final rows = await _getList(
      _restUri('courses', {
        'select':
            'id,slug,title,subtitle,description,thumbnail_url,level,duration_minutes,duration_seconds,learning_outcomes,requirements,instructor_id,is_published,category:categories(id,name,slug,description),sections(id,title,position,lessons(id,course_id,section_id,title,description,duration_minutes,duration_seconds,position,is_preview,bunny_video_guid,video_url,content,video_completion_threshold,quiz_required_for_completion,show_quiz_before_completion,show_resources_before_completion))',
        'slug': 'eq.$slug',
        'limit': '1',
      }),
    );
    if (rows.isEmpty) {
      throw Exception('Course not found.');
    }
    final detail = CourseDetail.fromJson(rows.first);
    final lessonIds = detail.lessonIds;
    final values = await Future.wait([
      fetchQuizzesForCourse(detail.course.id),
      fetchResourcesForLessons(lessonIds),
    ]);
    return detail.withLessonSupplements(
      quizzesByLesson: values[0] as Map<String, List<LessonQuiz>>,
      resourcesByLesson: values[1] as Map<String, List<LessonResource>>,
    );
  }

  Future<Map<String, List<LessonQuiz>>> fetchQuizzesForCourse(
    String courseId,
  ) async {
    if (courseId.isEmpty) return const {};
    final quizRows = await _getList(
      _restUri('quizzes', {
        'select':
            'id,lesson_id,course_id,title,description,passing_score,max_attempts,time_limit_minutes,show_correct_answers',
        'course_id': 'eq.$courseId',
        'order': 'created_at.asc',
      }),
    );
    if (quizRows.isEmpty) return const {};

    final quizIds = quizRows
        .map((row) => row['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final questionRows = await _getList(
      _restUri('quiz_questions', {
        'select':
            'id,quiz_id,question,type,options,correct_answers,position,points,explanation',
        'quiz_id': _inFilter(quizIds),
        'order': 'position.asc',
      }),
    );

    final questionsByQuiz = <String, List<QuizQuestion>>{};
    for (final row in questionRows) {
      final question = QuizQuestion.fromJson(row);
      questionsByQuiz.putIfAbsent(question.quizId, () => []).add(question);
    }

    final quizzesByLesson = <String, List<LessonQuiz>>{};
    for (final row in quizRows) {
      final quiz = LessonQuiz.fromJson(
        row,
        questionsByQuiz[row['id']?.toString() ?? ''] ?? const [],
      );
      if (quiz.lessonId.isEmpty) continue;
      quizzesByLesson.putIfAbsent(quiz.lessonId, () => []).add(quiz);
    }
    return quizzesByLesson;
  }

  Future<Map<String, List<LessonResource>>> fetchResourcesForLessons(
    List<String> lessonIds,
  ) async {
    final ids = lessonIds.where((id) => id.isNotEmpty).toList();
    if (ids.isEmpty) return const {};

    final values = await Future.wait([
      _getList(
        _restUri('resources', {
          'select': 'id,lesson_id,title,url,file_type',
          'lesson_id': _inFilter(ids),
        }),
      ),
      _getList(
        _restUri('lesson_attachments', {
          'select':
              'id,lesson_id,file_name,file_type,file_url,file_size,kind,position',
          'lesson_id': _inFilter(ids),
          'order': 'position.asc',
        }),
      ),
    ]);

    final resourcesByLesson = <String, List<LessonResource>>{};
    for (final row in values.expand((rows) => rows)) {
      final resource = LessonResource.fromJson(row);
      if (resource.lessonId.isEmpty) continue;
      resourcesByLesson.putIfAbsent(resource.lessonId, () => []).add(resource);
    }
    return resourcesByLesson;
  }

  Future<VideoPlayerSource> fetchBunnyPlayerSource({
    required String lessonId,
    required String accessToken,
  }) async {
    if (lessonId.isEmpty) throw Exception('Missing lesson id.');
    if (accessToken.isEmpty) throw Exception('Please sign in to watch videos.');

    final uri = _siteUri.resolve('/api/public/bunny/sign-playback');
    final response = await _client.post(
      uri,
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'lessonId': lessonId}),
    );

    if (response.statusCode == 401) {
      throw const AuthExpiredException(
        'Your session expired. Please sign in again.',
      );
    }
    if (response.statusCode == 403) {
      throw Exception('Please enroll in this course to watch the lesson.');
    }
    if (response.statusCode >= 400) {
      throw Exception(
        _friendlyResponseMessage(
          response.body,
          fallback: 'Video request failed. Please try again.',
        ),
      );
    }

    final body = _decodeObject(response);
    final embedUrl = _findStringByKeys(body, const [
      'embedUrl',
      'embed_url',
      'playerUrl',
      'player_url',
      'url',
    ]);
    if (embedUrl != null && embedUrl.isNotEmpty) {
      return VideoPlayerSource.fromUrl(
        embedUrl,
        kind: VideoPlayerSourceKind.embedded,
      );
    }

    final nativeUrl = _findStringByKeys(body, const [
      'hlsUrl',
      'hls_url',
      'streamUrl',
      'stream_url',
      'mp4Url',
      'mp4_url',
      'videoUrl',
      'video_url',
      'playbackUrl',
      'playback_url',
    ]);
    if (nativeUrl != null && nativeUrl.isNotEmpty) {
      return VideoPlayerSource.fromUrl(
        nativeUrl,
        kind: _inferVideoSourceKind(Uri.parse(nativeUrl)),
      );
    }

    throw Exception('Video player URL was not returned by the server.');
  }

  Future<String?> createWatchSession({
    required String accessToken,
    required String userId,
    required String courseId,
    required String lessonId,
    required int durationSeconds,
  }) async {
    final response = await _client.post(
      _restUri('video_watch_sessions', {'select': 'id'}),
      headers: _headers(
        contentType: true,
        accessToken: accessToken,
        preferRepresentation: true,
      ),
      body: jsonEncode({
        'user_id': userId,
        'course_id': courseId,
        'lesson_id': lessonId,
        'user_agent': 'Merolagani Academy Flutter Android',
        'device_fingerprint': _deviceFingerprint(userId),
        'total_seconds_watched': 0,
        'furthest_position_seconds': 0,
        'video_duration_seconds': durationSeconds,
        'skip_attempts': 0,
        'completed': false,
      }),
    );
    if (response.statusCode >= 400) return null;
    final decoded = jsonDecode(response.body.isEmpty ? '[]' : response.body);
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map) {
      return (decoded.first as Map)['id']?.toString();
    }
    return null;
  }

  Future<void> updateWatchSession({
    required String accessToken,
    required String watchSessionId,
    required int totalSecondsWatched,
    required int furthestSeconds,
    required int durationSeconds,
    required int skipAttempts,
    required bool completed,
  }) async {
    await _client.patch(
      _restUri('video_watch_sessions', {'id': 'eq.$watchSessionId'}),
      headers: _headers(contentType: true, accessToken: accessToken),
      body: jsonEncode({
        'last_heartbeat_at': DateTime.now().toUtc().toIso8601String(),
        'total_seconds_watched': totalSecondsWatched,
        'furthest_position_seconds': furthestSeconds,
        'video_duration_seconds': durationSeconds,
        'skip_attempts': skipAttempts,
        'completed': completed,
        if (completed) 'ended_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  Future<void> markLessonComplete({
    required String accessToken,
    required String lessonId,
  }) async {
    await _client.post(
      _siteUri.resolve('/api/public/lessons/mark-complete'),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({'lessonId': lessonId}),
    );
  }

  Future<void> submitQuizAttempt({
    required String accessToken,
    required String userId,
    required LessonQuiz quiz,
    required Map<String, dynamic> answers,
    required QuizScore score,
  }) async {
    final response = await _client.post(
      _restUri('quiz_attempts', {'select': 'id'}),
      headers: _headers(
        contentType: true,
        accessToken: accessToken,
        preferRepresentation: true,
      ),
      body: jsonEncode({
        'quiz_id': quiz.id,
        'course_id': quiz.courseId,
        'user_id': userId,
        'answers': answers,
        'score': score.earned,
        'max_score': score.total,
        'passed': score.passed(quiz),
      }),
    );
    if (response.statusCode >= 400) {
      throw Exception(
        _friendlyResponseMessage(
          response.body,
          fallback: 'Quiz attempt could not be saved. Please try again.',
        ),
      );
    }
  }

  Future<CertificateResult?> verifyCertificate(String number) async {
    final certRows = await _getList(
      _restUri('certificates', {
        'select': 'id,user_id,course_id,certificate_number,issued_at',
        'certificate_number': 'eq.$number',
        'limit': '1',
      }),
    );
    if (certRows.isEmpty) return null;
    final cert = certRows.first;

    Course? course;
    final courseId = cert['course_id']?.toString();
    if (courseId != null && courseId.isNotEmpty) {
      final courseRows = await _getList(
        _restUri('courses', {
          'select':
              'id,slug,title,subtitle,description,thumbnail_url,duration_minutes,duration_seconds,level,is_published,category:categories(id,name,slug,description),lessons(count)',
          'id': 'eq.$courseId',
          'limit': '1',
        }),
      );
      if (courseRows.isNotEmpty) course = Course.fromJson(courseRows.first);
    }

    String? holderName;
    final userId = cert['user_id']?.toString();
    if (userId != null && userId.isNotEmpty) {
      final profileRows = await _getList(
        _restUri('profiles', {
          'select': 'full_name',
          'id': 'eq.$userId',
          'limit': '1',
        }),
      );
      if (profileRows.isNotEmpty) {
        holderName = profileRows.first['full_name']?.toString();
      }
    }

    return CertificateResult(
      number: cert['certificate_number']?.toString() ?? number,
      issuedAt: DateTime.tryParse(cert['issued_at']?.toString() ?? ''),
      holderName: holderName,
      courseTitle: course?.title,
    );
  }

  Future<AuthSession?> signIn({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_supabaseUrl/auth/v1/token?grant_type=password');
    final response = await _client.post(
      uri,
      headers: _headers(contentType: true),
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = _decodeObject(response);
    if (response.statusCode >= 400) {
      throw Exception(body['msg'] ?? body['message'] ?? 'Login failed.');
    }
    return AuthSession.fromAuthResponse(body);
  }

  Future<AuthSession?> refreshSession({required String refreshToken}) async {
    final uri = Uri.parse(
      '$_supabaseUrl/auth/v1/token?grant_type=refresh_token',
    );
    final response = await _client.post(
      uri,
      headers: _headers(contentType: true),
      body: jsonEncode({'refresh_token': refreshToken}),
    );
    final body = _decodeObject(response);
    if (response.statusCode >= 400) {
      throw Exception(body['msg'] ?? body['message'] ?? 'Session expired.');
    }
    return AuthSession.fromAuthResponse(body);
  }

  Future<AuthSession?> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final uri = Uri.parse(
      '$_supabaseUrl/auth/v1/signup',
    ).replace(queryParameters: {'redirect_to': 'merolagani://auth-callback'});
    final response = await _client.post(
      uri,
      headers: _headers(contentType: true),
      body: jsonEncode({
        'email': email,
        'password': password,
        'data': {
          if (fullName != null && fullName.isNotEmpty) 'full_name': fullName,
        },
      }),
    );
    final body = _decodeObject(response);
    if (response.statusCode >= 400) {
      throw Exception(body['msg'] ?? body['message'] ?? 'Signup failed.');
    }
    return AuthSession.fromAuthResponse(body);
  }

  Future<List<Map<String, dynamic>>> _getList(Uri uri) async {
    final response = await _client.get(uri, headers: _headers());
    final decoded = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      if (decoded is Map<String, dynamic>) {
        throw Exception(decoded['message'] ?? 'Request failed.');
      }
      throw Exception('Request failed.');
    }
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((row) => row.cast<String, dynamic>())
        .toList();
  }

  Uri _restUri(String table, Map<String, String> query) {
    return Uri.parse(
      '$_supabaseUrl/rest/v1/$table',
    ).replace(queryParameters: query);
  }

  Map<String, String> _headers({
    bool contentType = false,
    String? accessToken,
    bool preferRepresentation = false,
  }) {
    return {
      'apikey': _anonKey,
      'Authorization': 'Bearer ${accessToken ?? _anonKey}',
      'Accept': 'application/json',
      if (contentType) 'Content-Type': 'application/json',
      if (preferRepresentation) 'Prefer': 'return=representation',
    };
  }

  String _inFilter(List<String> values) => 'in.(${values.join(',')})';

  String _deviceFingerprint(String userId) {
    final end = userId.length < 12 ? userId.length : 12;
    final source = 'flutter-android-${userId.substring(0, end)}';
    return base64Url.encode(utf8.encode(source)).replaceAll('=', '');
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    final decoded = jsonDecode(response.body.isEmpty ? '{}' : response.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  String? _findStringByKeys(Object? value, List<String> keys) {
    if (value is Map) {
      for (final key in keys) {
        final direct = value[key];
        if (direct is String && direct.isNotEmpty) return direct;
      }
      for (final item in value.values) {
        final found = _findStringByKeys(item, keys);
        if (found != null) return found;
      }
    }
    if (value is List) {
      for (final item in value) {
        final found = _findStringByKeys(item, keys);
        if (found != null) return found;
      }
    }
    return null;
  }

  String _friendlyResponseMessage(String body, {required String fallback}) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return fallback;
    if (trimmed.contains('Unauthorized')) {
      return 'Please sign in again to watch this video.';
    }
    if (trimmed.contains('Seroval Error')) {
      return 'The video session could not be prepared. Please retry.';
    }

    try {
      final decoded = jsonDecode(trimmed);
      final message = _findMessage(decoded);
      if (message != null && message.isNotEmpty) return message;
    } catch (_) {
      return trimmed.length > 120 ? fallback : trimmed;
    }
    return fallback;
  }

  String? _findMessage(Object? value) {
    if (value is String) return value;
    if (value is List) {
      for (final item in value) {
        final found = _findMessage(item);
        if (found != null) return found;
      }
    }
    if (value is Map) {
      for (final key in const ['message', 'error', 'msg']) {
        final direct = value[key];
        if (direct is String && direct.isNotEmpty) return direct;
      }
      for (final item in value.values) {
        final found = _findMessage(item);
        if (found != null) return found;
      }
    }
    return null;
  }
}

class AuthController extends ChangeNotifier {
  AuthController(this._api);

  static const _sessionKey = 'merolagani_academy_session';

  final AcademyApi _api;
  AuthSession? session;
  bool isRestoring = true;

  bool get isSignedIn => session?.accessToken.isNotEmpty == true;

  Future<void> restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionKey);
      if (raw != null) {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          session = AuthSession.fromStoredJson(decoded);
        }
      }
      if (session?.shouldRefresh == true) {
        await refresh();
      }
    } catch (_) {
      session = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
    } finally {
      isRestoring = false;
      notifyListeners();
    }
  }

  Future<String?> validAccessToken({bool forceRefresh = false}) async {
    final current = session;
    if (current == null || current.accessToken.isEmpty) return null;
    if (forceRefresh || current.shouldRefresh) {
      try {
        await refresh();
      } catch (_) {
        await signOut();
        return null;
      }
    }
    return session?.accessToken;
  }

  Future<void> refresh() async {
    final current = session;
    if (current == null || current.refreshToken.isEmpty) {
      throw Exception('Session expired.');
    }
    final next = await _api.refreshSession(refreshToken: current.refreshToken);
    if (next == null) throw Exception('Session refresh failed.');
    session = next;
    await _save();
    notifyListeners();
  }

  Future<void> signIn({required String email, required String password}) async {
    final next = await _api.signIn(email: email, password: password);
    if (next == null) throw Exception('Login did not return a session.');
    session = next;
    await _save();
    notifyListeners();
  }

  Future<String> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final next = await _api.signUp(
      email: email,
      password: password,
      fullName: fullName,
    );
    if (next != null && next.accessToken.isNotEmpty) {
      session = next;
      await _save();
      notifyListeners();
      return 'Signup successful. You are logged in.';
    }
    return 'Signup successful. Please check email confirmation if required.';
  }

  Future<void> signOut() async {
    session = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final value = session;
    if (value == null) return;
    await prefs.setString(_sessionKey, jsonEncode(value.toStoredJson()));
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.email,
    required this.userId,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final String email;
  final String userId;
  final DateTime? expiresAt;

  DateTime? get effectiveExpiresAt =>
      expiresAt ?? _jwtExpiryFromToken(accessToken);

  bool get shouldRefresh {
    final expiry = effectiveExpiresAt;
    if (expiry == null) return false;
    return DateTime.now().isAfter(expiry.subtract(const Duration(minutes: 5)));
  }

  static AuthSession? fromAuthResponse(Map<String, dynamic> json) {
    final user = (json['user'] is Map) ? (json['user'] as Map) : const {};
    final accessToken = json['access_token']?.toString() ?? '';
    if (accessToken.isEmpty) return nullSession(json);
    final expiresAt = _authExpiryFromJson(json);
    return AuthSession(
      accessToken: accessToken,
      refreshToken: json['refresh_token']?.toString() ?? '',
      email: user['email']?.toString() ?? '',
      userId: user['id']?.toString() ?? '',
      expiresAt: expiresAt,
    );
  }

  factory AuthSession.fromStoredJson(Map<String, dynamic> json) {
    return AuthSession(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      expiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
    );
  }

  static AuthSession? nullSession(Map<String, dynamic> json) {
    final user = (json['user'] is Map) ? (json['user'] as Map) : const {};
    final email = user['email']?.toString() ?? '';
    if (email.isEmpty) return null;
    return AuthSession(
      accessToken: '',
      refreshToken: '',
      email: email,
      userId: user['id']?.toString() ?? '',
      expiresAt: null,
    );
  }

  Map<String, dynamic> toStoredJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'email': email,
      'userId': userId,
      'expiresAt': expiresAt?.toIso8601String(),
    };
  }
}

DateTime? _authExpiryFromJson(Map<String, dynamic> json) {
  final expiresAt = json['expires_at'];
  if (expiresAt is num && expiresAt > 0) {
    return DateTime.fromMillisecondsSinceEpoch(
      expiresAt.round() * 1000,
      isUtc: false,
    );
  }
  final expiresIn = json['expires_in'];
  if (expiresIn is num && expiresIn > 0) {
    return DateTime.now().add(Duration(seconds: expiresIn.round()));
  }
  return null;
}

DateTime? _jwtExpiryFromToken(String token) {
  final parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    final payload = utf8.decode(
      base64Url.decode(base64Url.normalize(parts[1])),
    );
    final decoded = jsonDecode(payload);
    if (decoded is! Map<String, dynamic>) return null;
    final exp = decoded['exp'];
    if (exp is! num || exp <= 0) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      exp.round() * 1000,
      isUtc: false,
    );
  } catch (_) {
    return null;
  }
}

class HomeData {
  const HomeData({required this.courses, required this.categories});

  final List<Course> courses;
  final List<Category> categories;

  factory HomeData.empty() => const HomeData(courses: [], categories: []);
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.description,
  });

  final String id;
  final String name;
  final String slug;
  final String description;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Category',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
    );
  }
}

class Course {
  const Course({
    required this.id,
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.thumbnailUrl,
    required this.durationMinutes,
    required this.durationSeconds,
    required this.level,
    required this.lessonCount,
    required this.category,
    required this.learningOutcomes,
    required this.requirements,
  });

  final String id;
  final String slug;
  final String title;
  final String subtitle;
  final String description;
  final String thumbnailUrl;
  final int durationMinutes;
  final int durationSeconds;
  final String level;
  final int lessonCount;
  final Category? category;
  final List<String> learningOutcomes;
  final List<String> requirements;

  String get levelLabel => level.isEmpty
      ? 'Beginner'
      : '${level[0].toUpperCase()}${level.substring(1)}';

  String get durationLabel {
    final minutes = durationSeconds > 0
        ? (durationSeconds / 60).round()
        : durationMinutes;
    if (minutes <= 0) return 'Self paced';
    if (minutes < 60) return '$minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return rest == 0 ? '$hours hr' : '$hours hr $rest min';
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    final categoryRaw = json['category'];
    final lessonsRaw = json['lessons'];
    var lessonCount = 0;
    if (lessonsRaw is List && lessonsRaw.isNotEmpty) {
      final first = lessonsRaw.first;
      if (first is Map) lessonCount = _asInt(first['count']);
    }
    return Course(
      id: json['id']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled course',
      subtitle: json['subtitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      thumbnailUrl: json['thumbnail_url']?.toString() ?? '',
      durationMinutes: _asInt(json['duration_minutes']),
      durationSeconds: _asInt(json['duration_seconds']),
      level: json['level']?.toString() ?? '',
      lessonCount: lessonCount,
      category: categoryRaw is Map
          ? Category.fromJson(categoryRaw.cast<String, dynamic>())
          : null,
      learningOutcomes: _asStringList(json['learning_outcomes']),
      requirements: _asStringList(json['requirements']),
    );
  }

  Course copyWith({int? lessonCount}) {
    return Course(
      id: id,
      slug: slug,
      title: title,
      subtitle: subtitle,
      description: description,
      thumbnailUrl: thumbnailUrl,
      durationMinutes: durationMinutes,
      durationSeconds: durationSeconds,
      level: level,
      lessonCount: lessonCount ?? this.lessonCount,
      category: category,
      learningOutcomes: learningOutcomes,
      requirements: requirements,
    );
  }
}

class CourseDetail {
  const CourseDetail({required this.course, required this.sections});

  final Course course;
  final List<CourseSection> sections;

  int get lessonCount =>
      sections.fold(0, (count, section) => count + section.lessons.length);

  List<String> get lessonIds => [
    for (final section in sections)
      for (final lesson in section.lessons) lesson.id,
  ];

  Lesson get firstLesson {
    for (final section in sections) {
      if (section.lessons.isNotEmpty) return section.lessons.first;
    }
    return Lesson.empty(course.id);
  }

  Lesson? lessonById(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final section in sections) {
      for (final lesson in section.lessons) {
        if (lesson.id == id) return lesson;
      }
    }
    return null;
  }

  CourseDetail withLessonSupplements({
    required Map<String, List<LessonQuiz>> quizzesByLesson,
    required Map<String, List<LessonResource>> resourcesByLesson,
  }) {
    return CourseDetail(
      course: course,
      sections: sections.map((section) {
        return section.copyWith(
          lessons: section.lessons.map((lesson) {
            return lesson.copyWith(
              quizzes: quizzesByLesson[lesson.id] ?? const [],
              resources: resourcesByLesson[lesson.id] ?? const [],
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  factory CourseDetail.fromCourse(Course course) {
    return CourseDetail(course: course, sections: const []);
  }

  factory CourseDetail.fromJson(Map<String, dynamic> json) {
    final sectionsRaw = json['sections'];
    final sections = sectionsRaw is List
        ? sectionsRaw
              .whereType<Map>()
              .map((row) => CourseSection.fromJson(row.cast<String, dynamic>()))
              .toList()
        : <CourseSection>[];
    sections.sort((a, b) => a.position.compareTo(b.position));
    final lessonCount = sections.fold(
      0,
      (count, section) => count + section.lessons.length,
    );
    return CourseDetail(
      course: Course.fromJson(json).copyWith(lessonCount: lessonCount),
      sections: sections,
    );
  }
}

class CourseSection {
  CourseSection({
    required this.id,
    required this.title,
    required this.position,
    required this.lessons,
  });

  final String id;
  final String title;
  final int position;
  final List<Lesson> lessons;

  CourseSection copyWith({List<Lesson>? lessons}) {
    return CourseSection(
      id: id,
      title: title,
      position: position,
      lessons: lessons ?? this.lessons,
    );
  }

  factory CourseSection.fromJson(Map<String, dynamic> json) {
    final lessonsRaw = json['lessons'];
    final lessons = lessonsRaw is List
        ? lessonsRaw
              .whereType<Map>()
              .map((row) => Lesson.fromJson(row.cast<String, dynamic>()))
              .toList()
        : <Lesson>[];
    lessons.sort((a, b) => a.position.compareTo(b.position));
    return CourseSection(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Section',
      position: _asInt(json['position']),
      lessons: lessons,
    );
  }
}

class Lesson {
  const Lesson({
    required this.id,
    required this.courseId,
    required this.sectionId,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.durationSeconds,
    required this.position,
    required this.isPreview,
    required this.bunnyVideoGuid,
    required this.videoUrl,
    required this.content,
    required this.videoCompletionThreshold,
    required this.quizRequiredForCompletion,
    required this.showQuizBeforeCompletion,
    required this.showResourcesBeforeCompletion,
    required this.quizzes,
    required this.resources,
  });

  final String id;
  final String courseId;
  final String sectionId;
  final String title;
  final String description;
  final int durationMinutes;
  final int durationSeconds;
  final int position;
  final bool isPreview;
  final String bunnyVideoGuid;
  final String videoUrl;
  final String content;
  final int videoCompletionThreshold;
  final bool quizRequiredForCompletion;
  final bool showQuizBeforeCompletion;
  final bool showResourcesBeforeCompletion;
  final List<LessonQuiz> quizzes;
  final List<LessonResource> resources;

  bool get hasVideo => bunnyVideoGuid.isNotEmpty || videoUrl.isNotEmpty;

  String get durationLabel {
    final minutes = durationSeconds > 0
        ? (durationSeconds / 60).round()
        : durationMinutes;
    return minutes <= 0 ? 'Lesson' : '$minutes min';
  }

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['id']?.toString() ?? '',
      courseId: json['course_id']?.toString() ?? '',
      sectionId: json['section_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Lesson',
      description: json['description']?.toString() ?? '',
      durationMinutes: _asInt(json['duration_minutes']),
      durationSeconds: _asInt(json['duration_seconds']),
      position: _asInt(json['position']),
      isPreview: json['is_preview'] == true,
      bunnyVideoGuid: json['bunny_video_guid']?.toString() ?? '',
      videoUrl: json['video_url']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      videoCompletionThreshold: _asInt(json['video_completion_threshold']),
      quizRequiredForCompletion: json['quiz_required_for_completion'] == true,
      showQuizBeforeCompletion: json['show_quiz_before_completion'] == true,
      showResourcesBeforeCompletion:
          json['show_resources_before_completion'] != false,
      quizzes: const [],
      resources: const [],
    );
  }

  factory Lesson.empty(String courseId) {
    return Lesson(
      id: '',
      courseId: courseId,
      sectionId: '',
      title: 'Lesson',
      description: '',
      durationMinutes: 0,
      durationSeconds: 0,
      position: 0,
      isPreview: false,
      bunnyVideoGuid: '',
      videoUrl: '',
      content: '',
      videoCompletionThreshold: 90,
      quizRequiredForCompletion: false,
      showQuizBeforeCompletion: false,
      showResourcesBeforeCompletion: true,
      quizzes: const [],
      resources: const [],
    );
  }

  Lesson copyWith({
    List<LessonQuiz>? quizzes,
    List<LessonResource>? resources,
  }) {
    return Lesson(
      id: id,
      courseId: courseId,
      sectionId: sectionId,
      title: title,
      description: description,
      durationMinutes: durationMinutes,
      durationSeconds: durationSeconds,
      position: position,
      isPreview: isPreview,
      bunnyVideoGuid: bunnyVideoGuid,
      videoUrl: videoUrl,
      content: content,
      videoCompletionThreshold: videoCompletionThreshold,
      quizRequiredForCompletion: quizRequiredForCompletion,
      showQuizBeforeCompletion: showQuizBeforeCompletion,
      showResourcesBeforeCompletion: showResourcesBeforeCompletion,
      quizzes: quizzes ?? this.quizzes,
      resources: resources ?? this.resources,
    );
  }
}

class LessonQuiz {
  const LessonQuiz({
    required this.id,
    required this.lessonId,
    required this.courseId,
    required this.title,
    required this.description,
    required this.passingScore,
    required this.maxAttempts,
    required this.timeLimitMinutes,
    required this.showCorrectAnswers,
    required this.questions,
  });

  final String id;
  final String lessonId;
  final String courseId;
  final String title;
  final String description;
  final int passingScore;
  final int maxAttempts;
  final int timeLimitMinutes;
  final bool showCorrectAnswers;
  final List<QuizQuestion> questions;

  factory LessonQuiz.fromJson(
    Map<String, dynamic> json,
    List<QuizQuestion> questions,
  ) {
    return LessonQuiz(
      id: json['id']?.toString() ?? '',
      lessonId: json['lesson_id']?.toString() ?? '',
      courseId: json['course_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Quiz',
      description: json['description']?.toString() ?? '',
      passingScore: _asInt(json['passing_score']),
      maxAttempts: _asInt(json['max_attempts']),
      timeLimitMinutes: _asInt(json['time_limit_minutes']),
      showCorrectAnswers: json['show_correct_answers'] != false,
      questions: questions,
    );
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.quizId,
    required this.question,
    required this.type,
    required this.options,
    required this.correctAnswerIndexes,
    required this.position,
    required this.points,
    required this.explanation,
  });

  final String id;
  final String quizId;
  final String question;
  final String type;
  final List<String> options;
  final Set<int> correctAnswerIndexes;
  final int position;
  final int points;
  final String explanation;

  bool get isMultipleAnswer => correctAnswerIndexes.length > 1;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      quizId: json['quiz_id']?.toString() ?? '',
      question: json['question']?.toString() ?? 'Question',
      type: json['type']?.toString() ?? 'multiple_choice',
      options: _asStringList(json['options']),
      correctAnswerIndexes: _asIntList(json['correct_answers']).toSet(),
      position: _asInt(json['position']),
      points: _asInt(json['points']),
      explanation: json['explanation']?.toString() ?? '',
    );
  }
}

class LessonResource {
  const LessonResource({
    required this.id,
    required this.lessonId,
    required this.title,
    required this.url,
    required this.fileType,
    required this.kind,
    required this.position,
  });

  final String id;
  final String lessonId;
  final String title;
  final String url;
  final String fileType;
  final String kind;
  final int position;

  String get fileTypeLabel {
    final value = fileType.isNotEmpty ? fileType : kind;
    return value.isEmpty ? 'Resource' : value.toUpperCase();
  }

  factory LessonResource.fromJson(Map<String, dynamic> json) {
    final title =
        json['title']?.toString() ??
        json['file_name']?.toString() ??
        'Resource';
    return LessonResource(
      id: json['id']?.toString() ?? '',
      lessonId: json['lesson_id']?.toString() ?? '',
      title: title,
      url: json['url']?.toString() ?? json['file_url']?.toString() ?? '',
      fileType: json['file_type']?.toString() ?? '',
      kind: json['kind']?.toString() ?? '',
      position: _asInt(json['position']),
    );
  }
}

class CertificateResult {
  const CertificateResult({
    required this.number,
    required this.issuedAt,
    required this.holderName,
    required this.courseTitle,
  });

  final String number;
  final DateTime? issuedAt;
  final String? holderName;
  final String? courseTitle;
}

class CourseCard extends StatelessWidget {
  const CourseCard({required this.course, required this.onTap, super.key});

  final Course course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 8.8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    _NetworkImageOrBrand(url: course.thumbnailUrl),
                    if (course.category != null)
                      Positioned(
                        left: 12,
                        top: 12,
                        child: _Pill(
                          text: course.category!.name,
                          color: _brandTealDark,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    if (course.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        course.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _mutedInk,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SmallMeta(
                          icon: Icons.play_lesson_outlined,
                          label: '${course.lessonCount} lessons',
                        ),
                        _SmallMeta(
                          icon: Icons.timer_outlined,
                          label: course.durationLabel,
                        ),
                        _SmallMeta(
                          icon: Icons.bar_chart_rounded,
                          label: course.levelLabel,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.courseCount, required this.onBrowse});

  final int courseCount;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: Colors.white,
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12142333),
            blurRadius: 24,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Pill(text: '100% Free Learning Platform', color: _brandTeal),
          const SizedBox(height: 16),
          const Text(
            'Master investing in the Nepali stock market',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              height: 1.02,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Structured courses on stocks, mutual funds, technical analysis, banking, and personal finance for Nepali learners.',
            style: TextStyle(color: _mutedInk, fontSize: 15, height: 1.45),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: onBrowse,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Browse courses'),
                ),
              ),
              const SizedBox(width: 12),
              const _BrandMark(size: 54),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              _HeroStat(value: '$courseCount+', label: 'Courses'),
              const SizedBox(width: 18),
              const _HeroStat(value: '100%', label: 'Free access'),
              const SizedBox(width: 18),
              const _HeroStat(value: 'Certs', label: 'Completion'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    final features = [
      (Icons.play_circle_outline_rounded, 'Video Lessons'),
      (Icons.workspace_premium_outlined, 'Certificates'),
      (Icons.quiz_outlined, 'Quizzes'),
      (Icons.forum_outlined, 'Q&A'),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: features.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 2.35,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final item = features[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(radius: 16),
          child: Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: _brandTeal.withAlpha(24),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.$1, color: _brandTealDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.$2,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryWrap extends StatelessWidget {
  const _CategoryWrap({required this.categories});

  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const _EmptyState(
        icon: Icons.category_outlined,
        title: 'No categories yet',
        message: 'Categories from the admin panel will appear here.',
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: categories.map((category) {
        return Container(
          width: MediaQuery.sizeOf(context).width >= 430 ? 190 : null,
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(radius: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              if (category.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  category.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: _mutedInk, fontSize: 12),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.section, required this.onLessonTap});

  final CourseSection section;
  final ValueChanged<Lesson> onLessonTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                _Pill(
                  text: 'Section ${section.position + 1}',
                  color: _brandGold,
                  foreground: _brandInk,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    section.title,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _line),
          ...section.lessons.map(
            (lesson) => ListTile(
              onTap: () => onLessonTap(lesson),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: _brandTeal.withAlpha(24),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: _brandTealDark,
                ),
              ),
              title: Text(
                lesson.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(lesson.durationLabel),
              trailing: lesson.isPreview
                  ? const _Pill(text: 'Preview', color: _brandTeal)
                  : const Icon(Icons.chevron_right_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseHeroImage extends StatelessWidget {
  const _CourseHeroImage({required this.course});

  final Course course;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _NetworkImageOrBrand(url: course.thumbnailUrl),
      ),
    );
  }
}

class _NetworkImageOrBrand extends StatelessWidget {
  const _NetworkImageOrBrand({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return const ColoredBox(
        color: Color(0xFFEAF4F2),
        child: Center(child: _BrandMark(size: 74)),
      );
    }
    return Image.network(
      url,
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final total = progress.expectedTotalBytes;
        final loaded = progress.cumulativeBytesLoaded;
        return ColoredBox(
          color: const Color(0xFFEAF4F2),
          child: Center(
            child: SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: total == null ? null : loaded / total,
              ),
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: Color(0xFFEAF4F2),
        child: Center(child: _BrandMark(size: 74)),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  const _CertificateCard({required this.result});

  final CertificateResult result;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 20).copyWith(
        border: Border.all(color: _brandTeal.withAlpha(120), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.verified_rounded, color: _brandTealDark, size: 30),
              SizedBox(width: 10),
              Text(
                'Verified certificate',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _InfoLine(label: 'Certificate no.', value: result.number),
          if (result.holderName != null)
            _InfoLine(label: 'Student', value: result.holderName!),
          if (result.courseTitle != null)
            _InfoLine(label: 'Course', value: result.courseTitle!),
          if (result.issuedAt != null)
            _InfoLine(label: 'Issued', value: _formatDate(result.issuedAt!)),
        ],
      ),
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({required this.email, required this.onSignOut});

  final String email;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BrandMark(size: 64),
          const SizedBox(height: 14),
          const Text(
            'Signed in',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(email, style: const TextStyle(color: _mutedInk)),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: onSignOut,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: const [
        _BrandMark(size: 38),
        SizedBox(width: 10),
        Flexible(
          child: Text(
            'Merolagani Academy',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
      ],
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CustomPaint(painter: _BrandMarkPainter()),
    );
  }
}

class _BrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final teal = Paint()
      ..color = _brandTeal
      ..style = PaintingStyle.fill;
    final gold = Paint()
      ..color = _brandGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final bg = Paint()..color = Colors.white;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(size.width * 0.22),
      ),
      bg,
    );

    final base = size.height * 0.78;
    final barWidth = size.width * 0.13;
    for (var i = 0; i < 3; i += 1) {
      final left = size.width * (0.23 + i * 0.18);
      final top = base - size.height * (0.22 + i * 0.12);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, base - top),
          Radius.circular(size.width * 0.025),
        ),
        teal,
      );
    }

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.52)
      ..lineTo(size.width * 0.39, size.height * 0.38)
      ..lineTo(size.width * 0.53, size.height * 0.44)
      ..lineTo(size.width * 0.79, size.height * 0.24);
    canvas.drawPath(path, gold);
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.79, size.height * 0.24)
        ..lineTo(size.width * 0.77, size.height * 0.4)
        ..moveTo(size.width * 0.79, size.height * 0.24)
        ..lineTo(size.width * 0.63, size.height * 0.27),
      gold,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScreenIntro extends StatelessWidget {
  const _ScreenIntro({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 22),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: _brandTeal.withAlpha(24),
            child: Icon(icon, color: _brandTealDark),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: _mutedInk, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(subtitle, style: const TextStyle(color: _mutedInk)),
            ],
          ),
        ),
        ?trailing,
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _CalloutPanel extends StatelessWidget {
  const _CalloutPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _brandTealDark,
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Start your learning journey today',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Gain practical financial knowledge built for Nepali learners.',
            style: TextStyle(color: Color(0xDDFFFFFF), height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _brandTealDark, size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(message, style: const TextStyle(color: _mutedInk, height: 1.4)),
          const SizedBox(height: 16),
          FilledButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}

class _ProgressSummaryCard extends StatelessWidget {
  const _ProgressSummaryCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _brandTealDark),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: _mutedInk, fontSize: 12)),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.text,
    required this.color,
    this.foreground = Colors.white,
  });

  final String text;
  final Color color;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: _brandTealDark, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _SmallMeta extends StatelessWidget {
  const _SmallMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _mutedInk),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: _mutedInk, fontSize: 12)),
      ],
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: _brandTealDark,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(label, style: const TextStyle(color: _mutedInk, fontSize: 12)),
        ],
      ),
    );
  }
}

class _DetailHeading extends StatelessWidget {
  const _DetailHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _CheckLine extends StatelessWidget {
  const _CheckLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: _brandTealDark,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontWeight: FontWeight.w900)),
          Expanded(child: Text(text, style: const TextStyle(height: 1.35))),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: _mutedInk, fontSize: 12)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF4F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFD5CE)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFB42318)),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: _cardDecoration(radius: 18),
      child: Column(
        children: [
          Icon(icon, color: _mutedInk, size: 36),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _mutedInk, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(radius: 18),
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

class _CourseSkeletonList extends StatelessWidget {
  const _CourseSkeletonList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        2,
        (index) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 190,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _line),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ),
    );
  }
}

BoxDecoration _cardDecoration({double radius = 18}) {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: _line),
    boxShadow: const [
      BoxShadow(color: Color(0x08142333), blurRadius: 16, offset: Offset(0, 8)),
    ],
  );
}

Future<void> _openExternal(Uri uri) async {
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

int _asInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

List<String> _asStringList(Object? value) {
  if (value is List) {
    return value
        .map((item) => item.toString())
        .where((item) => item.isNotEmpty)
        .toList();
  }
  return const [];
}

List<int> _asIntList(Object? value) {
  if (value is List) {
    return value.map(_asInt).where((item) => item >= 0).toList();
  }
  return const [];
}

String _formatDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}, ${value.year}';
}
