alter table public.products
  alter column trade_name set not null;

alter table public.products
  drop constraint if exists products_price_check,
  add constraint products_price_check check (price > 0),
  drop constraint if exists products_stock_check,
  add constraint products_stock_check check (stock >= 0),
  add constraint products_internal_name_not_blank
    check (btrim(internal_name) <> ''),
  add constraint products_trade_name_not_blank
    check (btrim(trade_name) <> '');

create or replace function public.admin_delete_or_deactivate_product(
  p_product_id uuid,
  p_admin_id uuid
)
returns text
language plpgsql
security definer
set search_path = ''
as $$
begin
  if auth.uid() is null
    or auth.uid() <> p_admin_id
    or not public.is_admin()
  then
    raise exception 'Bạn không có quyền xóa sản phẩm.';
  end if;

  perform 1
  from public.products
  where id = p_product_id
  for update;

  if not found then
    raise exception 'Sản phẩm không tồn tại.';
  end if;

  if exists (
    select 1 from public.order_items where product_id = p_product_id
  ) or exists (
    select 1 from public.cart_items where product_id = p_product_id
  ) or exists (
    select 1 from public.inventory_transactions where product_id = p_product_id
  ) or exists (
    select 1 from public.return_order_items where product_id = p_product_id
  ) then
    update public.products
    set
      status = 'inactive',
      deleted_at = null,
      deleted_by = null,
      updated_by = p_admin_id,
      updated_at = now()
    where id = p_product_id;

    return 'deactivated';
  end if;

  delete from public.products
  where id = p_product_id;

  return 'deleted';
end;
$$;

revoke all on function public.admin_delete_or_deactivate_product(uuid, uuid)
from public;

grant execute on function public.admin_delete_or_deactivate_product(uuid, uuid)
to authenticated;
