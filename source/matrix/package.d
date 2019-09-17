module matrix;

import std.container : DList;
import std.meta;
import std.range : chain;
import std.string : toLower;
import std.traits;

import core.thread;

import queue;
import matrix.api;

enum Kind {
  Request,
  Response,
}

alias Request(alias T)  = T!(Kind.Request);
alias Response(alias T) = T!(Kind.Response);

unittest
{
  assert(is(Request!Sync == Sync!(Kind.Request)));
  assert(is(Response!Sync == Sync!(Kind.Response)));
}

enum HttpMethod {
  GET,
  POST,
}

struct State
{
  string server;
  string accessToken;

  @property bool connected() nothrow
  {
    synchronized
    {
      return _connected;
    }
  }

  @property void connected(bool c) nothrow
  {
    synchronized
    {
      _connected = c;
    }
  }
private:
  bool _connected = false;
}

__gshared static State STATE;

struct Status
{
  bool ok;
  string message;
}

mixin template RequestParameters(string Endpoint, HttpMethod Method, bool Auth = true) {
  import std.string : capitalize;

  enum string endpoint = Endpoint;
  enum HttpMethod method = Method;
  enum bool requiresAuth = Auth;
  mixin(`alias ResponseOf = ` ~ Endpoint.capitalize ~ `!(Kind.Response);`);
}

mixin template ResponseParameters(string Type)
{
  enum string responseType = Type;
  Status status;
}

void execute(T)(T request, string baseUrl)
{
  import std.format : format;
  import std.json : JSONException, JSONValue, parseJSON;
  import std.net.curl : CurlException, HTTPStatusException;

  import matrix.common : buildUrl;

  static foreach (Method; Methods)
  {
    static if (methodMatches!(Method, T))
    {
      static assert (__traits(hasMember, request, "ResponseOf"));
      static assert (__traits(hasMember, T, "data") || __traits(hasMember, T, "params"));
      alias U = request.ResponseOf;
      static assert (__traits(hasMember, U, "parse"));

      static if (T.requiresAuth) {
        string accessToken = STATE.accessToken;
      } else {
        string accessToken = "";
      }

      static if (__traits(hasMember, T, "params")) {
        string url = buildUrl(baseUrl, request.endpoint, accessToken, request.params);
      } else {
        string url = buildUrl(baseUrl, request.endpoint, accessToken);
      }

      static if (T.method == HttpMethod.GET) {
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

      put(response);
    }
  }
}

unittest
{
  // demonstrate execute() workflow, but it will fail due to http request
  auto login = Request!Login();
  put(login);
  auto result = take!(Request!Login, true)();
  assert(!result.isNull);
  result.execute("localhost");

  auto response = take!(Response!Login, true)();
  assert(!response.isNull);
  assert(!response.status.ok);
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

unittest
{
  assert( IsRequest!("Login"));
  assert(!IsRequest!("FooBar"));
}

template IsResponse(alias T)
{
  static if (__traits(compiles, mixin(T ~ `!(Kind.Response)`))) {
    const IsResponse = __traits(hasMember, mixin(T ~ `!(Kind.Response)`), "parse");
  } else {
    const IsResponse = false;
  }
}

unittest
{
  assert( IsResponse!("Login"));
  assert(!IsResponse!("FooBar"));
}

alias Methods = Filter!(templateOr!(IsRequest, IsResponse), ApiMembers);

/++
 + Match the string representation of a type to it's actual type.
 + Will unwrap T if it is Nullable
 +/
bool methodMatches(string Method, T)()
{
  import std.traits : TemplateOf, TemplateArgsOf;
  import std.typecons : Nullable;

  static if (is(Nullable!(TemplateArgsOf!T) == T!(TemplateArgsOf!T)))
  {
    return mixin(`is(Nullable!(` ~ Method ~ `!(TemplateArgsOf!(TemplateArgsOf!T))) == T)`);
  }
  else
  {
    return mixin(`is(` ~ Method ~ `!(TemplateArgsOf!T) == T)`);
  }
}

unittest
{
  import std.typecons : Nullable;

  assert(methodMatches!("Sync", Request!Sync));
  assert(!methodMatches!("Login", Request!Sync));
  assert(methodMatches!("Login", Response!Login));
  assert(!methodMatches!("Sync", Response!Login));

  assert(methodMatches!("Sync", Nullable!(Request!Sync)));
  assert(!methodMatches!("Login", Nullable!(Request!Sync)));
  assert(methodMatches!("Login", Nullable!(Response!Login)));
  assert(!methodMatches!("Sync", Nullable!(Response!Login)));
}
