module ui.chat_pane;

import gtk.ScrolledWindow;

class ChatPane : ScrolledWindow
{
  this()
  {
    super();

    import gtk.Entry;
    auto e = new Entry();
    e.setText("lol");

    this.add(e);
  }
}