alter policy return_orders_customer_insert
  on public.return_orders
  with check (customer_id = (select auth.uid()));

alter policy return_orders_select_owner_or_staff
  on public.return_orders
  using (customer_id = (select auth.uid()) or public.is_staff());

alter policy order_status_logs_select_owner_or_staff
  on public.order_status_logs
  using (
    public.is_staff()
    or exists (
      select 1
      from public.orders
      where orders.id = order_status_logs.order_id
        and orders.customer_id = (select auth.uid())
    )
  );

alter policy return_order_items_customer_insert
  on public.return_order_items
  with check (
    exists (
      select 1
      from public.return_orders
      where return_orders.id = return_order_items.return_order_id
        and return_orders.customer_id = (select auth.uid())
        and return_orders.status = 'return_pending'::public.return_status
    )
  );

alter policy return_order_items_select_owner_or_staff
  on public.return_order_items
  using (
    public.is_staff()
    or exists (
      select 1
      from public.return_orders
      where return_orders.id = return_order_items.return_order_id
        and return_orders.customer_id = (select auth.uid())
    )
  );
