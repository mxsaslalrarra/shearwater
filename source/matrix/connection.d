module matrix.connection;

void connection(string url)
{
  import std.concurrency : ownerTid, receiveTimeout, send;
  import core.thread : Thread, dur;
  import matrix.api : execute, Request;
  import matrix.api.login;

  bool running = true;

  while (running) {
    receiveTimeout(dur!"msecs"(0),
      (Request!Login request) {
        execute!Login(url, request);
      },
      (bool cont) {
        ownerTid.send(0); // force kill onIdle in main thread
        running = cont;
      },
    );

    Thread.sleep(dur!"seconds"(0));
  }
}