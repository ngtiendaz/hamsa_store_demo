drop function if exists public.admin_get_dashboard_stats(text);

create function public.admin_get_dashboard_stats(
  p_period text default 'month',
  p_reference_date date default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_reference_date date;
  v_start_local timestamp;
  v_end_local timestamp;
  v_start_at timestamptz;
  v_end_at timestamptz;
  v_result jsonb;
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception 'Bạn không có quyền xem dashboard quản trị.';
  end if;

  if p_period not in ('week', 'month', 'year') then
    raise exception 'Khoảng thời gian không hợp lệ.';
  end if;

  v_reference_date := coalesce(
    p_reference_date,
    timezone('Asia/Ho_Chi_Minh', now())::date
  );
  v_start_local := date_trunc(p_period, v_reference_date::timestamp);
  v_end_local := case p_period
    when 'week' then v_start_local + interval '1 week'
    when 'month' then v_start_local + interval '1 month'
    else v_start_local + interval '1 year'
  end;
  v_start_at := v_start_local at time zone 'Asia/Ho_Chi_Minh';
  v_end_at := v_end_local at time zone 'Asia/Ho_Chi_Minh';

  with period_orders as (
    select o.*
    from public.orders o
    where o.created_at >= v_start_at
      and o.created_at < v_end_at
  ),
  completed_refunds as (
    select coalesce(sum(ro.total_refund_amount), 0) as amount
    from public.return_orders ro
    join period_orders o on o.id = ro.order_id
    where ro.status = 'return_completed'
  ),
  order_summary as (
    select
      coalesce(sum(o.total_amount) filter (
        where o.status in ('delivered', 'returned')
          and o.payment_status in ('paid', 'refunded', 'partially_refunded')
      ), 0) as gross_revenue,
      count(*) filter (where o.status = 'shipping') as shipping_count,
      count(*) filter (where o.status = 'cancelled') as cancelled_count,
      count(*) filter (where o.status = 'delivered') as delivered_count,
      count(*) filter (where o.status = 'delivery_failed') as delivery_failed_count,
      count(*) filter (
        where o.status = 'returned'
          or o.payment_status in ('refunded', 'partially_refunded')
      ) as refunded_count,
      count(*) filter (where o.status = 'returned') as returned_count
    from period_orders o
  ),
  low_stock as (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'id', p.id,
          'name', p.trade_name,
          'stock', p.stock,
          'image_url', image.image_url
        )
        order by p.stock asc, p.trade_name asc
      ),
      '[]'::jsonb
    ) as items
    from public.products p
    left join lateral (
      select pi.image_url
      from public.product_images pi
      where pi.product_id = p.id
      order by pi.sort_order asc, pi.created_at asc
      limit 1
    ) image on true
    where p.deleted_at is null
      and p.status = 'active'
      and p.stock < 5
  ),
  top_selling as (
    select coalesce(
      jsonb_agg(
        jsonb_build_object(
          'id', ranked.product_id,
          'name', ranked.product_name,
          'quantity_sold', ranked.quantity_sold,
          'revenue', ranked.revenue,
          'image_url', ranked.image_url
        )
        order by ranked.quantity_sold desc, ranked.product_name asc
      ),
      '[]'::jsonb
    ) as items
    from (
      select
        oi.product_id,
        oi.product_name_snapshot as product_name,
        sum(oi.quantity)::integer as quantity_sold,
        sum(oi.subtotal) as revenue,
        image.image_url
      from public.order_items oi
      join period_orders o on o.id = oi.order_id
      left join lateral (
        select pi.image_url
        from public.product_images pi
        where pi.product_id = oi.product_id
        order by pi.sort_order asc, pi.created_at asc
        limit 1
      ) image on true
      where o.status not in ('cancelled', 'delivery_failed')
      group by oi.product_id, oi.product_name_snapshot, image.image_url
      order by quantity_sold desc, oi.product_name_snapshot asc
      limit 5
    ) ranked
  )
  select jsonb_build_object(
    'period', p_period,
    'reference_date', v_reference_date,
    'start_at', v_start_at,
    'end_at', v_end_at,
    'revenue', greatest(summary.gross_revenue - refunds.amount, 0),
    'shipping_count', summary.shipping_count,
    'cancelled_count', summary.cancelled_count,
    'delivered_count', summary.delivered_count,
    'refunded_count', summary.refunded_count,
    'refunded_amount', refunds.amount,
    'return_rate', case
      when summary.delivered_count + summary.returned_count = 0 then 0
      else round(
        summary.returned_count::numeric
        / (summary.delivered_count + summary.returned_count)
        * 100,
        2
      )
    end,
    'delivery_success_rate', case
      when summary.delivered_count + summary.delivery_failed_count = 0 then 0
      else round(
        summary.delivered_count::numeric
        / (summary.delivered_count + summary.delivery_failed_count)
        * 100,
        2
      )
    end,
    'low_stock_products', low_stock.items,
    'top_selling_products', top_selling.items
  )
  into v_result
  from order_summary summary
  cross join completed_refunds refunds
  cross join low_stock
  cross join top_selling;

  return v_result;
end;
$$;

revoke execute on function public.admin_get_dashboard_stats(text, date)
from public, anon;

grant execute on function public.admin_get_dashboard_stats(text, date)
to authenticated;
