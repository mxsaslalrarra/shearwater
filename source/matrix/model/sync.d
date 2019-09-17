module matrix.model.sync;

import std.json;

struct SyncModel
{
  string nextBatch;
  RoomsModel rooms;
  PresenceModel presence;
  AccountDataModel accountData;

  this(const ref JSONValue data)
  {
    nextBatch = data["next_batch"].str;
    rooms = RoomsModel(data["rooms"]);
    presence = PresenceModel(data["presence"]);
    accountData = AccountDataModel(data["account_data"]);
  }
}

//

struct AccountDataModel
{
  Event[] events;

  this(const ref JSONValue data)
  {
    events = data["events"].array.parseEvents;
  }
}

//

struct PresenceModel
{
  this(const ref JSONValue data)
  {
  }
}

//

struct RoomsModel
{
  this(const ref JSONValue data)
  {
  }
}

//

struct Event
{
  string type;
  JSONValue content;

  this(const ref JSONValue data)
  {
    type = data["type"].str;
    content = data["content"];
  }
}

Event[] parseEvents(const ref JSONValue[] data)
{
  import std.algorithm : map;
  import std.array : array;
  return data.map!(evt => Event(evt)).array;
}
