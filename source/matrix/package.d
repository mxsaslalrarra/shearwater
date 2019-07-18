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

struct State
{
  string accessToken;
}

struct Status
{
  bool ok;
  string message;
}

mixin template RequestParameters(string Endpoint, Method HttpMethod, bool Auth = true) {
  import std.string : capitalize;

  enum string endpoint = Endpoint;
  enum Method method = HttpMethod;
  enum bool requiresAuth = Auth;
  mixin(`alias ResponseOf = ` ~ Endpoint.capitalize ~ `!(Kind.Response);`);
}

mixin template ResponseParameters(string Type)
{
  enum string responseType = Type;
  Status status;
}

void execute(Action action, State state, string baseUrl)
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
      //static assert (__traits(hasMember, T, "data") || __traits(hasMember, T, "parse"));
      alias U = request.ResponseOf;
      //static assert (__traits(hasMember, U, "parse"));

      static if (T.requiresAuth) {
        string accessToken = state.accessToken;
      } else {
        string accessToken = "";
      }

      static if (__traits(hasMember, T, "params")) {
        string url = buildUrl(baseUrl, request.endpoint, accessToken, request.params);
      } else {
        string url = buildUrl(baseUrl, request.endpoint, accessToken);
      }

      static if (T.method == Method.GET) {
        import std.net.curl : get;
        enum http = `get(url)`;
      } else {
        import std.net.curl : post;
        enum http = `post(url, request.data)`;
      }

      U response;

      try {
        JSONValue data = mixin(http ~ `.parseJSON()`);
        response.parse(data);
        response.status = Status(true, "");
      } catch (HTTPStatusException e) {
        response.status = Status(false, "HTTP %d: %s".format(e.status, e.msg));
      } catch (CurlException e) {
        response.status = Status(false, e.msg);
      } catch (JSONException e) {
        response.status = Status(false, e.toString);
      }

      // cast response to reaction
      Reaction result = response;

      ownerTid.send(result);
    }
  );
}

template IsRequest(alias T)
{
  static if (__traits(compiles, mixin(T ~ `!(Kind.Request)`))) {
    const IsRequest =
      __traits(hasMember, mixin(T ~ `!(Kind.Request)`), "data") ||
      __traits(hasMember, mixin(T ~ `!(Kind.Request)`), "params");
  } else {
    const IsRequest = false;
  }
}

template MakeRequest(alias T)
{
  mixin(`alias MakeRequest = ` ~ T ~ `!(Kind.Request);`);
}

template IsResponse(alias T)
{
  static if (__traits(compiles, mixin(T ~ `!(Kind.Response)`))) {
    const IsResponse = __traits(hasMember, mixin(T ~ `!(Kind.Response)`), "parse");
  } else {
    const IsResponse = false;
  }
}

template MakeResponse(alias T)
{
  mixin(`alias MakeResponse = ` ~ T ~ `!(Kind.Response);`);
}

alias ReqSymbols = Filter!(IsRequest, ApiMembers);
alias Action = SumType!(staticMap!(MakeRequest, ReqSymbols));

alias ResSymbols = Filter!(IsResponse, ApiMembers);
alias Reaction = SumType!(staticMap!(MakeResponse, ResSymbols));