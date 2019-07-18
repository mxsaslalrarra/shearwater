module ui.idle;

extern(C) static int onIdle(void* data) nothrow
{
  import std.concurrency : receiveTimeout;
  import std.string : capitalize;
  import core.thread : dur, Thread;

  import sumtype : match;

  import matrix : Reaction;
  import ui.main_window : mainWindow;

  int alive = 1;

  try {
    receiveTimeout(dur!"msecs"(0),
      (Reaction response) => response.match!(
        (res) =>
          mixin(`mainWindow.on` ~ res.responseType.capitalize ~ `Complete`)(res)
      ),
      (int kill) {
        alive = kill;
      }
    );
  } catch (Throwable t) {}

  return alive;
}