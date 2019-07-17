module ui.chat;

import gtk.Frame;
import gtk.Box;
import gtk.Label;

class ChatFrame : Frame
{
  this()
  {
    super("");
    this.setLabel(null);

    auto vbox = new Box(Orientation.VERTICAL, 0);

    auto lbl = new Label("Logged in!");
    vbox.setCenterWidget(lbl);

    this.add(vbox);
  }
}