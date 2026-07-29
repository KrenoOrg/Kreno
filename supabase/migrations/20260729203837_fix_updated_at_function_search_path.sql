-- Trigger functions are invoked implicitly; recreate the helper with a fixed
-- lookup path so this also repairs environments where it was created manually.
create or replace function public.set_updated_at()
returns trigger language plpgsql set search_path = public as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
