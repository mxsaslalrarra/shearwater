import std.concurrency;
import std.stdio : writeln;

void main()
{
  import std.process : environment;

  import matrix.api;
  import matrix.api.login;

  string serv = environment.get("SW_SERV");
  string user = environment.get("SW_USER");
  string pass = environment.get("SW_PASS");

  if (serv.length == 0 || user.length == 0 || pass.length == 0) {
    writeln("Missing dev environment vars");
    return;
  }

  // Might be ok to spawn a thread for these events so long as there is
  // a long running one for sync
  // ^ Perhaps use a template flag + static if for whether to use a while
  // loop in executeRequest
  auto tid = spawn(&execute!Login, serv, user, pass);

  receive(
    (Response!Login res) {
      writeln(res.status);
    }
  );
}
