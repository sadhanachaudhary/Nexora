import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/message.dart';
import '../providers/messages_provider.dart';
import 'checkout_sheet.dart';

// ── 1. Payment / Invoice Bubble Widget ────────────────────────────────────────

class PaymentBubbleWidget extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onPaid;

  const PaymentBubbleWidget({
    super.key,
    required this.message,
    required this.isMe,
    this.onPaid,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String title = 'Invoice';
    double amount = 50.00;
    String currency = 'USD';
    String status = 'UNPAID'; // 'UNPAID' | 'PAID'
    String dueDate = 'Due upon receipt';

    try {
      final data = jsonDecode(message.content ?? '{}');
      if (data is Map) {
        title = data['title'] ?? 'Invoice';
        amount = (data['amount'] as num?)?.toDouble() ?? 50.00;
        currency = data['currency'] ?? 'USD';
        status = data['status'] ?? 'UNPAID';
        dueDate = data['dueDate'] ?? 'Due upon receipt';
      }
    } catch (_) {}

    final isPaid = status == 'PAID';

    return Container(
      width: 260,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.12)
            : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaid
              ? Colors.green.withValues(alpha: 0.4)
              : (isMe ? Colors.white.withValues(alpha: 0.2) : cs.outline.withValues(alpha: 0.25)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isPaid
                  ? Colors.green.withValues(alpha: 0.15)
                  : const Color(0xFF7C3AED).withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isPaid ? Icons.check_circle_rounded : Icons.receipt_long_rounded,
                      color: isPaid ? Colors.green : const Color(0xFF7C3AED),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isPaid ? 'Payment Settled' : 'Nexora Invoice',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isPaid ? Colors.green : const Color(0xFF7C3AED),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPaid ? 'PAID' : 'PENDING',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content body
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: isMe ? Colors.white : cs.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$currency ',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isMe ? Colors.white70 : cs.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    Text(
                      amount.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        color: isMe ? Colors.white : cs.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dueDate,
                  style: TextStyle(
                    fontSize: 11,
                    color: isMe ? Colors.white60 : cs.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 12),

                // Pay Now button (if not me or recipient wants to pay)
                if (!isPaid)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C3AED),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        CheckoutSheet.show(
                          context,
                          amount: amount,
                          currency: currency,
                          title: title,
                          onComplete: () {
                            onPaid?.call();
                          },
                        );
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.payment_rounded, size: 16),
                          SizedBox(width: 8),
                          Text('Pay with Nexora Pay', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── 2. Task Bubble Widget ─────────────────────────────────────────────────────

class TaskBubbleWidget extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onToggle;

  const TaskBubbleWidget({
    super.key,
    required this.message,
    required this.isMe,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String title = 'Complete task';
    String priority = 'Medium'; // 'High' | 'Medium' | 'Low'
    bool isCompleted = false;
    String dueDate = 'Tomorrow';
    String assignee = 'You';

    try {
      final data = jsonDecode(message.content ?? '{}');
      if (data is Map) {
        title = data['title'] ?? 'Complete task';
        priority = data['priority'] ?? 'Medium';
        isCompleted = data['isCompleted'] ?? false;
        dueDate = data['dueDate'] ?? 'Tomorrow';
        assignee = data['assignee'] ?? 'You';
      }
    } catch (_) {}

    Color priorityColor;
    if (priority == 'High') {
      priorityColor = Colors.red;
    } else if (priority == 'Low') {
      priorityColor = Colors.blue;
    } else {
      priorityColor = Colors.orange;
    }

    return Container(
      width: 260,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.12)
            : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? Colors.white.withValues(alpha: 0.2) : cs.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isCompleted ? Colors.green : Colors.transparent,
                    border: Border.all(
                      color: isCompleted ? Colors.green : (isMe ? Colors.white60 : cs.onSurface.withValues(alpha: 0.4)),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 14,
                    color: isCompleted ? Colors.white : Colors.transparent,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isMe ? Colors.white : cs.onSurface,
                        decoration: isCompleted ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Assignee: $assignee • Due: $dueDate',
                      style: TextStyle(
                        fontSize: 11,
                        color: isMe ? Colors.white70 : cs.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              '$priority Priority',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: priorityColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 3. Interactive Poll Bubble Widget ─────────────────────────────────────────

class PollBubbleWidget extends StatelessWidget {
  final Message message;
  final bool isMe;
  final String currentUserId;
  final Function(int optionIndex)? onVote;

  const PollBubbleWidget({
    super.key,
    required this.message,
    required this.isMe,
    required this.currentUserId,
    this.onVote,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String question = 'Poll Question';
    List<dynamic> options = [];
    int totalVotes = 0;

    try {
      final data = jsonDecode(message.content ?? '{}');
      if (data is Map) {
        question = data['question'] ?? 'Poll Question';
        options = data['options'] ?? [];
        for (var opt in options) {
          final votes = (opt['voters'] as List?)?.length ?? 0;
          totalVotes += votes;
        }
      }
    } catch (_) {}

    return Container(
      width: 270,
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isMe
            ? Colors.white.withValues(alpha: 0.12)
            : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isMe ? Colors.white.withValues(alpha: 0.2) : cs.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.poll_rounded, color: const Color(0xFF8B5CF6), size: 18),
              const SizedBox(width: 6),
              const Text(
                'POLL',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: Color(0xFF8B5CF6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            question,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isMe ? Colors.white : cs.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...options.asMap().entries.map((entry) {
            final idx = entry.key;
            final opt = entry.value;
            final text = opt['text'] ?? 'Option';
            final voters = List<String>.from(opt['voters'] ?? []);
            final voteCount = voters.length;
            final hasVoted = voters.contains(currentUserId);
            final ratio = totalVotes > 0 ? (voteCount / totalVotes) : 0.0;

            return GestureDetector(
              onTap: () => onVote?.call(idx),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                height: 42,
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasVoted
                        ? const Color(0xFF7C3AED)
                        : cs.outline.withValues(alpha: 0.15),
                    width: hasVoted ? 1.5 : 1,
                  ),
                ),
                child: Stack(
                  children: [
                    // Filled progress bar
                    FractionallySizedBox(
                      widthFactor: ratio,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                    ),
                    // Option text & vote count
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              if (hasVoted) ...[
                                const Icon(Icons.check_circle_rounded, color: Color(0xFF7C3AED), size: 16),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                text,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: hasVoted ? FontWeight.w700 : FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${(ratio * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$totalVotes votes total',
              style: TextStyle(
                fontSize: 11,
                color: isMe ? Colors.white60 : cs.onSurface.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── 4. Webhook / Developer Embed Bubble Widget ────────────────────────────────

class WebhookBubbleWidget extends StatelessWidget {
  final Message message;
  final bool isMe;

  const WebhookBubbleWidget({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    String service = 'Webhook';
    String title = 'External Alert';
    String description = '';
    String status = 'success';
    List<dynamic> fields = [];
    String actionUrl = '';

    try {
      final data = jsonDecode(message.content ?? '{}');
      if (data is Map) {
        service = data['service'] ?? 'Webhook';
        title = data['title'] ?? 'External Alert';
        description = data['description'] ?? '';
        status = data['status'] ?? 'success';
        fields = data['fields'] ?? [];
        actionUrl = data['actionUrl'] ?? '';
      }
    } catch (_) {}

    Color statusColor;
    if (status == 'error') {
      statusColor = Colors.red;
    } else if (status == 'warning') {
      statusColor = Colors.orange;
    } else {
      statusColor = Colors.green;
    }

    return Container(
      width: 280,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border(
          left: BorderSide(color: statusColor, width: 4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.webhook_rounded, size: 16, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      service.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            if (description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
            if (fields.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...fields.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Text(
                          '${f['name']}: ',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        Text(
                          '${f['value']}',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            if (actionUrl.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    side: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Opening $actionUrl...')),
                    );
                  },
                  child: const Text('View Event Details', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── 5. Live Location Streaming Bubble Widget ──────────────────────────────────

class LiveLocationBubbleWidget extends ConsumerStatefulWidget {
  final Message message;
  final bool isMe;

  const LiveLocationBubbleWidget({
    super.key,
    required this.message,
    required this.isMe,
  });

  @override
  ConsumerState<LiveLocationBubbleWidget> createState() =>
      _LiveLocationBubbleWidgetState();
}

class _LiveLocationBubbleWidgetState
    extends ConsumerState<LiveLocationBubbleWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    int durationMins = 60;
    double lat = 37.7749;
    double lng = -122.4194;
    String senderName = 'User';
    bool isEnded = false;

    try {
      final data = jsonDecode(widget.message.content ?? '{}');
      if (data is Map) {
        durationMins = data['durationMins'] ?? 60;
        lat = (data['lat'] as num?)?.toDouble() ?? 37.7749;
        lng = (data['lng'] as num?)?.toDouble() ?? -122.4194;
        senderName = data['senderName'] ?? 'Live Location';
        isEnded = data['isEnded'] == true;
      }
    } catch (_) {}

    return Container(
      width: 250,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: widget.isMe
            ? Colors.white.withValues(alpha: 0.12)
            : cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isMe
              ? Colors.white.withValues(alpha: 0.2)
              : cs.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Map Radar Canvas
          Container(
            height: 90,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              gradient: isEnded
                  ? const LinearGradient(
                      colors: [Color(0xFF334155), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse waves (only when active)
                if (!isEnded)
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, child) {
                      final val = _pulseCtrl.value;
                      return Container(
                        width: 30 + val * 50,
                        height: 30 + val * 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent
                              .withValues(alpha: (1 - val) * 0.4),
                        ),
                      );
                    },
                  ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isEnded ? Colors.grey.shade600 : const Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEnded
                        ? Icons.location_off_rounded
                        : Icons.navigation_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isEnded ? Colors.grey.shade700 : Colors.redAccent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.circle,
                          color: isEnded ? Colors.white70 : Colors.white,
                          size: 6,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isEnded ? 'ENDED' : 'LIVE',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$senderName\'s Live Location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: widget.isMe ? Colors.white : cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isEnded
                      ? 'Live location sharing ended'
                      : 'Active for $durationMins mins • ${lat.toStringAsFixed(3)}°, ${lng.toStringAsFixed(3)}°',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isMe
                        ? Colors.white70
                        : cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
                // Stop sharing button
                if (widget.isMe && !isEnded) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade400,
                        side: BorderSide(
                          color: Colors.red.shade400.withValues(alpha: 0.5),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        ref
                            .read(messagesProvider(widget.message.conversationId))
                            .stopLiveLocation(widget.message.id);
                      },
                      icon: const Icon(Icons.stop_circle_outlined, size: 15),
                      label: const Text(
                        'Stop Sharing',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
