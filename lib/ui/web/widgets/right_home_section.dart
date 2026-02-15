import 'package:flutter/material.dart';

class RightHomeSection extends StatelessWidget {
  const RightHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.grey[300]!)),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Attendance Dashboard',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          _AttendanceButton(
            label: 'Clock In',
            onPressed: () => _handleClockIn(context),
            primary: true,
          ),
          const SizedBox(height: 12),
          _AttendanceButton(
            label: 'Clock Out',
            onPressed: () => _handleClockOut(context),
            primary: false,
          ),
          const SizedBox(height: 24),
          const _StatusCard(
            title: 'Status',
            value: 'Present',
            icon: Icons.check_circle,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          const _StatusCard(
            title: 'Last Log',
            value: '09:00 AM',
            icon: Icons.access_time,
            color: Colors.blue,
          ),
          const Spacer(),
          // Team status
          const Text(
            'Team Status',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _TeamStatusItem(team: 'Team A', status: 'Clocked In'),
          _TeamStatusItem(team: 'Team B', status: 'Clocked Out'),
          _TeamStatusItem(team: 'Team C', status: 'Pending'),
        ],
      ),
    );
  }

  void _handleClockIn(BuildContext context) {
    // Logica per clock in
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Clock In successful')));
  }

  void _handleClockOut(BuildContext context) {
    // Logica per clock out
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Clock Out successful')));
  }
}

class _AttendanceButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool primary;

  const _AttendanceButton({
    required this.label,
    required this.onPressed,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return primary
        ? ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(label),
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 48),
            ),
            child: Text(label),
          );
  }
}

class _StatusCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatusCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamStatusItem extends StatelessWidget {
  final String team;
  final String status;

  const _TeamStatusItem({required this.team, required this.status});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(team),
          Chip(
            label: Text(status),
            backgroundColor: _getStatusColor(status),
            labelStyle: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'clocked in':
        return Colors.green.shade100;
      case 'clocked out':
        return Colors.blue.shade100;
      default:
        return Colors.orange.shade100;
    }
  }
}
