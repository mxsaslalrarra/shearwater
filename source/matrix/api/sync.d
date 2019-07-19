module matrix.api.sync;

import std.json;

import matrix;

immutable string EndpointType = "sync";

struct Sync(Kind K)
  if (K == Kind.Request)
{
  string[string] params() const
  {
    string[string] result;
    return result;
  }

  mixin RequestParameters!(EndpointType, Method.GET);
}

struct Sync(Kind K)
  if (K == Kind.Response)
{
  string value;

  void parse(JSONValue data)
  {
    value = data.toPrettyString();
  }

  mixin ResponseParameters!(EndpointType);
}