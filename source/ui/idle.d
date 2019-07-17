module ui.idle;

extern(C) static int onIdle(void* data) nothrow
{
  import std.concurrency : receiveTimeout;
  import core.thread : dur, Thread;

  import matrix.api : Response;
  import matrix.api.login : Login;

  import ui.main_window : mainWindow;

  int alive = 1;

  try {
    receiveTimeout(dur!"msecs"(0),
      (Response!Login response) {
        mainWindow.onLoginComplete(response);
      },
      (int kill) {
        alive = kill;
      }
    );
  } catch (Throwable t) {}

  return alive;
}