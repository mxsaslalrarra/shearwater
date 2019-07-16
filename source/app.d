import std.concurrency;
import std.stdio : writeln;

void main()
{
  import matrix.api;
  import matrix.api.login;

  string baseUrl = "https://matrix.org/";

  auto tid = spawn(&execute!Login, baseUrl, "", "");

  receive(
    (Response!Login res) {
      writeln(res.status);
    }
  );
}
