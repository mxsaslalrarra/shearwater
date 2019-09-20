module matrix;

import std.algorithm : canFind;
import std.container : DList;
import std.meta : CompFilter = Filter, templateOr;
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

mixin template StateProp(T, string name)
{
  mixin(`private ` ~ T.stringof ~ ` _` ~ name ~ `;
    @property ` ~ T.stringof ~ ` ` ~ name ~ `() nothrow
    {
      synchronized
      {
        return _` ~ name ~ `;
      }
    }

    @property void ` ~ name ~ `(` ~ T.stringof ~ ` prop) nothrow
    {
      synchronized
      {
        _` ~ name ~ ` = prop;
      }
    }`
  );
}

struct State
{
  alias _ = StateProp;
  mixin _!(string, "server");
  mixin _!(string, "accessToken");
  mixin _!(string, "userId");
  mixin _!(bool, "connected");
}

__gshared static State STATE;

struct Status
{
  bool ok;
  string message;
}

// @refactor move to matrix/api/package.d
mixin template RequestParameters(string Endpoint, HttpMethod Method, bool Auth = true) {
  import std.array : split;

  enum string endpoint = Endpoint;
  enum HttpMethod method = Method;
  enum bool requiresAuth = Auth;
  static if (is(typeof(this) == T!A, alias T, A...))
  {
    mixin(`alias ResponseOf = ` ~ T.stringof.split('(')[0] ~ `!(Kind.Response);`);
  }
  else
  {
    static assert (0);
  }
}

unittest
{
  Request!Login req1;
  assert(is(req1.ResponseOf == Response!Login));
  Request!Sync req2;
  assert(is(req2.ResponseOf == Response!Sync));
  Request!Filter req3;
  assert(is(req3.ResponseOf == Response!Filter));
}

// @refactor move to matrix/api/package.d
mixin template ResponseParameters()
{
  import std.array : split;

  Status status;
  static if (is(typeof(this) == T!A, alias T, A...))
  {
    mixin(`enum string responseType = "` ~ T.stringof.split('(')[0] ~ `";`);
  }
  else
  {
    static assert (0);
  }
}

unittest
{
  Response!Login res1;
  assert(res1.responseType == "Login");
  Response!Sync res2;
  assert(res2.responseType == "Sync");
  Response!Filter res3;
  assert(res3.responseType == "Filter");
}

string createUrl(T)(T request, string baseUrl)
  if (__traits(hasMember, T, "endpoint"))
  out (result; !result.canFind("%s"))
  do
{
  import matrix.common : buildUrl;

  static if (T.requiresAuth)
  {
    string accessToken = STATE.accessToken;
  }
  else
  {
    string accessToken = "";
  }

  // does the request url need to be formatted?
  static if (__traits(hasMember, T, "urlParams"))
  {
    import std.format : format;
    import std.traits : ReturnType, TemplateOf;
    import std.typecons : Tuple;

    static if (__traits(isSame, TemplateOf!(ReturnType!(T.urlParams)), Tuple))
    {
      string path = request.endpoint.format(request.urlParams.expand);
    }
    else
    {
      static assert (is(ReturnType!(T.urlParams) == string));
      string path = request.endpoint.format(request.urlParams);
    }
  }
  else
  {
    string path = request.endpoint;
  }

  static if (__traits(hasMember, T, "params"))
  {
    return buildUrl(baseUrl, path, accessToken, request.params);
  }
  else
  {
    return buildUrl(baseUrl, path, accessToken);
  }

  assert(0);
}

void execute(T)(T request, string baseUrl)
{
  import std.format : format;
  import std.json : JSONException, JSONValue, parseJSON;
  import std.net.curl : CurlException, HTTPStatusException;

  static foreach (Method; Methods)
  {
    static if (methodMatches!(Method, T))
    {
      static assert (__traits(hasMember, request, "ResponseOf"));
      static assert (__traits(hasMember, T, "data") || __traits(hasMember, T, "params"));
      alias U = request.ResponseOf;
      static assert (__traits(hasMember, U, "parse"));

      string url = request.createUrl(baseUrl);

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

alias Methods = CompFilter!(templateOr!(IsRequest, IsResponse), ApiMembers);

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
