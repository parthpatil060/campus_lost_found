import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../models/broadcast_model.dart';
import '../utils/app_theme.dart';

class BroadcastCard extends StatelessWidget {
  final BroadcastModel broadcast;
  final String currentUserId;
  final bool compact;
  final bool fullWidth;
  final bool showResponseCount;
  final bool showRespondAction;
  final void Function(BroadcastModel)? onRespond;
  final void Function(BroadcastModel)? onDeactivate;

  const BroadcastCard({
    super.key,
    required this.broadcast,
    required this.currentUserId,
    this.compact = false,
    this.fullWidth = false,
    this.showResponseCount = true,
    this.showRespondAction = true,
    this.onRespond,
    this.onDeactivate,
  });

  static const Color _lostColor = AppTheme.primary;
  static const Color _foundColor = Color(0xFF7C73E6);

  Color get _accentColor =>
      broadcast.broadcastType == 'lost_broadcast' ? _lostColor : _foundColor;

  String get _typeLabel =>
      broadcast.broadcastType == 'lost_broadcast' ? 'Lost Item' : 'Found Item';

  String get _responseButtonLabel =>
      broadcast.broadcastType == 'lost_broadcast'
          ? 'I found this'
          : 'This might be mine';

  bool get _hasResponded => broadcast.readBy.contains(currentUserId);

  bool get _isActive =>
      broadcast.isActive && broadcast.expiresAt.isAfter(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact || fullWidth ? double.infinity : 290,
      margin: compact || fullWidth
          ? const EdgeInsets.only(bottom: 18)
          : const EdgeInsets.only(right: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: _accentColor.withOpacity(0.14)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _accentColor.withOpacity(0.16),
                    Colors.white,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  _TypeChip(label: _typeLabel, color: _accentColor),
                  if (compact || fullWidth) ...[
                    const SizedBox(width: 8),
                    _TypeChip(
                      label: _isActive ? 'Active' : 'Inactive',
                      color: _isActive ? AppTheme.success : AppTheme.textSecondary,
                    ),
                  ],
                  const Spacer(),
                  Text(
                    compact
                        ? DateFormat('MMM d, yyyy').format(broadcast.createdAt)
                        : fullWidth
                            ? DateFormat('MMM d, yyyy').format(broadcast.createdAt)
                            : timeago.format(broadcast.createdAt),
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 2, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: broadcast.itemPhotoURL.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: broadcast.itemPhotoURL,
                                width: compact || fullWidth ? 88 : 76,
                                height: compact || fullWidth ? 88 : 76,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => _ImagePlaceholder(
                                  color: _accentColor,
                                  size: compact || fullWidth ? 88 : 76,
                                ),
                                errorWidget: (_, __, ___) => _ImagePlaceholder(
                                  color: _accentColor,
                                  broken: true,
                                  size: compact || fullWidth ? 88 : 76,
                                ),
                              )
                            : _ImagePlaceholder(
                                color: _accentColor,
                                size: compact || fullWidth ? 88 : 76,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              broadcast.itemName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            if (broadcast.itemDescription.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                broadcast.itemDescription,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                            if (broadcast.locationInfo.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 1),
                                    child: Icon(
                                      Icons.location_on_outlined,
                                      size: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      broadcast.locationInfo,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if ((compact || fullWidth) &&
                                broadcast.createdByName.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person_outline_rounded,
                                    size: 13,
                                    color: AppTheme.textSecondary,
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      'By ${broadcast.createdByName}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (broadcast.verifierMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _accentColor.withOpacity(0.14)),
                      ),
                      child: Text(
                        broadcast.verifierMessage,
                        maxLines: compact ? 3 : 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                  if (compact || fullWidth) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _MetaDetail(
                          icon: Icons.calendar_today_outlined,
                          label:
                              'Created ${DateFormat('MMM d, yyyy').format(broadcast.createdAt)}',
                        ),
                        _MetaDetail(
                          icon: Icons.timer_off_outlined,
                          label:
                              'Expires ${DateFormat('MMM d, yyyy').format(broadcast.expiresAt)}',
                        ),
                        if (showResponseCount)
                          _MetaDetail(
                            icon: Icons.remove_red_eye_outlined,
                            label:
                                '${broadcast.readBy.length} response${broadcast.readBy.length == 1 ? '' : 's'}',
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (compact) ...[
                    if (onDeactivate != null) ...[
                      const SizedBox(height: 2),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => onDeactivate!(broadcast),
                          icon: const Icon(Icons.block_outlined, size: 14),
                          label: const Text('Deactivate'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _accentColor,
                            side: BorderSide(color: _accentColor.withOpacity(0.35)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ] else if (showRespondAction) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _hasResponded ? null : () => onRespond?.call(broadcast),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _hasResponded ? Colors.grey.shade200 : _accentColor,
                          foregroundColor:
                              _hasResponded ? AppTheme.textSecondary : Colors.white,
                          disabledBackgroundColor: Colors.grey.shade200,
                          disabledForegroundColor: AppTheme.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: _hasResponded ? 0 : 2,
                          textStyle: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(
                          _hasResponded ? 'Response sent' : _responseButtonLabel,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final Color color;

  const _TypeChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final Color color;
  final bool broken;
  final double size;

  const _ImagePlaceholder({
    required this.color,
    this.broken = false,
    this.size = 76,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      color: color.withOpacity(0.1),
      child: Icon(
        broken ? Icons.broken_image_outlined : Icons.image_outlined,
        color: color,
        size: 28,
      ),
    );
  }
}

class _MetaDetail extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaDetail({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppTheme.textSecondary),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
