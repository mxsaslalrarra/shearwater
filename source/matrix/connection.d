module matrix.connection;

import matrix;

void connection()
{
  import std.string : toLower;
  import core.thread : Thread, dur;

  bool running = true;

  while (running) {
    static foreach (Method; Methods)
    {
      if (mixin(`!` ~ `work_queue_` ~ Method.toLower ~ `.empty`))
      {
        execute(mixin(`work_queue_` ~ Method.toLower).popFront(), STATE.server);
      }
    }

    // TODO force kill onIdle in main thread

    Thread.sleep(dur!"msecs"( 0 ));
  }
}
