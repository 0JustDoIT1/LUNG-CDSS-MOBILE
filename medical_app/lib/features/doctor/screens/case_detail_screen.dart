import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../models/review_case.dart';
import 'case_review_history_screen.dart';
import 'widgets/case_review_actions.dart';

/// AI 결과 상세뷰.
///
/// 상단 "이미지 / 소견" 탭으로 크게 나뉜다.
/// - 이미지 탭: 히트맵/오버레이/원본 전환, 확대축소 버튼, 오버레이 강도, 주석/드로잉 컨트롤
/// - 소견 탭: 확률 요약, 유전자확률, AI소견(MedGemma 초안)
///
/// TODO: 실제 이미지 API 붙으면 placeholder를 Image.network로 교체.
/// TODO: 주석/드로잉은 컨트롤 UI만 있고, 실제 캔버스에 그리는 기능은 다음 단계에서.
/// TODO: 승인/반려 버튼은 다음 단계에서 추가.
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
            onPressed: () {
              setState(() => _isFavorite = !_isFavorite);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _isFavorite ? '즐겨찾기에 추가했어요' : '즐겨찾기에서 제거했어요',
                  ),
                  duration: const Duration(seconds: 1),
                ),
              );
              // TODO: CaseFavorite 토글 API 연결, 홈화면 즐겨찾기카드와 연동
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
                  ? _ImageTabView(reviewCase: c)
                  : _OpinionTabView(reviewCase: c),
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
        Expanded(child: _tabButton('이미지', _MainTab.image)),
        const SizedBox(width: 8),
        Expanded(child: _tabButton('소견', _MainTab.opinion)),
      ],
    );
  }

  Widget _tabButton(String label, _MainTab tab) {
    final isSelected = selected == tab;
    return GestureDetector(
      onTap: () => onChanged(tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
        color: isSelected ? AppTheme.gradientEnd : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(24),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
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

  const _ImageTabView({required this.reviewCase});

  @override
  State<_ImageTabView> createState() => _ImageTabViewState();
}

class _ImageTabViewState extends State<_ImageTabView> {
  _ViewMode _mode = _ViewMode.heatmap;
  double _overlayIntensity = 0.65;
  bool _annotationOn = false;
  Color _selectedColor = Colors.red;
  double _strokeWidth = 4;
  final TransformationController _transformController =
      TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    final matrix = _transformController.value.clone();
    matrix.scale(factor);
    setState(() => _transformController.value = matrix);
  }

  void _resetZoom() {
    setState(() => _transformController.value = Matrix4.identity());
  }

  Color get _placeholderColor => switch (_mode) {
        _ViewMode.heatmap => Colors.deepOrange.shade200,
        _ViewMode.overlay => Colors.purple.shade200,
        _ViewMode.original => Colors.grey.shade300,
      };

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
                  // 실제 슬라이드 이미지 붙기 전까지는 색상 placeholder만 확인.
                  child: InteractiveViewer(
                    transformationController: _transformController,
                    minScale: 1,
                    maxScale: 5,
                    child: Container(
                      color: _placeholderColor,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: Colors.black38,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '핀치줌·드래그로 이동',
                            style: TextStyle(
                              color: Colors.black45,
                              fontSize: 12,
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
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.layers_outlined, size: 18),
              const SizedBox(width: 6),
              const Text('오버레이 강도'),
              Expanded(
                child: Slider(
                  value: _overlayIntensity,
                  onChanged: (v) => setState(() => _overlayIntensity = v),
                ),
              ),
              Text('${(_overlayIntensity * 100).round()}%'),
            ],
          ),
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
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _mode = mode),
      selectedColor: AppTheme.gradientEnd,
      labelStyle: TextStyle(color: selected ? Colors.white : Colors.black87),
      backgroundColor: Colors.grey.shade100,
      side: BorderSide.none,
    );
  }

  Widget _zoomButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white,
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
    return IconButton.filled(
      onPressed: () => setState(() => _annotationOn = !_annotationOn),
      style: IconButton.styleFrom(
        backgroundColor: _annotationOn ? AppTheme.gradientEnd : Colors.grey.shade200,
      ),
      icon: Icon(
        Icons.edit,
        color: _annotationOn ? Colors.white : Colors.black54,
      ),
    );
  }

  Widget _eraserButton() {
    return IconButton(
      onPressed: () {
        // TODO: 지우기 기능 (드로잉 캔버스 붙을 때 연결)
      },
      icon: const Icon(Icons.auto_fix_normal_outlined),
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
          border: selected ? Border.all(width: 2, color: Colors.black) : null,
        ),
      ),
    );
  }
}

class _OpinionTabView extends StatelessWidget {
  final ReviewCase reviewCase;

  const _OpinionTabView({required this.reviewCase});

  @override
  Widget build(BuildContext context) {
    final c = reviewCase;

    return ListView(
      children: [
        _PredictedTypeCard(reviewCase: c),
        const SizedBox(height: 16),
        _TypeProbabilityBar(reviewCase: c),
        const SizedBox(height: 24),
        const Text('유전자변이 확률', style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        _GenePredictionList(genePredictions: c.genePredictions),
        const SizedBox(height: 24),
        const Text('AI 소견 초안',
            style: TextStyle(fontSize: 12, color: Colors.black54)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(c.aiOpinion),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PredictedTypeCard extends StatelessWidget {
  final ReviewCase reviewCase;

  const _PredictedTypeCard({required this.reviewCase});

  @override
  Widget build(BuildContext context) {
    final percent = (reviewCase.confidence * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('AI 예측 조직형',
              style: TextStyle(fontSize: 13, color: Colors.black54)),
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
                  child: Container(color: Colors.grey.shade300),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _GenePredictionList extends StatelessWidget {
  final Map<String, double> genePredictions;

  const _GenePredictionList({required this.genePredictions});

  @override
  Widget build(BuildContext context) {
    if (genePredictions.isEmpty) {
      return const Text('유전자 예측 데이터 없음');
    }

    final entries = genePredictions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topKey = entries.first.key;

    return Column(
      children: entries.map((entry) {
        final percent = (entry.value * 100).round();
        final isTop = entry.key == topKey;
        final barColor = isTop ? Colors.blue.shade600 : Colors.grey.shade400;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontWeight: isTop ? FontWeight.bold : FontWeight.w500,
                    color: isTop ? Colors.blue.shade700 : Colors.black87,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: entry.value,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(barColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '$percent%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: isTop ? FontWeight.bold : FontWeight.normal,
                    color: isTop ? Colors.blue.shade700 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}