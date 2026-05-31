revoke execute on function public.process_wallet_transaction(uuid, text, numeric, text)
  from public, anon;

grant execute on function public.process_wallet_transaction(uuid, text, numeric, text)
  to authenticated;

revoke execute on function public.rls_auto_enable()
  from public, anon, authenticated;
