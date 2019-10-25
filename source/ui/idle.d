module ui.idle;

import matrix;
import matrix.api;

extern(C) static int onIdle(void* data) nothrow
{
  import std.string : capitalize;
  import queue : take;
  import ui.main_window : mainWindow;

  static foreach (Method; Methods)
  {
    try
    {
      auto result = take!(mixin(Method ~ `!(Kind.Response)`))();
      if (!result.isNull && result.get.status.ok)
      {
        mixin(`mainWindow.on` ~ result.get.responseType.capitalize ~ `Complete`)(result.get);
      }
    } catch (Throwable t) {}
  }

  if (!STATE.connected)
  {
    return 0;
  }

  return 1;
}
