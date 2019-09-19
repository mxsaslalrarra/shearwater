module ui.main_window;

import std.experimental.logger : fatal;
import std.concurrency;

import core.thread : Thread;
import core.time : dur;

import gdk.Event;
import gdk.Threads;

import gtk.Application : Application;
import gtk.ApplicationWindow: ApplicationWindow;
import gtk.Button;
import gtk.Widget;

import matrix;
import matrix.api.login;
import matrix.api.sync;
import matrix.connection : connection;

import ui.idle : onIdle;
import ui.chat : ChatFrame;
import ui.login_frame : LoginFrame;

class MainWindow : ApplicationWindow
{
private:
  Thread mWorker;

public:
  this(Application app)
  {
    super(app);

    this.addOnDelete(&onCloseWindow);

    setDefaultSize(1024, 768);
    setTitle("Shearwater");

    this.initLoginUI();

    this.showAll();
  }

  void onLoginComplete(Response!Login response)
  {
    if (!response.status.ok) {
      mLoginFrame.loginFailed("Failed to log in");
      stopConnection();
    } else {
      STATE.accessToken = response.accessToken;
      STATE.userId = response.userId;

      // start a sync
      auto syncRequest = Request!Sync();
      this.process(syncRequest);

      // remove login form and show main ui
      mLoginFrame.hide();
      this.remove(mLoginFrame);
      mLoginFrame = null;

      this.initChatUI();
    }
  }

  void onSyncComplete(Response!Sync response)
  {
    import std.algorithm : filter, map;
    import std.array : array;
    import std.stdio : writeln;
    auto roomId = response.model.rooms.join.keys[0];
    writeln(
        response.model.rooms.join[roomId].timeline.events
                .filter!(evt => evt.type == "m.text")
                .array
    );
  }

private:
  LoginFrame mLoginFrame;
  ChatFrame mChatFrame;

  void process(T)(T action)
  {
    import queue : put;
    put!T(action);
  }

  void initLoginUI()
  {
    mLoginFrame = new LoginFrame();
    mLoginFrame.setupConnections(&onLogin);
    this.add(mLoginFrame);
  }

  void initChatUI()
  {
    mChatFrame = new ChatFrame();
    this.add(mChatFrame);
    this.showAll();
  }

  void onLogin(Button btn)
  {
    STATE.connected = true;
    mWorker = new Thread(&connection).start();
    threadsAddTimeoutSeconds(1, &onIdle, null);

    STATE.server = mLoginFrame.server;
    auto req = Request!Login(mLoginFrame.username, mLoginFrame.password);
    this.process(req);
  }

  bool onCloseWindow(Event event, Widget widget)
  {
    if (STATE.connected) {
      stopConnection();
    }
    return false;
  }

  void stopConnection()
  {
    STATE.connected = false;
    mWorker.join();
  }
}

MainWindow mainWindow;
