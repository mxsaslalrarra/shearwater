module ui.chat_pane;

import gtk.ScrolledWindow;
import gtk.TextBuffer;
import gtk.TextView;

class ChatPane : ScrolledWindow
{
private:
  TextView content;
  TextBuffer buffer;

public:
  this()
  {
    super();

    content = new TextView();
    buffer = content.getBuffer();
    content.setEditable(false);

    this.add(content);
  }

  void addMessage(string message)
  {
    content.appendText(message);
  }

  void addMessages(string[] messages)
  {
    foreach (ref message; messages)
    {
      addMessage(message);
    }
    this.showAll();
  }
}
