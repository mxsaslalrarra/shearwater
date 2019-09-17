module matrix.model;

import std.json : JSONValue;

struct UserIdentifier(string Type)
{
  static if (Type == "m.id.user") {
    string user;
  } else {
    static assert (0);
  }

  string key = "identifier";

  JSONValue data() {
    return JSONValue( [ "user": user, "type": Type ] );
  }
}
