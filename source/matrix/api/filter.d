module matrix.api.filter;

import std.json;
import std.typecons : Tuple, tuple;

import matrix;

immutable string EndpointType = "user/%s/filter";

struct Filter(Kind K)
  if (K == Kind.Request)
{
  auto urlParams()
  {
    return tuple(STATE.userId);
  }

  string data()
  {
    return "";
  }

  mixin RequestParameters!(EndpointType, "Filter", HttpMethod.POST);
}

struct Filter(Kind K)
  if (K == Kind.Response)
{
  void parse(const ref JSONValue data)
  {
  }

  mixin ResponseParameters!(EndpointType);
}
