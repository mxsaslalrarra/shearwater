module matrix;

import std.container : DList;
import std.meta;
import std.range : chain;
import std.string : toLower;
import std.traits;

import core.thread;

import matrix.api;

enum Kind {
  Request,
  Response,
}

alias Request(alias T)  = T!(Kind.Request);
alias Response(alias T) = T!(Kind.Response);

enum HttpMethod {
  GET,
  POST,
}

struct State
{
  string server;
  string accessToken;
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
    static if (mixin(`is(` ~ Method ~ `!(Kind.Request) == T)`))
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

      mixin(`main_queue_` ~ Method.toLower ~ ` ~= response;`);
    }
  }
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

template IsResponse(alias T)
{
  static if (__traits(compiles, mixin(T ~ `!(Kind.Response)`))) {
    const IsResponse = __traits(hasMember, mixin(T ~ `!(Kind.Response)`), "parse");
  } else {
    const IsResponse = false;
  }
}

alias Methods = Filter!(templateOr!(IsRequest, IsResponse), ApiMembers);

// Queue Stuff

static foreach (Method; Methods)
{
  static if (IsRequest!Method || IsResponse!Method)
  {
    mixin(`__gshared static auto main_queue_` ~ Method.toLower ~
          ` = DList!(` ~ Method ~ `!(Kind.Response))();`);
    mixin(`__gshared static auto work_queue_` ~ Method.toLower ~
          ` = DList!(` ~ Method ~ `!(Kind.Request))();`);
  }
}

T popFront(T)(DList!T queue)
{
  T result = queue.front;
  queue.removeFront();
  return result;
}

void putWork(T)(T value)
{
  static foreach (Method; Methods)
  {
    static if (mixin(`is(` ~ Method ~ `!(Kind.Request) == T)`))
    {
      mixin(`work_queue_` ~ Method.toLower ~ ` ~= value;`);
    }
  }
}

auto takeResult(T)()
{
  static foreach (Method; Methods)
  {
    static if (mixin(`is(` ~ Method ~ `!(Kind.Response) == T)`))
    {
      enum queue = `main_queue_` ~ Method.toLower;

      if (mixin(`!` ~ queue ~ `.empty`)) {
        return mixin(queue ~ `.popFront()`);
      }
    }
  }

  return T.init;
}
