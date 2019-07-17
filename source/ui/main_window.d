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

import matrix.api;
import matrix.api.login;
import matrix.connection : connection;
import ui.idle : onIdle;

class MainWindow : ApplicationWindow
{
private:
  Tid mConnectionTid;

public:
  this(Application app) {
    super(app);

    this.addOnDelete(&onCloseWindow);

    setDefaultSize(1024, 768);
    setTitle("Shearwater");

    this.initLoginUI();

    this.showAll();
  }

private:
  void initLoginUI() {
    auto btn = new Button("Login");
    btn.addOnClicked(&onLogin);
    this.add(btn);
  }

  void onLogin(Button btn) {
    import std.process : env = environment;
    mConnectionTid = spawnLinked(&connection, env.get("SW_SERV"));
    threadsAddIdle(&onIdle, null);

    auto req = Request!Login(env.get("SW_USER"), env.get("SW_PASS"));
    mConnectionTid.send(req);
  }

  bool onCloseWindow(Event event, Widget widget) {
    mConnectionTid.send(false); // stop connection worker
    return false;
  }
}

MainWindow mainWindow;