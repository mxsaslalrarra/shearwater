module matrix;

enum Kind {
  Request,
  Response,
}

alias Request(alias T)  = T!(Kind.Request);
alias Response(alias T) = T!(Kind.Response);

alias execute(alias T) = executeRequest!(Request!T);

enum Method {
  GET,
  POST,
}

struct Status
{
  bool ok;
  string message;
}

mixin template RequestParameters(string Endpoint, Method HttpMethod) {
  enum string endpoint = Endpoint;
  enum Method method = HttpMethod;
}

immutable string[string] NULL_PARAMS;

void executeRequest(alias R)(string baseUrl, Request!R request)
{
  import std.concurrency : ownerTid, send;
  import std.format : format;
  import std.json : JSONException, JSONValue, parseJSON;
  import std.net.curl : CurlException, HTTPStatusException;

  alias T = Request!R;

  static assert (__traits(hasMember, Response!R, "parse"));

  string url = buildUrl(baseUrl, request.endpoint);

  static if (T.method == Method.GET) {
    import std.net.curl : get;
    enum http = `get(url)`;
  } else {
    import std.net.curl : post;
    static assert (__traits(hasMember, T, "data"));
    enum http = `post(url, request.data)`;
  }

  Response!R response;

  try {
    JSONValue result = mixin(http ~ `.parseJSON()`);
    response.parse(result);
    response.status = Status(true, "");
  } catch (HTTPStatusException e) {
    response.status = Status(false, "HTTP %d: %s".format(e.status, e.msg));
  } catch (CurlException e) {
    response.status = Status(false, e.msg);
  } catch (JSONException e) {
    response.status = Status(false, e.toString);
  }

  ownerTid.send(response);
}

string makeParamString(const string[string] params, string concat)
{
  import std.format : format;

  string result = concat;

  foreach (k, v; params) {
    result ~= "%s=%s&".format(k, v);
  }

  return result[0 .. $-1];
}

string buildUrl(
    string baseUrl,
    string endpoint,
    string accessToken = "",
    const string[string] params = NULL_PARAMS,
    string apiVersion = "r0",
    string apiSection = "client"
) {
  import std.algorithm : endsWith;
  import std.format : format;

  string concatChar = "?";
  string slash = "/";

  if (baseUrl.endsWith("/")) {
    slash = "";
  }

  string url = "%s%s_matrix/%s/%s/%s".format(
    baseUrl, slash, apiSection, apiVersion, endpoint
  );

  if (accessToken.length != 0) {
    concatChar = "&";
    url ~= "%saccess_token=%s".format("?", accessToken);
  }

  if (params.length != 0) {
    url ~= makeParamString(params, concatChar);
  }

  return url;
}