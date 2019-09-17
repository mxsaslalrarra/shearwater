module matrix.connection;

import matrix;
import matrix.api;

void connection()
{
  import std.string : toLower;
  import core.thread : Thread, dur;
  import queue : take;

  while (STATE.connected) {
    static foreach (Method; Methods)
    {
      // TODO use std parallelism for execute
      {
        auto request = take!(mixin(Method ~ `!(Kind.Request)`))();
        if (!request.isNull)
        {
          request.execute(STATE.server);
        }
      }
    }

    Thread.sleep(dur!"seconds"( 1 ));
  }
}
