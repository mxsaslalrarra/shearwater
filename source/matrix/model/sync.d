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

struct RoomsModel
{
  JoinedRoom[string] join;
  InvitedRoom[string] invite;
  LeftRoom[string] leave;

  this(const ref JSONValue data)
  {
    join = JoinedRoom.parse(data["join"]);
  }
}

//

struct JoinedRoom
{
  RoomSummary summary;
  RoomState state;
  Timeline timeline;
  Ephemeral ephemeral;
  AccountDataModel accountData;
  UnreadNotificationCounts unreadNotifications;

  this(const ref JSONValue data)
  {
    summary = RoomSummary(data["summary"]);
    state = RoomState(data["state"]);
    timeline = Timeline(data["timeline"]);
    ephemeral = Ephemeral(data["ephemeral"]);
    accountData = AccountDataModel(data["account_data"]);
    unreadNotifications = UnreadNotificationCounts(data["unread_notifications"]);
  }

  static JoinedRoom[string] parse(const ref JSONValue data)
  {
    JoinedRoom[string] result;

    foreach (string room, ref roomData; data.object)
    {
      result[room] = JoinedRoom(roomData);
    }

    return result;
  }
}

struct RoomSummary
{
  // TODO
  this(const ref JSONValue data)
  {
  }
}

struct RoomState
{
  // TODO
  this(const ref JSONValue data)
  {
  }
}

struct Timeline
{
  // TODO
  this(const ref JSONValue data)
  {
  }
}

struct Ephemeral
{
  // TODO
  this(const ref JSONValue data)
  {
  }
}

struct UnreadNotificationCounts
{
  // TODO
  this(const ref JSONValue data)
  {
  }
}

//

struct InvitedRoom
{
  // TODO
  this(const ref JSONValue data)
  {
  }
}

struct LeftRoom
{
  // TODO
  this(const ref JSONValue data)
  {
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
  Event[] events;

  this(const ref JSONValue data)
  {
    events = data["events"].array.parseEvents;
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
