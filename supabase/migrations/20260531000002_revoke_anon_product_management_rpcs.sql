revoke execute
on function public.admin_delete_or_deactivate_product(uuid, uuid)
from anon;

revoke execute
on function public.admin_delete_category(uuid)
from anon;

revoke execute
on function public.admin_delete_brand(uuid)
from anon;
