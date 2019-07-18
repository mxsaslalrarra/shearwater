module ui.chat;

import gtk.Frame;
import gtk.Box;
import gtk.Label;
import gtk.Entry;
import gtk.ScrolledWindow;
import gtk.Paned;

import ui.chat_pane;
import ui.room_list;

class ChatFrame : Frame
{
  this()
  {
    super("");
    this.setLabel(null);

    auto hbox = new Paned(Orientation.HORIZONTAL);

    auto roomListScroll = new ScrolledWindow();

    auto roomList = new RoomList();
    roomListScroll.add(roomList);

    hbox.pack1(roomListScroll, true, false);

    auto vbox = new Box(Orientation.VERTICAL, 0);

    auto chatPane = new ChatPane();
    vbox.packStart(chatPane, true, true, 0);

    auto chatEntry = new Entry();
    vbox.packStart(chatEntry, false, false, 0);

    hbox.pack2(vbox, true, false);

    hbox.setPosition(150);
    this.add(hbox);

    this.showAll();
  }
}