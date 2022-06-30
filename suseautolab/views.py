from django.http import HttpResponse
from django.shortcuts import render
import commands


def hello(request):
    return HttpResponse("Hello world ! ")


def runoob(request):
    context = {}
    context['hello'] = 'Hello World!'
    return render(request, 'runoob.html', context)


def search_form(request):
    return render(request, 'search_form.html')


def search_result(request):
    context = {}
    module = ''
    typesite = ''
    result = ''
    request.encoding = 'utf-8'
    if 'q' in request.GET and request.GET['q']:
        module = request.GET['q']
    else:
        module = 'nothing'
    if 'sellist1' in request.GET and request.GET['sellist1']:
        typesite = request.GET['sellist1']
    else:
        typesite = 'nothing'

    context['module'] = module
    context['typesite'] = typesite

    for site in ['O3', 'OSD']:
        cmd = "perl /root/website/HWPP/scriptfind_jobs_by_module.pl -f %s -m %s" % (
            typesite, module)
        ret = subprocess.run(cmd, shell=True)
    context['ret'] = ret
    return render(request, 'search_result.html', context)


def search_module(request):
    return render(request, 'search_module.html')
