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
  Tid mConnectionTid;
  State mState;

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
      mState.accessToken = response.accessToken;

      // start a sync
      Action syncRequest = Request!Sync();
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
    import std.stdio : writeln;
    writeln(response.value);
  }

private:
  LoginFrame mLoginFrame;
  ChatFrame mChatFrame;

  void process(Action action)
  {
    mConnectionTid.send(action, mState);
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
    mConnectionTid = spawnLinked(&connection, mLoginFrame.server);
    threadsAddIdle(&onIdle, null);

    Action req = Request!Login(mLoginFrame.username, mLoginFrame.password);
    this.process(req);
  }

  bool onCloseWindow(Event event, Widget widget)
  {
    if (mConnectionTid != Tid.init) {
      stopConnection();
    }
    return false;
  }

  void stopConnection()
  {
    mConnectionTid.send(false); // stop connection worker
  }
}

MainWindow mainWindow;