-- The previous regular expression escaped the backslash itself, so every
-- French number was rejected. Keep one regex escape for the literal + sign.
create or replace function public.normalize_fr_phone(p_phone text)
returns text
language plpgsql
immutable
set search_path = public
as $$
declare
  v_phone text := regexp_replace(coalesce(p_phone, ''), '[^0-9+]', '', 'g');
begin
  if v_phone like '0033%' then
    v_phone := '+' || substr(v_phone, 3);
  end if;
  if v_phone like '33%' then
    v_phone := '+' || v_phone;
  end if;
  if v_phone like '0%' then
    v_phone := '+33' || substr(v_phone, 2);
  end if;
  if v_phone !~ '^\+33[1-9][0-9]{8}$' then
    raise exception 'Téléphone invalide';
  end if;
  return v_phone;
end;
$$;
