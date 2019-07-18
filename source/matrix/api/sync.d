module matrix.api.sync;

import std.json;

import matrix;

immutable string EndpointType = "sync";

struct Sync(Kind K)
  if (K == Kind.Request)
{
  string[string] params()
  {
    string[string] result;
    return result;
  }

  mixin RequestParameters!(EndpointType, Method.GET);
}

struct Sync(Kind K)
  if (K == Kind.Response)
{
  void parse(JSONValue data)
  {
  }

  mixin ResponseParameters!(EndpointType);
}