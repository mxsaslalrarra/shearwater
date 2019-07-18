module matrix.connection;

void connection(string url)
{
  import std.concurrency : ownerTid, receiveTimeout, send;
  import core.thread : Thread, dur;
  import matrix : Action, execute;

  bool running = true;

  while (running) {
    receiveTimeout(dur!"msecs"(0),
      (Action a) => a.execute(url),
      (bool cont) {
        ownerTid.send(0); // force kill onIdle in main thread
        running = cont;
      },
    );

    Thread.sleep(dur!"seconds"(0));
  }
}