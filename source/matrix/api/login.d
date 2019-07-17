module matrix.api.login;

import std.json : JSONValue, parseJSON;

import matrix.api;
import matrix.api.model : UserIdentifier;

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

  mixin RequestParameters!("login", Method.POST);

private:
  enum string UserIdentifierType = "m.id.user";
}

struct Login(Kind K)
  if (K == Kind.Response)
{
  string accessToken;
  string userId;
  Status status;

  void parse(JSONValue data) {
    accessToken = data["access_token"].str;
    userId = data["user_id"].str;
  }
}