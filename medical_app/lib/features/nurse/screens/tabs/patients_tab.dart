import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/api/auth_api.dart';
import '../../../../core/api/medications_api.dart';
import '../../../../core/auth/session_controller.dart';
import '../../../../main.dart';
import '../../models/staff_patient.dart';
import '../nurse_patient_detail_screen.dart';

/// 탭 2: 담당환자 목록.
/// 환자 명단은 실제 API(GET /api/auth/staff/patients/) 기반.
/// 복약현황(오늘 복약 X/N)은 카드별로 GET /api/medications/logs/today/?patient_id= 조회.
/// 목록은 10초 폴링 + 포그라운드 푸시 수신 시 즉시 새로고침으로 자동 반영됨.
class NursePatientsTab extends StatefulWidget {
  const NursePatientsTab({super.key});

  @override
  State<NursePatientsTab> createState() => _NursePatientsTabState();
}

class _NursePatientsTabState extends State<NursePatientsTab> {
  List<StaffPatient> _patients = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _pollTimer;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _silentRefresh());
    fcmService.incomingMessage.addListener(_silentRefresh);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim());
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    fcmService.incomingMessage.removeListener(_silentRefresh);
    _searchController.dispose();
    super.dispose();
  }

  /// 폴링/푸시 수신 시 배경에서 조용히 새로고침 — 실패해도 기존 목록 유지, 로딩/에러 화면 안 건드림.
  Future<void> _silentRefresh() async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    try {
      final patients = await fetchStaffPatients(token);
      if (!mounted) return;
      setState(() => _patients = patients);
    } on ApiException catch (_) {
      // 조용히 무시
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;

    try {
      final patients = await fetchStaffPatients(token);
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            TextButton(onPressed: _load, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    final filteredPatients = _searchQuery.isEmpty
        ? _patients
        : _patients.where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return RefreshIndicator(
      onRefresh: _load,
      child: SafeArea(
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      '담당환자 목록',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF26B2C8).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '호흡기내과',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF26B2C8),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '총 ${_patients.length}명의 환자를 관리 중입니다',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            /// 로고 테마 색상이 반영된 환자 검색창 (터치 포커스 시 테테두리 강조)
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: '환자 이름으로 검색',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, size: 22, color: Color(0xFF26B2C8)),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.cancel_rounded, size: 18, color: Colors.grey),
                        onPressed: _searchController.clear,
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF26B2C8), width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (filteredPatients.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isEmpty ? '담당 환자가 없어요' : '검색 결과가 없어요',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...filteredPatients.map((p) {
                return _PatientCard(
                  patientId: p.id,
                  patientName: p.name,
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _PatientCard extends StatefulWidget {
  final String patientId;
  final String patientName;

  const _PatientCard({
    required this.patientId,
    required this.patientName,
  });

  @override
  State<_PatientCard> createState() => _PatientCardState();
}

class _PatientCardState extends State<_PatientCard> {
  List<MedicationLog>? _logs; // null이면 아직 로딩 중이거나 실패

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLogs());
  }

  Future<void> _loadLogs() async {
    final token = context.read<SessionController>().accessToken;
    if (token == null) return;
    try {
      final logs = await fetchTodayMedicationLogs(accessToken: token, patientId: widget.patientId);
      if (!mounted) return;
      setState(() => _logs = logs);
    } on ApiException catch (_) {
      // 카드 하나 실패는 조용히 무시 — "복약스케줄 미설정"처럼 보이는 것으로 충분
    }
  }

  bool get _hasSchedule => (_logs ?? const []).isNotEmpty;
  int get _takenCount => (_logs ?? const []).where((l) => l.taken).length;
  int get _totalCount => (_logs ?? const []).length;
  String get _subtitle =>
      _hasSchedule ? '오늘 복약 $_takenCount/$_totalCount 완료' : '복약스케줄 미설정';

  Color _subtitleColor(BuildContext context) {
    if (!_hasSchedule) return Theme.of(context).colorScheme.onSurfaceVariant;
    if (_takenCount == _totalCount) return const Color(0xFF26B2C8); // 로고 청록색
    return const Color(0xFFFF6B00); // 주의/미완료 오렌지
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allTaken = _hasSchedule && _takenCount == _totalCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => NursePatientDetailScreen(
                  patientId: widget.patientId,
                  patientName: widget.patientName,
                ),
              ),
            );
            _loadLogs(); // 상세화면에서 복약스케줄이 바뀌었을 수 있으니 새로고침
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                /// 환자 프로필 아바타 (로고 그라데이션 컨셉 반영)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: allTaken
                        ? const LinearGradient(
                            colors: [Color(0xFFE0F7FA), Color(0xFFE1F5FE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: allTaken ? null : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.patientName.isNotEmpty
                        ? widget.patientName.substring(0, 1)
                        : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: allTaken
                          ? const Color(0xFF26B2C8)
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                /// 환자 이름 + 복약 상태 정보
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.patientName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (_hasSchedule)
                            Container(
                              width: 6,
                              height: 6,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _subtitleColor(context),
                              ),
                            ),
                          Text(
                            _subtitle,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _subtitleColor(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}