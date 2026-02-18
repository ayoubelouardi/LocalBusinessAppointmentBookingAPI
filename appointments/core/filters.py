from django.db.models import Q


def filter_services(queryset, params):
    name = params.get("name")
    min_price = params.get("min_price")
    max_price = params.get("max_price")
    min_duration = params.get("min_duration")
    max_duration = params.get("max_duration")

    if name:
        queryset = queryset.filter(
            Q(name__icontains=name) | Q(description__icontains=name)
        )
    if min_price:
        queryset = queryset.filter(price__gte=min_price)
    if max_price:
        queryset = queryset.filter(price__lte=max_price)
    if min_duration:
        queryset = queryset.filter(duration_minutes__gte=min_duration)
    if max_duration:
        queryset = queryset.filter(duration_minutes__lte=max_duration)
    return queryset
