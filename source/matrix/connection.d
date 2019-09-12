module matrix.connection;

import matrix;

void connection()
{
  import std.string : toLower;
  import core.thread : Thread, dur;

  while (STATE.connected) {
    static foreach (Method; Methods)
    {
      if (mixin(`!` ~ `work_queue_` ~ Method.toLower ~ `.empty`))
      {
        execute(mixin(`work_queue_` ~ Method.toLower).popFront(), STATE.server);
      }
    }

    Thread.sleep(dur!"msecs"( 0 ));
  }
}
