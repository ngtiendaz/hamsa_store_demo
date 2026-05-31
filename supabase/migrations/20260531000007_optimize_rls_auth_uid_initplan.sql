alter policy profiles_admin_insert on public.profiles
  with check (is_admin() or id = (select auth.uid()));

alter policy profiles_select_self_or_staff on public.profiles
  using (id = (select auth.uid()) or is_staff());

alter policy profiles_update_self_basic_or_admin on public.profiles
  using (id = (select auth.uid()) or is_admin())
  with check (id = (select auth.uid()) or is_admin());

alter policy carts_owner_insert on public.carts
  with check (user_id = (select auth.uid()));

alter policy carts_owner_select on public.carts
  using (user_id = (select auth.uid()));

alter policy carts_owner_update on public.carts
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

alter policy cart_items_owner_select on public.cart_items
  using (
    exists (
      select 1
      from public.carts
      where carts.id = cart_items.cart_id
        and carts.user_id = (select auth.uid())
    )
  );

alter policy cart_items_owner_write on public.cart_items
  using (
    exists (
      select 1
      from public.carts
      where carts.id = cart_items.cart_id
        and carts.user_id = (select auth.uid())
        and carts.status = 'active'
    )
  )
  with check (
    exists (
      select 1
      from public.carts
      where carts.id = cart_items.cart_id
        and carts.user_id = (select auth.uid())
        and carts.status = 'active'
    )
  );

alter policy orders_customer_insert on public.orders
  with check (customer_id = (select auth.uid()) or is_staff());

alter policy orders_customer_pending_update_or_staff on public.orders
  using (
    is_staff()
    or (customer_id = (select auth.uid()) and status = 'pending_confirmation')
  )
  with check (is_staff() or customer_id = (select auth.uid()));

alter policy orders_select_owner_or_staff on public.orders
  using (customer_id = (select auth.uid()) or is_staff());

alter policy order_items_insert_customer_or_staff on public.order_items
  with check (
    is_staff()
    or exists (
      select 1
      from public.orders
      where orders.id = order_items.order_id
        and orders.customer_id = (select auth.uid())
        and orders.status = 'pending_confirmation'
    )
  );

alter policy order_items_select_owner_or_staff on public.order_items
  using (
    is_staff()
    or exists (
      select 1
      from public.orders
      where orders.id = order_items.order_id
        and orders.customer_id = (select auth.uid())
    )
  );

alter policy wallets_owner_or_admin_insert on public.wallets
  with check (user_id = (select auth.uid()) or is_admin());

alter policy wallets_select_owner_or_staff on public.wallets
  using (user_id = (select auth.uid()) or is_staff());

alter policy wallet_transactions_select_owner_or_staff on public.wallet_transactions
  using (user_id = (select auth.uid()) or is_staff());
