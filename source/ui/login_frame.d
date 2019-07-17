module ui.login_frame;

import gtk.Frame;
import gtk.Label;
import gtk.Button;
import gtk.Entry;
import gtk.Box;

class LoginFrame : Frame
{
private:
  Label mError_L;
  Entry mUsername_E, mPassword_E, mServer_E;
  Button mLogin_B;

public:
  this()
  {
    import std.process : env = environment;

    super("");
    this.setLabel(null);

    auto topVbox = new Box(Orientation.VERTICAL, 0);
    auto hbox = new Box(Orientation.HORIZONTAL, 0);
    auto vbox = new Box(Orientation.VERTICAL, 0);

    auto userBox = new Box(Orientation.HORIZONTAL, 0);
    auto lblUsername = new Label("Username");
    userBox.packStart(lblUsername, true, true, 10);
    mUsername_E = new Entry();
    mUsername_E.setText(env.get("SW_USER"));
    userBox.packStart(mUsername_E, false, false, 0);

    vbox.packStart(userBox, false, false, 0);

    auto passwordBox = new Box(Orientation.HORIZONTAL, 0);
    auto lblPassword = new Label("Password");
    passwordBox.packStart(lblPassword, true, true, 10);
    mPassword_E = new Entry();
    mPassword_E.setVisibility(false);
    mPassword_E.setText(env.get("SW_PASS"));
    passwordBox.packStart(mPassword_E, false, false, 0);

    vbox.packStart(passwordBox, false, false, 0);

    auto serverBox = new Box(Orientation.HORIZONTAL, 0);
    auto lblServer = new Label("Server");
    serverBox.packStart(lblServer, true, true, 10);
    mServer_E = new Entry();
    mServer_E.setText(env.get("SW_SERV"));
    serverBox.packStart(mServer_E, false, false, 0);

    vbox.packStart(serverBox, false, false, 0);

    mLogin_B = new Button("Login");
    vbox.packStart(mLogin_B, false, false, 0);

    mError_L = new Label("");
    mError_L.hide();
    vbox.packStart(mError_L, false, false, 0);

    hbox.setCenterWidget(vbox);
    topVbox.setCenterWidget(hbox);

    this.add(topVbox);
  }

  void setupConnections(void delegate(Button) fn)
  {
    // TODO add on activate to each entry widget
    mLogin_B.addOnClicked(fn);
  }

  string username()
  {
    return mUsername_E.getText();
  }

  string password()
  {
    return mPassword_E.getText();
  }

  string server()
  {
    return mServer_E.getText();
  }

  void loginFailed(string message)
  {
    mError_L.setMarkup(`<span color="#FF0000">` ~ message ~ `</span>`);
    mError_L.show();
  }
}