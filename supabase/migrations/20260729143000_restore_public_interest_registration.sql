-- The remote legacy baseline contains the table but not the public RPC used by
-- the landing page. Restore the versioned, rate-limited registration endpoint.

create or replace function public.register_professional_interest(
  p_email text, p_name text, p_business_name text, p_activity text, p_city text, p_consent boolean
) returns uuid
language plpgsql security definer set search_path = public
as $$
declare v_id uuid; v_email text := lower(trim(p_email));
begin
  if p_consent is distinct from true then raise exception 'Le consentement est requis'; end if;
  if v_email !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then raise exception 'E-mail invalide'; end if;
  perform enforce_rate_limit('professional_interest', v_email, 3, interval '1 hour');
  insert into professional_interest(email, name, business_name, activity, city, consented_at)
    values (v_email, nullif(trim(p_name), ''), nullif(trim(p_business_name), ''), nullif(trim(p_activity), ''), nullif(trim(p_city), ''), now())
    on conflict (lower(email)) do update set
      name = excluded.name, business_name = excluded.business_name, activity = excluded.activity,
      city = excluded.city, consented_at = now(), consent_source = 'public_interest_form'
    returning id into v_id;
  return v_id;
end;
$$;

revoke all on function public.register_professional_interest(text,text,text,text,text,boolean) from public;
grant execute on function public.register_professional_interest(text,text,text,text,text,boolean) to anon, authenticated;
