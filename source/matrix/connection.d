module matrix.connection;

import matrix;
import matrix.api;

void connection()
{
  import std.string : toLower;
  import core.thread : Thread, dur;

  while (STATE.connected) {
    static foreach (Method; Methods)
    {
      // TODO use std parallelism for execute
      try
      {
        take!(mixin(Method ~ `!(Kind.Request)`), false)().execute(STATE.server);
      } catch (Throwable t) {}
    }

    Thread.sleep(dur!"msecs"( 0 ));
  }
}
