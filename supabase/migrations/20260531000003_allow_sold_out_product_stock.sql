alter table public.products
  drop constraint if exists products_stock_check,
  add constraint products_stock_check check (stock >= 0);
