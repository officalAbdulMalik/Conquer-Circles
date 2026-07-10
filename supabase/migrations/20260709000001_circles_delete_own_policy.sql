-- Allow a circle's owner to delete it. Related rows in circle_members,
-- circle_messages, invites, leaderboard_entries, circle_raid_alerts, and
-- circle_join_requests all have ON DELETE CASCADE foreign keys to
-- circles.id, so deleting the circle row cleans up everything else.
create policy "circles_delete_own"
on public.circles
for delete
using (auth.uid() = owner_id);
