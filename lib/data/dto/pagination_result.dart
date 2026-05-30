class PaginationResult<T> {
  final List<T> items;
  final int totalCount;
  final int page;
  final int pageSize;

  PaginationResult({
    required this.items,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  bool get hasNextPage => (page * pageSize) < totalCount;
}
