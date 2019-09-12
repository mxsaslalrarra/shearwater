module ui.idle;

import matrix;
import matrix.api;

extern(C) static int onIdle(void* data) nothrow
{
  import std.string : capitalize;

  import ui.main_window : mainWindow;

  try {
    static foreach (Method; Methods)
    {
      mixin(`auto result` ~ Method ~ ` = takeResult!(` ~ Method ~ `!(Kind.Response))();`);
      //auto result = takeResult!(mixin(Method ~ `!(Kind.Response)`))();
      if (mixin(`result` ~ Method).status.ok)
      {
        mixin(`mainWindow.on` ~ mixin(`result` ~ Method).responseType.capitalize ~ `Complete`)(
          mixin(`result` ~ Method)
        );
      }
    }
  } catch (Throwable t) {}

  if (!STATE.connected)
  {
    return 0;
  }

  return 1;
}
