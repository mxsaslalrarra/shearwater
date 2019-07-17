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

void connection(string url)
{
  bool running = true;

  while (running) {
    receiveTimeout(dur!"msecs"(0),
      (Request!Login request) {
        execute!Login(url, request);
      },
      (bool cont) {
        ownerTid.send(0); // force kill onIdle in main thread
        running = cont;
      },
    );

    Thread.sleep(dur!"seconds"(0));
  }
}

extern(C) static int onIdle(void* data) nothrow
{
  int alive = 1;

  try {
    receiveTimeout(dur!"msecs"(0),
      (Response!Login response) {
        import std.stdio : writeln;
        // update ui here
        writeln(response.status);
      },
      (int kill) {
        alive = kill;
      }
    );
  } catch (Throwable t) {}

  return alive;
}

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