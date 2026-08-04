import 'package:flutter/material.dart';

class PatientQrScreen extends StatelessWidget {
  const PatientQrScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('진료카드 QR'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Text(
                '진료 접수 시 QR을 보여주세요',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                '병원에서 환자 정보를 빠르게 확인할 수 있습니다.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 32),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.grey.shade200,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.05,
                      ),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 220,
                      height: 220,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.grey.shade300,
                        ),
                      ),
                      child: const _MockQrCode(),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '이대박',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '환자번호 2026080301',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Theme.of(context)
                          .colorScheme
                          .primary,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'QR에는 환자 식별을 위한 임시 정보만 포함되며, 일정 시간이 지나면 새로 갱신됩니다.',
                        style: TextStyle(
                          height: 1.5,
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
    );
  }
}

class _MockQrCode extends StatelessWidget {
  const _MockQrCode();

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 21 * 21,
      gridDelegate:
          const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 21,
      ),
      itemBuilder: (context, index) {
        final row = index ~/ 21;
        final column = index % 21;

        final isFinderPattern =
            _isFinderPattern(row, column);

        final isFilled = isFinderPattern ||
            ((row * 7 + column * 3 + row * column) % 5 == 0);

        return Container(
          color: isFilled
              ? Colors.black
              : Colors.white,
        );
      },
    );
  }

  bool _isFinderPattern(int row, int column) {
    return _inPattern(row, column, 0, 0) ||
        _inPattern(row, column, 0, 14) ||
        _inPattern(row, column, 14, 0);
  }

  bool _inPattern(
    int row,
    int column,
    int startRow,
    int startColumn,
  ) {
    final localRow = row - startRow;
    final localColumn = column - startColumn;

    if (localRow < 0 ||
        localRow > 6 ||
        localColumn < 0 ||
        localColumn > 6) {
      return false;
    }

    final isOuterBorder = localRow == 0 ||
        localRow == 6 ||
        localColumn == 0 ||
        localColumn == 6;

    final isCenter = localRow >= 2 &&
        localRow <= 4 &&
        localColumn >= 2 &&
        localColumn <= 4;

    return isOuterBorder || isCenter;
  }
}