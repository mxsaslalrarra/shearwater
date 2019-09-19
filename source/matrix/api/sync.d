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

  string[] getMessages(string room)
  {
    import std.algorithm : filter, map;
    import std.array : array;
    import std.conv : to;

    return model.rooms.join[room]
                .timeline.events
                .filter!(evt => evt.type == "m.text")
                .map!(evt => evt.content["body"].str)
                .array
                .to!(string[]);
  }

  mixin ResponseParameters!(EndpointType);
}
