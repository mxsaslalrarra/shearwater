import std.concurrency;
import std.stdio : writeln;

import matrix.api;
import matrix.api.login;

void idle(string url)
{
  import core.thread : Thread;
  import core.time : dur;

  bool running = true;

  while (running) {
    receiveTimeout(dur!"msecs"(0),
      (Request!Login request) {
        execute!Login(url, request);
      },
      (bool cont) {
        running = cont;
      },
    );

    Thread.sleep(dur!"seconds"(0));
  }
}

void main()
{
  import std.process : environment;

  string serv = environment.get("SW_SERV");
  string user = environment.get("SW_USER");
  string pass = environment.get("SW_PASS");

  if (serv.length == 0 || user.length == 0 || pass.length == 0) {
    writeln("Missing dev environment vars");
    return;
  }

  auto tid = spawn(&idle, serv);

  auto req = Request!Login(user, pass);
  tid.send(req);

  receive(
    (Response!Login res) {
      writeln(res.status);
    }
  );

  tid.send(false);
}
