module matrix.api.login;

import std.json : JSONValue, parseJSON;

import matrix;
import matrix.model : UserIdentifier;

immutable string EndpointType = "login";

struct Login(Kind K)
  if (K == Kind.Request)
{
  UserIdentifier!UserIdentifierType user;
  string password;
  string type = "m.login.password";

  this (string username, string password) {
    this.user = UserIdentifier!UserIdentifierType(username);
    this.password = password;
  }

  string data() {
    JSONValue data = [ "password" : password, "type" : type ];
    data.object[user.key] = user.data;

    return data.toString;
  }

  mixin RequestParameters!(EndpointType, HttpMethod.POST, false);

private:
  enum string UserIdentifierType = "m.id.user";
}

struct Login(Kind K)
  if (K == Kind.Response)
{
  string accessToken;
  string userId;

  void parse(JSONValue data) {
    accessToken = data["access_token"].str;
    userId = data["user_id"].str;
  }

  mixin ResponseParameters;
}
