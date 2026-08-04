import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('내 정보'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          20,
          16,
          20,
          32,
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: const Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  child: Icon(
                    Icons.person_outline_rounded,
                    size: 40,
                  ),
                ),
                SizedBox(height: 14),
                Text(
                  '이대박',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  '환자번호 2026080301',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: '기본 정보',
          ),
          const SizedBox(height: 10),
          const _InfoCard(
            children: [
              _InfoRow(
                label: '이름',
                value: '이대박',
              ),
              Divider(height: 1),
              _InfoRow(
                label: '생년월일',
                value: '2001.03.23',
              ),
              Divider(height: 1),
              _InfoRow(
                label: '연락처',
                value: '010-1234-5678',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionTitle(
            title: '병원 정보',
          ),
          const SizedBox(height: 10),
          const _InfoCard(
            children: [
              _InfoRow(
                label: '병원',
                value: '김호흡 의료원',
              ),
              Divider(height: 1),
              _InfoRow(
                label: '진료과',
                value: '호흡기내과',
              ),
              Divider(height: 1),
              _InfoRow(
                label: '담당 의료진',
                value: '김호흡 의사',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}