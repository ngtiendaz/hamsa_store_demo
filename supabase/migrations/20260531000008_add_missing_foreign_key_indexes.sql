create index if not exists idx_inventory_transactions_created_by
  on public.inventory_transactions (created_by);

create index if not exists idx_inventory_transactions_related_return_order_id
  on public.inventory_transactions (related_return_order_id);

create index if not exists idx_order_status_logs_changed_by
  on public.order_status_logs (changed_by);

create index if not exists idx_order_status_logs_order_id
  on public.order_status_logs (order_id);

create index if not exists idx_orders_cancelled_by
  on public.orders (cancelled_by);

create index if not exists idx_orders_completed_by
  on public.orders (completed_by);

create index if not exists idx_orders_confirmed_by
  on public.orders (confirmed_by);

create index if not exists idx_orders_created_by
  on public.orders (created_by);

create index if not exists idx_orders_shipped_by
  on public.orders (shipped_by);

create index if not exists idx_products_created_by
  on public.products (created_by);

create index if not exists idx_products_deleted_by
  on public.products (deleted_by);

create index if not exists idx_products_updated_by
  on public.products (updated_by);

create index if not exists idx_return_order_items_order_item_id
  on public.return_order_items (order_item_id);

create index if not exists idx_return_order_items_product_id
  on public.return_order_items (product_id);

create index if not exists idx_return_order_items_return_order_id
  on public.return_order_items (return_order_id);

create index if not exists idx_return_orders_approved_by
  on public.return_orders (approved_by);

create index if not exists idx_return_orders_rejected_by
  on public.return_orders (rejected_by);

create index if not exists idx_revenue_transactions_return_order_id
  on public.revenue_transactions (return_order_id);

create index if not exists idx_wallet_transactions_related_return_order_id
  on public.wallet_transactions (related_return_order_id);
