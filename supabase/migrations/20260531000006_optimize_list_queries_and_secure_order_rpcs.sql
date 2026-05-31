create index if not exists idx_product_images_product_id
  on public.product_images (product_id);

create index if not exists idx_orders_customer_created_at
  on public.orders (customer_id, created_at desc);

create index if not exists idx_orders_customer_status_created_at
  on public.orders (customer_id, status, created_at desc);

create index if not exists idx_orders_status_created_at
  on public.orders (status, created_at desc);

create index if not exists idx_products_status_created_at
  on public.products (status, created_at desc)
  where deleted_at is null;

create index if not exists idx_wallet_transactions_user_created_at
  on public.wallet_transactions (user_id, created_at desc);

revoke execute on function public.create_order(uuid, text, text, text, text, text, uuid[], text) from public, anon;
revoke execute on function public.request_cancel_order(uuid, uuid) from public, anon;
revoke execute on function public.cancel_request_cancel_order(uuid, uuid) from public, anon;
revoke execute on function public.customer_request_return_order(uuid, uuid) from public, anon;
revoke execute on function public.customer_cancel_request_return_order(uuid, uuid) from public, anon;
revoke execute on function public.admin_confirm_order(uuid, uuid) from public, anon;
revoke execute on function public.admin_approve_cancel_order(uuid, uuid) from public, anon;
revoke execute on function public.admin_deliver_order_success(uuid, uuid) from public, anon;
revoke execute on function public.admin_deliver_order_failed(uuid, uuid) from public, anon;
revoke execute on function public.admin_approve_return_order(uuid, uuid) from public, anon;
revoke execute on function public.admin_cancel_pending_order(uuid, uuid) from public, anon;

grant execute on function public.create_order(uuid, text, text, text, text, text, uuid[], text) to authenticated;
grant execute on function public.request_cancel_order(uuid, uuid) to authenticated;
grant execute on function public.cancel_request_cancel_order(uuid, uuid) to authenticated;
grant execute on function public.customer_request_return_order(uuid, uuid) to authenticated;
grant execute on function public.customer_cancel_request_return_order(uuid, uuid) to authenticated;
grant execute on function public.admin_confirm_order(uuid, uuid) to authenticated;
grant execute on function public.admin_approve_cancel_order(uuid, uuid) to authenticated;
grant execute on function public.admin_deliver_order_success(uuid, uuid) to authenticated;
grant execute on function public.admin_deliver_order_failed(uuid, uuid) to authenticated;
grant execute on function public.admin_approve_return_order(uuid, uuid) to authenticated;
grant execute on function public.admin_cancel_pending_order(uuid, uuid) to authenticated;
