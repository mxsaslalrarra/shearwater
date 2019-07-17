module ui.idle;

extern(C) static int onIdle(void* data) nothrow
{
  import std.concurrency : receiveTimeout;
  import core.thread : dur, Thread;
  import matrix.api : Response;
  import matrix.api.login : Login;

  int alive = 1;

  try {
    receiveTimeout(dur!"msecs"(0),
      (Response!Login response) {
        import std.stdio : writeln;
        // update ui here
        writeln(response.status);
      },
      (int kill) {
        alive = kill;
      }
    );
  } catch (Throwable t) {}

  return alive;
}