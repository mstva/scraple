from django.http import HttpResponse


def index_view(request):
    return HttpResponse(f"<h1>Welcome to Scraple</h1>")
