create or replace function public.admin_delete_category(
  p_category_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_default_category_id uuid;
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Bạn không có quyền xóa danh mục.';
  end if;

  select id
  into v_default_category_id
  from public.categories
  where name = 'Khác'
  limit 1;

  if v_default_category_id is null then
    insert into public.categories (name, description, is_active)
    values ('Khác', 'Danh mục mặc định', true)
    returning id into v_default_category_id;
  end if;

  if p_category_id = v_default_category_id then
    raise exception 'Không thể xóa danh mục mặc định "Khác".';
  end if;

  update public.products
  set category_id = v_default_category_id
  where category_id = p_category_id;

  delete from public.categories
  where id = p_category_id;
end;
$$;

create or replace function public.admin_delete_brand(
  p_brand_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_default_brand_id uuid;
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Bạn không có quyền xóa nhãn hàng.';
  end if;

  select id
  into v_default_brand_id
  from public.brands
  where name = 'Khác'
  limit 1;

  if v_default_brand_id is null then
    insert into public.brands (name, description, is_active)
    values ('Khác', 'Nhãn hàng mặc định', true)
    returning id into v_default_brand_id;
  end if;

  if p_brand_id = v_default_brand_id then
    raise exception 'Không thể xóa nhãn hàng mặc định "Khác".';
  end if;

  update public.products
  set brand_id = v_default_brand_id
  where brand_id = p_brand_id;

  delete from public.brands
  where id = p_brand_id;
end;
$$;

revoke all on function public.admin_delete_category(uuid) from public;
revoke all on function public.admin_delete_brand(uuid) from public;

grant execute on function public.admin_delete_category(uuid) to authenticated;
grant execute on function public.admin_delete_brand(uuid) to authenticated;
