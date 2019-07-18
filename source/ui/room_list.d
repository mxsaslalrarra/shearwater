module ui.room_list;

import gtk.ListStore;
import gtk.TreeView;
import gtk.TreeIter;
import gtk.TreeViewColumn;
import gtk.CellRendererText;

import gobject.c.types;

class RoomList : TreeView
{
  RoomTreeViewColumn roomTreeViewColumn;
  RoomListStore roomListStore;

  this()
  {
    super();

    roomListStore = new RoomListStore();
    setModel(roomListStore);

    roomTreeViewColumn = new RoomTreeViewColumn();
    appendColumn(roomTreeViewColumn);
  }
}

class RoomListStore : ListStore
{
  string[] items;
  TreeIter treeIter;

  this()
  {
    super([GType.STRING]);

    for(int i; i < items.length; i++)
    {
      string message = items[i];
      treeIter = createIter();
      setValue(treeIter, 0, message);
    }
  }
}

class RoomTreeViewColumn : TreeViewColumn
{
  CellRendererText cellRendererText;
  string columnTitle = "Rooms";
  string attributeType = "text";
  int columnNumber = 0; // numbering starts at '0'

  this()
  {
    cellRendererText = new CellRendererText();
    super(columnTitle, cellRendererText, attributeType, columnNumber);
  }
}