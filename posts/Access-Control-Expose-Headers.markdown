---
title: "Access-Control-Expose-Headers"
date_time: 2022-1-14 08:20:32
tags: http
---

2021的年底，所在城市因为新一波的新冠疫情，大家被迫居家办公，虽然去不公司办公，但是依然不会影响日常工作，在过去的2021年，经历了很多，也成长了很多，不管是工作上还是人生，都在一步步的成长。

好了，言归正传。说到HTTP协议，说实话工作这么多年，要说熟悉，那肯定熟悉，但是要说不熟悉，其实遇到这个问题后，才觉得自己其实一点都不熟悉。先说说遇到的问题吧：

最近接到一个需求，需要自定义http header来暴露给前端，前端再将这个暴露的header在请求后台时带回给后端程序。很快前后端代码都完成了，可以开始测试时发现，前端的代码始终读不到这个自定义的header，打开浏览器的调试工具，发现Response headers里有我们自定义的这个header，但是代码就是读不到，本来以为是axios的Bug，去到此开源项目的issues也找到了有人提出了同样的问题，才发现http协议默认是不会把自定义的header暴露给前端的脚本或程序去使用，必须使用[**Access-Control-Expose-Headers**](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Expose-Headers)将需要暴露的headers名字指定出现才可以使用，大概是这样

```
Access-Control-Expose-Headers: [<header-name>[, <header-name>]*]
Access-Control-Expose-Headers: *
```
在这过程中查阅了相关文档，有提到3个概念[CORS-safelisted response headers](https://developer.mozilla.org/en-US/docs/Glossary/CORS-safelisted_response_header)，[CORS-safelisted request header](https://developer.mozilla.org/en-US/docs/Glossary/CORS-safelisted_request_header)和[CORS](https://developer.mozilla.org/en-US/docs/Glossary/CORS)

## CORS-safelisted response header

A [**CORS-safelisted response header**](https://developer.mozilla.org/en-US/docs/Glossary/CORS-safelisted_response_header) is an HTTP header in a CORS response that it is considered safe to expose to client scripts. Only safelisted response headers are made available to web pages.

By default, the safelist includes the following response headers:

- Cache-Control
- Content-Language
- Content-Length
- Content-Type
- Expires
- Last-Modified
- Pragma

Additional headers can be added to the safelist using Access-Control-Expose-Headers.

> Note: **Content-Length** was not part of the original set of safelisted response headers

## CORS-safelisted request header
A [**CORS-safelisted request header**](https://developer.mozilla.org/en-US/docs/Glossary/CORS-safelisted_request_header) is one of the following HTTP headers:

- Accept
- Accept-Language
- Content-Language
- Content-Type

When containing only these headers (and values that meet the additional requirements laid out below), a requests doesn't need to send a [preflight](https://developer.mozilla.org/en-US/docs/Glossary/Preflight_request) request in the context of CORS. 这里有有提到如果发送的request仅仅只包含以上的headers的话，浏览器是不会发送一个preflight的请求

You can safelist more headers using the [**Access-Control-Allow-Headers**](https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Access-Control-Allow-Headers) header and also list the above headers there to circumvent the following additional restrictions:

Additional restrictions
CORS-safelisted headers must also fulfill the following requirements in order to be a CORS-safelisted request header:

- For Accept-Language and Content-Language: can only have values consisting of 0-9, A-Z, a-z, space or *,-.;=.
- For Accept and Content-Type: can't contain a CORS-unsafe request header byte: 0x00-0x1F (except for 0x09 (HT), which is allowed), "():<>?@[\]{}, and 0x7F (DEL).
- For Content-Type: needs to have a MIME type of its parsed value (ignoring parameters) of either application/x-www-form-urlencoded, multipart/form-data, or text/plain.
- For any header: the value’s length can't be greater than 128.

## CORS
最后有说到一个CORS，翻译成中文叫跨源资源共享，既然有跨源，那么相对应就有同源，这里有个很重要的概念叫[Origin](https://developer.mozilla.org/en-US/docs/Glossary/Origin)，这里可以详细的看一下什么是源

Web content's origin is defined by the **scheme** (protocol), **hostname** (domain), and **port** of the URL used to access it. Two objects have the same origin only when the scheme, hostname, and port all match.

Some operations are restricted to same-origin content, and this restriction can be lifted using CORS.

### Examples
These are same origin because they have the same scheme (http) and hostname (example.com), and the different file path does not matter:

```
http://example.com/app1/index.html
http://example.com/app2/index.html
```

These are same origin because a server delivers HTTP content through port 80 by default:

```
http://Example.com:80
http://example.com
```

These are not same origin because they use different schemes:
```
http://example.com/app1
https://example.com/app2
```

These are not same origin because they use different hostnames:
```
http://example.com
http://www.example.com
http://myapp.example.com
```

These are not same origin because they use different ports:
```
http://example.com
http://example.com:8080
```

上面给了些例子用来阐述同源和跨源，可以看出源是有协议，域名，端口这3个部分组成，这几项一样，就是同源，否则就是跨源。那么浏览器在处理跨源请求时，会自动触发一个[preflight](https://developer.mozilla.org/en-US/docs/Glossary/Preflight_request)的请求，那么服务器会告诉浏览器这个preflight的请求是否被授权访问，如果被允许，那么才会正常的触发实际的请求到后台。


好了就到这里吧，关于HTTP协议的东西，还有很多很多，有兴趣可以多看看[https://developer.mozilla.org/en-US/docs/Web/HTTP](https://developer.mozilla.org/en-US/docs/Web/HTTP)