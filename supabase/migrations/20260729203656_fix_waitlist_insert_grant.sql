-- The provider dashboard has an owner-only INSERT policy, but the table grant
-- was omitted. Without it, a legitimate provider cannot manually add a client.
-- RLS still restricts the inserted row to the authenticated owner.
grant insert on table public.waitlist_clients to authenticated;
