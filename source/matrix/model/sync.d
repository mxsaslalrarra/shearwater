module matrix.model.sync;

import std.json;

E parseSection(T, Data, E = Exception)(ref T result, Data data)
{
  import std.exception : collectException;
  return T(data).collectException(result);
}

void parseAttr(T, Data, E = Exception)(ref T result, Data data)
{
  try
  {
    result = data;
  }
  catch (JSONException e) {}
}

//

struct SyncModel
{
  string nextBatch;
  RoomsModel rooms;
  PresenceModel presence;
  AccountDataModel accountData;

  this(const ref JSONValue data)
  {
    parseAttr(nextBatch, data["next_batch"].str);
    parseSection(rooms, data["rooms"]);
    parseSection(presence, data["presence"]);
    parseSection(accountData, data["account_data"]);
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
  Timeline timeline; // TODO
  Ephemeral ephemeral; // TODO
  AccountDataModel accountData;
  UnreadNotificationCounts unreadNotifications; // TODO

  this(const ref JSONValue data)
  {
    parseSection(summary, data["summary"]);
    parseSection(state, data["state"]);
    parseSection(timeline, data["timeline"]);
    parseSection(ephemeral, data["ephemeral"]);
    parseSection(accountData, data["account_data"]);
    parseSection(unreadNotifications, data["unread_notifications"]);
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
  string[] heroes;
  long joined_member_count;
  long invited_member_count;

  this(const ref JSONValue data)
  {
    import std.conv : to;

    parseAttr(heroes, data["m.heroes"].array.to!(string[]));
    parseAttr(joined_member_count, data["m.joined_member_count"].integer);
    parseAttr(invited_member_count, data["m.invited_member_count"].integer);
  }
}

struct RoomState
{
  StateEvent[] events;

  this(const ref JSONValue data)
  {
    events = data["events"].array.parseEvents!StateEvent;
  }
}

struct StateEvent
{
  JSONValue content;
  string type;
  string eventId;
  string sender;
  long originServerTs;
  UnsignedData unsigned;
  // NOTE in the spec, prevContent is "EventContent" but that isn't defined
  JSONValue prevContent;
  string stateKey;

  this(const ref JSONValue data)
  {
    parseAttr(content, data["content"]);
    parseAttr(type, data["type"].str);
    parseAttr(eventId, data["event_id"].str);
    parseAttr(sender, data["sender"].str);
    parseAttr(originServerTs, data["origin_server_ts"].integer);
    parseSection(unsigned, data["unsigned"]);
    parseAttr(prevContent, data["prev_content"]);
    parseAttr(stateKey, data["state_key"].str);
  }
}

struct UnsignedData
{
  long age;
  Event redactedBecause;
  string transactionId;

  this(const ref JSONValue data)
  {
    parseAttr(age, data["age"].integer);
    parseSection(redactedBecause, data["redacted_because"]);
    parseAttr(transactionId, data["transaction_id"].str);
  }
}

// 

struct Timeline
{
  RoomEvent[] events;
  bool limited;
  string prevBatch;

  // TODO
  this(const ref JSONValue data)
  {
  }
}

//

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
    events = data["events"].array.parseEvents!Event;
  }
}

//

struct PresenceModel
{
  Event[] events;

  this(const ref JSONValue data)
  {
    events = data["events"].array.parseEvents!Event;
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

T[] parseEvents(T)(const ref JSONValue[] data)
{
  import std.algorithm : map;
  import std.array : array;
  return data.map!(evt => T(evt)).array;
}
