import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/auth_api.dart';
import '../../../core/api/cases_api.dart';
import '../../../core/auth/session_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../models/review_case.dart';
import 'case_review_history_screen.dart';
import 'widgets/case_review_actions.dart';

/// 드로잉 한 획(스트로크) — 연속된 좌표 목록 + 스타일. 한 번의 터치-드래그-떼기가 하나의 스트로크.
class DrawingStroke {
  final List<Offset> points;
  final Paint paint;

  DrawingStroke({required this.points, required this.paint});
}

/// AI 결과 상세뷰
class CaseDetailScreen extends StatefulWidget {
  final ReviewCase reviewCase;

  const CaseDetailScreen({super.key, required this.reviewCase});

  @override
  State<CaseDetailScreen> createState() => _CaseDetailScreenState();
}

enum _MainTab { image, opinion }

class _CaseDetailScreenState extends State<CaseDetailScreen> {
  _MainTab _mainTab = _MainTab.image;
  late bool _isFavorite = widget.reviewCase.isFavorite;

  ReviewCase? _detail;
  bool _isLoadingDetail = true;
  String? _detailErrorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoadingDetail = true;
      _detailErrorMessage = null;
    });

    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    try {
      final detail = await fetchCaseDetail(widget.reviewCase.id, token);
      if (!mounted) return;
      setState(() => _detail = detail);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _detailErrorMessage = e.message);
    } finally {
      if (mounted) setState(() => _isLoadingDetail = false);
    }
  }

  Future<void> _toggleFavorite() async {
    final token = context.read<SessionController>().accessToken;
    setState(() => _isFavorite = !_isFavorite);
    if (token == null) return;
    try {
      await toggleCaseFavorite(widget.reviewCase.id, token);
    } on ApiException catch (_) {
      if (!mounted) return;
      setState(() => _isFavorite = !_isFavorite);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.reviewCase;

    return Scaffold(
      appBar: AppBar(
        title: Text('${c.patientName} · 조직검사'),
        actions: [
          IconButton(
            tooltip: _isFavorite ? '즐겨찾기 해제' : '즐겨찾기 추가',
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? Colors.amber : null,
            ),
            onPressed: () async {
              final wasFavorite = _isFavorite;
              await _toggleFavorite();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    !wasFavorite ? '즐겨찾기에 추가했어요' : '즐겨찾기에서 제거했어요',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          IconButton(
            tooltip: '검토 이력',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CaseReviewHistoryScreen(reviewCase: c),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: CaseReviewActionBar(reviewCase: c),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MainTabToggle(
              selected: _mainTab,
              onChanged: (t) => setState(() => _mainTab = t),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _mainTab == _MainTab.image
                  ? _ImageTabView(
                      reviewCase: c,
                      detail: _detail,
                      isLoading: _isLoadingDetail,
                      errorMessage: _detailErrorMessage,
                      onRetry: _loadDetail,
                    )
                  : _OpinionTabView(
                      reviewCase: c,
                      detail: _detail,
                      isLoading: _isLoadingDetail,
                      errorMessage: _detailErrorMessage,
                      onRetry: _loadDetail,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainTabToggle extends StatelessWidget {
  final _MainTab selected;
  final ValueChanged<_MainTab> onChanged;

  const _MainTabToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _tabButton(context, '이미지', _MainTab.image)),
        const SizedBox(width: 8),
        Expanded(child: _tabButton(context, '소견', _MainTab.opinion)),
      ],
    );
  }

  Widget _tabButton(BuildContext context, String label, _MainTab tab) {
    final isSelected = selected == tab;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onChanged(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.gradientEnd : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

enum _ViewMode { heatmap, overlay, original }

class _ImageTabView extends StatefulWidget {
  final ReviewCase reviewCase;
  final ReviewCase? detail; // slide_thumbnail_url/heatmap_url 포함된 상세조회 결과
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _ImageTabView({
    required this.reviewCase,
    required this.detail,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  State<_ImageTabView> createState() => _ImageTabViewState();
}

class _ImageTabViewState extends State<_ImageTabView> {
  _ViewMode _mode = _ViewMode.heatmap;
  double _overlayIntensity = 0.65;
  bool _annotationOn = false;
  Color _selectedColor = Colors.red;
  double _strokeWidth = 4;

  // 히트맵/오버레이/원본 각각 독립된 드로잉 — 한쪽에 그린 게 다른 모드엔 안 보임.
  final Map<_ViewMode, List<DrawingStroke>> _strokesByMode = {
    for (final m in _ViewMode.values) m: <DrawingStroke>[],
  };

  bool _originalReady = false;
  bool _heatmapReady = false;

  final TransformationController _transformController =
      TransformationController();

  @override
  void didUpdateWidget(covariant _ImageTabView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail == null && widget.detail != null) {
      _precacheImages();
    }
    // 상세 재조회(재시도/새로고침)가 다시 시작되면, 이전에 로딩됐던 이미지 기준으로
    // 드로잉이 계속 켜져있는 상태가 남지 않도록 초기화.
    if (!oldWidget.isLoading && widget.isLoading) {
      _annotationOn = false;
      _originalReady = false;
      _heatmapReady = false;
    }
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  /// 상세조회로 이미지 URL이 확정되는 즉시 원본/히트맵을 미리 캐시에 올려서,
  /// 사용자가 탭을 눌러 모드를 바꿀 때 바로 뜨도록 함(체감 로딩속도 개선).
  void _precacheImages() {
    final detail = widget.detail;
    if (detail == null) return;
    final original = detail.slideThumbnailUrl;
    final heatmap = detail.heatmapUrl;
    if (original != null && original.isNotEmpty) {
      precacheImage(NetworkImage(original), context);
    }
    if (heatmap != null && heatmap.isNotEmpty) {
      precacheImage(NetworkImage(heatmap), context);
    }
  }

  void _markOriginalReady() {
    if (!mounted || _originalReady) return;
    setState(() => _originalReady = true);
  }

  void _markHeatmapReady() {
    if (!mounted || _heatmapReady) return;
    setState(() => _heatmapReady = true);
  }

  /// 현재 모드에 필요한 이미지가 전부 로딩됐는지 — 로딩 끝나기 전엔 드로잉을 막음.
  bool get _currentImagesReady => switch (_mode) {
        _ViewMode.original => _originalReady,
        _ViewMode.heatmap => _heatmapReady,
        _ViewMode.overlay => _originalReady && _heatmapReady,
      };

  // InteractiveViewer의 minScale과 동일한 하한 — 핀치줌은 이미 1배 밑으로 안 줄어드는데
  // +/- 버튼은 매트릭스를 직접 조작해서 이 제한을 타지 않아 끝없이 작아지는 문제가 있었음.
  static const double _minZoomScale = 1.0;

  void _zoom(double factor) {
    final matrix = _transformController.value.clone();
    final currentScale = matrix.getMaxScaleOnAxis();
    final targetScale = currentScale * factor;
    if (targetScale < _minZoomScale) {
      // 축소 시 1배 밑으로 못 내려가게 — 그 이하로는 원본 크기로 고정.
      setState(() => _transformController.value = Matrix4.identity());
      return;
    }
    matrix.scaleByDouble(factor, factor, factor, 1.0);
    setState(() => _transformController.value = matrix);
  }

  void _resetZoom() {
    setState(() => _transformController.value = Matrix4.identity());
  }

  void _undoLastStroke() {
    setState(() {
      final strokes = _strokesByMode[_mode]!;
      if (strokes.isNotEmpty) strokes.removeLast();
    });
  }

  Widget _placeholder(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_outlined, size: 48, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _networkImage(String? url, {VoidCallback? onReady}) {
    if (url == null || url.isEmpty) return _placeholder('이미지가 없어요');
    return Image.network(
      url,
      fit: BoxFit.contain,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator());
      },
      // frameBuilder는 "실제로 화면에 그릴 픽셀이 준비됐는지"를 알려주는 더 확실한 신호라
      // 이걸 기준으로 드로잉 가능 여부(onReady)를 판단함 — loadingBuilder만으론
      // 캐시/타이밍에 따라 실제 그림이 뜨기 전에 준비완료로 잘못 판단할 수 있음.
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if ((frame != null || wasSynchronouslyLoaded) && onReady != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onReady());
        }
        return child;
      },
      errorBuilder: (context, error, stack) {
        // 로딩 실패해도 "로딩 대기" 상태에 영영 걸려있지 않도록 완료 처리.
        if (onReady != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) => onReady());
        }
        return _placeholder('이미지를 불러오지 못했어요');
      },
    );
  }

  /// 히트맵/오버레이/원본 모드에 맞는 이미지 배경 레이어.
  /// 오버레이는 원본 위에 히트맵을 겹치고 _overlayIntensity로 히트맵 투명도를 조절.
  Widget _buildImageLayer() {
    if (widget.isLoading) return const Center(child: CircularProgressIndicator());
    if (widget.errorMessage != null) return _placeholder(widget.errorMessage!);

    final detail = widget.detail;
    if (detail == null) return _placeholder('이미지를 불러오지 못했어요');

    return switch (_mode) {
      _ViewMode.original => _networkImage(detail.slideThumbnailUrl, onReady: _markOriginalReady),
      _ViewMode.heatmap => _networkImage(detail.heatmapUrl, onReady: _markHeatmapReady),
      _ViewMode.overlay => Stack(
          fit: StackFit.expand,
          children: [
            _networkImage(detail.slideThumbnailUrl, onReady: _markOriginalReady),
            Opacity(
              opacity: _overlayIntensity,
              child: _networkImage(detail.heatmapUrl, onReady: _markHeatmapReady),
            ),
          ],
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              _modeChip('히트맵', _ViewMode.heatmap),
              _modeChip('오버레이', _ViewMode.overlay),
              _modeChip('원본', _ViewMode.original),
            ],
          ),
          const SizedBox(height: 12),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: InteractiveViewer(
                    // 드로잉 모드일 때는 InteractiveViewer의 터치 이동(Pan)/확대(Scale)를 비활성화합니다.
                    panEnabled: !_annotationOn,
                    scaleEnabled: !_annotationOn,
                    transformationController: _transformController,
                    minScale: 1,
                    maxScale: 5,
                    child: SizedBox(
                      height: 280,
                      width: double.infinity,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // 1. 이미지 배경 레이어
                          _buildImageLayer(),

                          // 2. 드로잉 캔버스 레이어 (현재 모드에 그려진 스트로크만)
                          CustomPaint(
                            painter: _DrawingPainter(strokes: _strokesByMode[_mode]!),
                          ),

                          // 3. 터치 감지 전용 레이어. 드로잉 모드 + 현재 모드 이미지 로딩 완료 후에만 활성화
                          // — 이미지가 뜨기 전에 좌표가 어긋난 채로 그려지는 걸 막음.
                          if (_annotationOn && _currentImagesReady)
                            GestureDetector(
                              behavior: HitTestBehavior.opaque, // 투명 영역도 터치 강제 수신
                              onPanStart: (details) {
                                setState(() {
                                  _strokesByMode[_mode]!.add(
                                    DrawingStroke(
                                      points: [details.localPosition],
                                      paint: Paint()
                                        ..color = _selectedColor
                                        ..isAntiAlias = true
                                        ..strokeWidth = _strokeWidth
                                        ..strokeCap = StrokeCap.round,
                                    ),
                                  );
                                });
                              },
                              onPanUpdate: (details) {
                                setState(() {
                                  _strokesByMode[_mode]!.last.points.add(details.localPosition);
                                });
                              },
                            ),

                          // 4. 안내 캡션
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                              color: Colors.black.withValues(alpha: 0.45),
                              child: Text(
                                !_currentImagesReady
                                    ? '⏳ 이미지 로딩 중이에요'
                                    : _annotationOn
                                        ? '✏️ 드로잉 모드 (손가락으로 그려보세요)'
                                        : '🖐️ 핀치줌·드래그로 이동 (연필 클릭 시 드로잉)',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 11),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 12,
                child: Column(
                  children: [
                    _zoomButton(Icons.add, () => _zoom(1.2)),
                    const SizedBox(height: 6),
                    _zoomButton(Icons.remove, () => _zoom(0.8)),
                    const SizedBox(height: 6),
                    _zoomButton(Icons.center_focus_strong, _resetZoom),
                  ],
                ),
              ),
            ],
          ),
          if (_mode == _ViewMode.overlay) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.layers_outlined, size: 18),
                const SizedBox(width: 6),
                const Text('히트맵 투명도'),
                Expanded(
                  child: Slider(
                    value: _overlayIntensity,
                    onChanged: (v) => setState(() => _overlayIntensity = v),
                  ),
                ),
                Text('${(_overlayIntensity * 100).round()}%'),
              ],
            ),
          ],
          const SizedBox(height: 8),
          const Text('주석/드로잉', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(
            children: [
              _annotationToggleButton(),
              const SizedBox(width: 8),
              _eraserButton(),
              const SizedBox(width: 12),
              _colorDot(Colors.red),
              const SizedBox(width: 8),
              _colorDot(Colors.blue),
              const SizedBox(width: 8),
              _colorDot(Colors.orange),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('굵기'),
              Expanded(
                child: Slider(
                  value: _strokeWidth,
                  min: 1,
                  max: 12,
                  onChanged: (v) => setState(() => _strokeWidth = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _modeChip(String label, _ViewMode mode) {
    final selected = _mode == mode;
    final colorScheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() {
        _mode = mode;
        if (!_currentImagesReady) _annotationOn = false;
      }),
      selectedColor: AppTheme.gradientEnd,
      labelStyle: TextStyle(color: selected ? Colors.white : colorScheme.onSurface),
      backgroundColor: colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18),
        ),
      ),
    );
  }

  Widget _annotationToggleButton() {
    final colorScheme = Theme.of(context).colorScheme;
    final enabled = _currentImagesReady;
    // 켜져있는 것처럼 보이는 상태(파란 배경)는 실제로 그릴 수 있을 때(enabled)만 표시.
    final active = _annotationOn && enabled;
    return IconButton.filled(
      tooltip: enabled ? null : '이미지 로딩 중이에요',
      onPressed: enabled ? () => setState(() => _annotationOn = !_annotationOn) : null,
      style: IconButton.styleFrom(
        backgroundColor: active ? AppTheme.gradientEnd : colorScheme.surfaceContainerHighest,
      ),
      icon: Icon(
        Icons.edit,
        color: active ? Colors.white : colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _eraserButton() {
    final canUndo = _strokesByMode[_mode]!.isNotEmpty;
    return IconButton(
      tooltip: '방금 그린 획 취소',
      onPressed: canUndo ? _undoLastStroke : null,
      icon: const Icon(Icons.undo),
    );
  }

  Widget _colorDot(Color color) {
    final selected = _selectedColor == color;
    return GestureDetector(
      onTap: () => setState(() => _selectedColor = color),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(width: 2, color: Theme.of(context).colorScheme.onSurface)
              : null,
        ),
      ),
    );
  }
}

/// 캔버스에 스트로크를 그려주는 CustomPainter
class _DrawingPainter extends CustomPainter {
  final List<DrawingStroke> strokes;

  _DrawingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.length == 1) {
        // 단일 클릭(점) 처리 - drawCircle 이용 (PointMode 오류 방지)
        canvas.drawCircle(
          stroke.points.first,
          stroke.paint.strokeWidth / 2,
          stroke.paint..style = PaintingStyle.fill,
        );
        continue;
      }
      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], stroke.paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _OpinionTabView extends StatelessWidget {
  final ReviewCase reviewCase;
  final ReviewCase? detail; // gene_predictions/treatment_note 포함된 상세조회 결과
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  const _OpinionTabView({
    required this.reviewCase,
    required this.detail,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final c = reviewCase;
    final colorScheme = Theme.of(context).colorScheme;

    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null || detail == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              errorMessage ?? '소견을 불러오지 못했어요.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    final genePredictions = detail!.genePredictions;
    final treatmentNote = detail!.treatmentNote;

    return ListView(
      children: [
        _PredictedTypeCard(reviewCase: c),
        const SizedBox(height: 16),
        _TypeProbabilityBar(reviewCase: c),
        const SizedBox(height: 24),
        const Text('유전자변이 확률', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        if (genePredictions.isEmpty)
          Text('예측된 유전자변이가 없어요', style: TextStyle(color: colorScheme.onSurfaceVariant))
        else
          ...genePredictions.map((g) => _GenePredictionRow(prediction: g)),
        const SizedBox(height: 24),
        const Text('AI 소견', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            (treatmentNote == null || treatmentNote.isEmpty) ? 'AI 소견이 없어요.' : treatmentNote,
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _GenePredictionRow extends StatelessWidget {
  final GenePrediction prediction;

  const _GenePredictionRow({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final percent = (prediction.probability * 100).round();
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(prediction.gene, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: prediction.probability.clamp(0, 1),
                minHeight: 8,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: AppTheme.gradientEnd,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              '$percent%',
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _PredictedTypeCard extends StatelessWidget {
  final ReviewCase reviewCase;

  const _PredictedTypeCard({required this.reviewCase});

  @override
  Widget build(BuildContext context) {
    final percent = (reviewCase.confidence * 100).round();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text('AI 예측 조직형',
              style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Text(
            reviewCase.type.label,
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '확률 $percent%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeProbabilityBar extends StatelessWidget {
  final ReviewCase reviewCase;

  const _TypeProbabilityBar({required this.reviewCase});

  @override
  Widget build(BuildContext context) {
    final luadRatio =
        reviewCase.type == CaseType.luad ? reviewCase.confidence : 1 - reviewCase.confidence;
    final luadPercent = (luadRatio * 100).round();
    final luscPercent = 100 - luadPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('LUAD $luadPercent%',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('LUSC $luscPercent%',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 10,
            child: Row(
              children: [
                Expanded(
                  flex: luadPercent,
                  child: Container(color: Colors.blue.shade600),
                ),
                Expanded(
                  flex: luscPercent,
                  child: Container(color: Theme.of(context).colorScheme.surfaceContainerHighest),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}