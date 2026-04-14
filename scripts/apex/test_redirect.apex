HttpRequest req = new HttpRequest();
req.setEndpoint('callout:Frankfurter_API/latest?from=USD');
req.setMethod('GET');
req.setTimeout(10000);

Http http = new Http();
HttpResponse res = http.send(req);

System.debug('>>> Status: ' + res.getStatusCode());
System.debug('>>> Location Header: ' + res.getHeader('Location'));
System.debug('>>> All Headers: ' + res.getHeaderKeys());
