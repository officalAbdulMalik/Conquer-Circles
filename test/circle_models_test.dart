import 'package:flutter_test/flutter_test.dart';
import 'package:test_steps/features/social/models/circle_models.dart';

void main() {
  group('CircleModel', () {
    test('parses enriched browse-circle data', () {
      final circle = CircleModel.fromJson({
        'id': 'circle-1',
        'name': 'Walkers',
        'owner_id': 'owner-1',
        'image_url': 'https://example.com/circle.png',
        'is_private': false,
        'member_count': 2,
        'max_members': 20,
        'is_member': true,
        'territories': 7,
        'rank': 3,
        'member_profiles': [
          {
            'user_id': 'user-1',
            'full_name': 'Aisha Khan',
            'avatar_url': 'https://example.com/aisha.png',
          },
        ],
      });

      expect(circle.id, 'circle-1');
      expect(circle.name, 'Walkers');
      expect(circle.imageUrl, 'https://example.com/circle.png');
      expect(circle.memberCount, 2);
      expect(circle.maxMembers, 20);
      expect(circle.isMember, isTrue);
      expect(circle.members.single.name, 'Aisha Khan');
    });

    test('parses nested joined-circle data', () {
      final circle = CircleModel.fromJson({
        'circle_id': 'circle-2',
        'role': 'owner',
        'circles': {
          'id': 'circle-2',
          'name': 'Night Steps',
          'is_private': true,
        },
      });

      expect(circle.id, 'circle-2');
      expect(circle.name, 'Night Steps');
      expect(circle.isPrivate, isTrue);
      expect(circle.isMember, isTrue);
      expect(circle.membershipRole, 'owner');
    });
  });

  test('CircleDetailsModel parses members and real count', () {
    final details = CircleDetailsModel.fromJson({
      'circle': {'id': 'circle-3', 'name': 'Runners', 'max_members': 10},
      'leaderboard': [
        {'user_id': 'user-3', 'username': 'runner', 'attack_energy': 90},
      ],
    });

    expect(details.circle.memberCount, 1);
    expect(details.members.single.name, 'runner');
    expect(details.members.single.attackEnergy, 90);
  });

  test('CircleJoinRequestModel parses nested profile and circle', () {
    final request = CircleJoinRequestModel.fromJson({
      'id': 'request-1',
      'circle_id': 'circle-4',
      'requester_id': 'user-4',
      'status': 'pending',
      'requester': {
        'full_name': 'Sara Ali',
        'avatar_url': 'https://example.com/sara.png',
      },
      'circle': {'name': 'City Walkers'},
    });

    expect(request.requesterName, 'Sara Ali');
    expect(request.circleName, 'City Walkers');
    expect(request.status, CircleJoinRequestStatus.pending);
  });
}
