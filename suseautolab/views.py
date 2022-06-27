from django.http import HttpResponse
from django.shortcuts import render
 
def hello(request):
    return HttpResponse("Hello world ! ")

def runoob(request):
    context          = {}
    context['hello'] = 'Hello World!'
    return render(request, 'runoob.html', context)

def search_form(request):
    return render(request, 'search_form.html')

def search_result(request):
    request.encoding='utf-8'
    if 'q' in request.GET and request.GET['q']:
        message = 'the content of your input: ' + request.GET['q']
    else:
        message = 'nothing' 
    #return HttpResponse(message)
    return render(request, 'search_result.html', message)

def search_module(request):
    return render(request, 'search_module.html')

