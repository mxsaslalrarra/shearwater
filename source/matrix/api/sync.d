module matrix.api.sync;

import std.json;
import std.experimental.logger : warning;

import matrix;
import matrix.model.sync;

immutable string EndpointType = "sync";

struct Sync(Kind K)
  if (K == Kind.Request)
{
  string[string] params() const
  {
    string[string] result;
    return result;
  }

  mixin RequestParameters!(EndpointType, HttpMethod.GET);
}

struct Sync(Kind K)
  if (K == Kind.Response)
{
  SyncModel model;

  void parse(const ref JSONValue data)
  {
    try
    {
      model = SyncModel(data);
    }
    catch (JSONException e)
    {
      warning("Sync model failed to parse correctly");
    }
  }

  mixin ResponseParameters!(EndpointType);
}
