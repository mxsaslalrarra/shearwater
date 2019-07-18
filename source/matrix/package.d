module matrix;

import std.meta;
import std.range : chain;
import std.traits;

import sumtype;

import matrix.api;

enum Kind {
  Request,
  Response,
}

alias Request(alias T)  = T!(Kind.Request);
alias Response(alias T) = T!(Kind.Response);

enum Method {
  GET,
  POST,
}

struct Status
{
  bool ok;
  string message;
}

mixin template RequestParameters(string Endpoint, Method HttpMethod) {
  import std.string : capitalize;

  enum string endpoint = Endpoint;
  enum Method method = HttpMethod;
  mixin(`alias ResponseOf = ` ~ Endpoint.capitalize ~ `!(Kind.Response);`);
}

void execute(Action action, string baseUrl)
{
  import std.concurrency : ownerTid, send;
  import std.format : format;
  import std.json : JSONException, JSONValue, parseJSON;
  import std.net.curl : CurlException, HTTPStatusException;

  import matrix.common : buildUrl;

  action.match!(
    (request) {
      static assert (__traits(hasMember, request, "ResponseOf"));
      alias T = typeof(request);
      static assert (__traits(hasMember, T, "data"));
      alias U = request.ResponseOf;
      static assert (__traits(hasMember, U, "parse"));

      string url = buildUrl(baseUrl, request.endpoint);

      static if (T.method == Method.GET) {
        import std.net.curl : get;
        enum http = `get(url)`;
      } else {
        import std.net.curl : post;
        static assert (__traits(hasMember, T, "data"));
        enum http = `post(url, request.data)`;
      }

      U response;

      try {
        JSONValue result = mixin(http ~ `.parseJSON()`);
        response.parse(result);
        response.status = Status(true, "");
      } catch (HTTPStatusException e) {
        response.status = Status(false, "HTTP %d: %s".format(e.status, e.msg));
      } catch (CurlException e) {
        response.status = Status(false, e.msg);
      } catch (JSONException e) {
        response.status = Status(false, e.toString);
      }

      ownerTid.send(response);
    }
  );
}

template IsRequest(alias T)
{
  static if (__traits(compiles, mixin(T ~ `!(Kind.Request)`))) {
    const IsRequest = __traits(hasMember, mixin(T ~ `!(Kind.Request)`), "data");
  } else {
    const IsRequest = false;
  }
}

template MakeRequest(alias T)
{
  mixin(`alias MakeRequest = ` ~ T ~ `!(Kind.Request);`);
}

// NOTE add new modules to this list when adding endpoints to api

alias Symbols = Filter!(IsRequest, __traits(allMembers, matrix.api.login));
alias Action = SumType!(staticMap!(MakeRequest, Symbols));