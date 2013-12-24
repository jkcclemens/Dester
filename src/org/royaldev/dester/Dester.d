module org.royaldev.dester.Dester;

import core.thread: Thread;

import org.royaldev.dester.irc.EventType;
import org.royaldev.dester.irc.IRC;
import org.royaldev.dester.irc.LineType;
import org.royaldev.dester.irc.listeners.Listener;

import std.algorithm: startsWith, canFind;
import std.array: strip, split, join;
import std.math: floor;
import std.random: randomSample;
import std.regex: rreplace = replace;
import std.stdio: writeln, File;
import std.string: toLower;

private void main(string[] args) {
  if (args.length < 4) {
    writeln("Usage: " ~ args[0] ~ " nickname server(:port)(:pass) channel (nickserv pass)");
    return;
  }
  new Dester(args[1..$]);
}

public class Dester {
    private class IRCLauncher : Thread {
        private IRC irc;
        private this(IRC irc) {
            this.irc = irc;
            super(&run);
        }

        private : void run() {
            irc.startBot();
        }
    }

  /**
  * This defines if the bot should allow the "msg" command in private messages. This is useful for registering in
  * NickServ.
  */
  private bool allowmsg = false;

  private IRC irc;
  private string[] storage;

  public this(string[] args) {
    string nick = args[0];
    string serv = args[1];
    string chan = args[2];
    irc = new IRC(serv);
    irc.setCredentials(nick, "Dester", nick);
    auto botThread = new IRCLauncher(irc);
    botThread.start();
    irc.addListener("welcome", new class Listener {
        override public LineType getLineType() {
            return LineType.RplWelcome;
        }
        override public EventType getEventType() {
            return EventType.None;
        }
        override public void run(Captures!(string, ulong) captures) {
            loadBrain();
            irc.sendRaw("MODE " ~ irc.getNick() ~ " +B");
            if (args.length > 3) irc.sendMessage("NickServ", "IDENTIFY " ~ args[3]);
            foreach (channel; chan.split(" ")) irc.joinChannel(channel);
        }
    });
    irc.addListener("mention", new class Listener {
        override public LineType getLineType() {
            return LineType.RplNone;;
        }
        override public EventType getEventType() {
            return EventType.ChannelMessage;
        }
        override public void run(Captures!(string, ulong) captures) {
            string message = captures["trail"];
            string[] margs = message.split(" ")[1..$];
            string channel = captures["params"];
            if (message.toLower().canFind(nick.toLower())) {
                auto randMessage = scrambleWord();
                randMessage = truncate(randMessage, 300).rreplace(regex(r"<.*?>"), "").rreplace(regex(r"\\[.*?\\]"), "");
                irc.sendMessage(channel, randMessage);
            } else if (message.toLower().startsWith("!hi")) {
                irc.sendMessage(channel, "Hi!");
            } else if (message.toLower().startsWith("!join") && margs.length > 0) {
                irc.joinChannel(margs[0]);
            } else if (message.toLower().startsWith("!part") && margs.length > 0) {
                irc.partChannel(margs[0]);
            } else {
                write(message);
                storage ~= message;
            }
        }
    });
    irc.addListener("privmsgcommands", new class Listener {
        override public LineType getLineType() {
            return LineType.RplNone;;
        }
        override public EventType getEventType() {
            return EventType.PrivateMessage;
        }
        override public void run(Captures!(string, ulong) captures) {
            string message = captures["trail"];
            string[] margs = message.split(" ")[1..$];
            string channel = captures["params"];
            if (message.toLower().startsWith("join") && margs.length > 0)  {
                irc.joinChannel(margs[0]);
            } else if (message.toLower().startsWith("!part") && margs.length > 0) {
                irc.partChannel(margs[0]);
            }
        }
    });
    irc.addListener("invited", new class Listener {
        override public LineType getLineType() {
            return LineType.RplNone;;
        }
        override public EventType getEventType() {
            return EventType.Invite;
        }
        override public void run(Captures!(string, ulong) captures) {
            irc.joinChannel(captures["trail"]);
        }
    });
  }

  private void write(string sentence) {
    auto f = new File("dester.brain", "a");
    f.writeln(sentence);
    f.flush();
    f.close();
  }

  private void loadBrain() {
    auto f = new File("dester.brain", "a+");
    f.rewind();
    string output;
    while ((output = f.readln()) !is null) {
      output = output.replace("\n", "").strip();
      if (output.length < 1) continue;
      writeln(output);
      storage ~= output;
    }
    f.close();
  }

  private string truncate(string s, int len) {
    if (s !is null && s.length > len) s = s[0..len];
    return s;
  }

  private string scrambleWord() {
    if (storage.length < 2) return "I have no words.";
    auto rand = randomSample(storage, 2);
    string randMessage = rand.front();
    rand.popFront();
    string secondPart = rand.front();
    string[] wordsOne = randMessage.split(" ");
    string[] wordsTwo = secondPart.split(" ");
    string send = "";
    for (int i = 0; i <= floor(wordsOne.length / 2.0); i++) send ~= wordsOne[i] ~ " ";
    for (int i = cast(int) floor(wordsTwo.length / 2.0); i < wordsTwo.length; i++) send ~= wordsTwo[i] ~ " ";
    return send[0..$-1];
  }

}
