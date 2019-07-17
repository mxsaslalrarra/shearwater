import std.concurrency;
import std.stdio : writeln;

import gtk.Application : Application;
import gio.Application: GioApplication = Application;
import gtk.ApplicationWindow: ApplicationWindow;
import gtkc.giotypes: GApplicationFlags;

import ui.main_window;

int main(string[] args)
{
    auto app = new Application("re.b5.shearwater", GApplicationFlags.FLAGS_NONE);
    app.addOnActivate(delegate void(GioApplication _) {
        mainWindow = new MainWindow(app);
    });
    return app.run(args);
}