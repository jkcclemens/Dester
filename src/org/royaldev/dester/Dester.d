module org.royaldev.dester.Dester;

import core.thread: Thread;

import org.royaldev.dester.irc.EventType;
import org.royaldev.dester.irc.IRC;
import org.royaldev.dester.irc.LineType;
import org.royaldev.dester.irc.listeners.Listener;

import std.algorithm: startsWith, canFind;
import std.array: strip, split, join;
import std.c.stdlib: exit;
import std.getopt: getopt, config;
import std.math: floor;
import std.random: randomSample;
import std.regex: rreplace = replace;
import std.stdio: writeln, File;
import std.string: toLower;

string nickname = "Dester";
string server = null;
short port = 6667;
string password = "";
string channel = "";
string nickservPassword = "";

private Dester dester;

extern(C) private void shutdown(int value) {
    writeln("\nShutting down...");
    dester.shutdown();
    exit(1);
}

private void main(string[] args) {
    version (Posix) {
        import core.sys.posix.signal: sigset, SIGINT;
        sigset(SIGINT, &shutdown);
    }
    bool displayHelp = false;
    getopt(
        args,
        config.caseSensitive,
        config.bundling,
        config.passThrough,
        "n|nickname", &nickname,
        "p|port", &port,
        "P|password|server-password", &password,
        "s|server", &server,
        "c|channel|channels", &channel,
        "N|nickserv|nickserv-password", &nickservPassword,
        "h|help", &displayHelp
    );
    if (displayHelp) {
        writeln("Usage: -s server [-c \"#channel1 #channel2\"] [-p port] [-P password] [-n nickname] [-N nickservPassword] [-h]");
        writeln("-s | --server\n\tRequired\n\tSets the server that the bot will attempt to connect to.");
        writeln("-c | --channel | --channels\n\tSets the channels that the bot will join on connection.\n\tIf this is not set, the bot will join no channels by default.");
        writeln("-p | --port\n\tSets the port of the server to join.\n\tDefault to 6667.");
        writeln("-P | --password | --server-password\n\tSets the password used to connect to the server.");
        writeln("-n | --nickname\n\tSets the nickname of the bot.\n\tDefaults to Dester.");
        writeln("-N | --nickserv | --nickserv-password\n\tSets the password to use to authenticate with NickServ after joining the server.");
        writeln("-h | --help\n\tDisplays this help.");
        exit(0);
    }
    if (server is null) {
        writeln("Missing required arguments. Try " ~ args[0] ~ " -h for help.");
        exit(1);
    }
    dester = new Dester();
}

public class Dester {

    void shutdown() {
        irc.shutdown();
    }

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

    public this() {
        irc = new IRC(server);
        irc.setCredentials(nickname, "Dester", nickname);
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
                if (!nickservPassword.equal("")) irc.sendMessage("NickServ", "IDENTIFY " ~ nickservPassword);
                foreach (channelName; channel.split(" ")) irc.joinChannel(channelName);
            }
        });
        irc.addListener("mention", new class Listener {
            override public LineType getLineType() {
                return LineType.RplNone;
            }
            override public EventType getEventType() {
                return EventType.ChannelMessage;
            }
            override public void run(Captures!(string, ulong) captures) {
                string message = captures["trail"];
                string[] margs = message.split(" ")[1..$];
                string channel = captures["params"];
                if (message.toLower().canFind(nickname.toLower())) {
                    auto randMessage = scrambleWord();
                    randMessage = truncate(randMessage, 300).rreplace(regex(r"<.*?>"), "").rreplace(regex(r"\\[.*?\\]"), "");
                    irc.sendMessage(channel, randMessage);
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
                if (message.toLower().startsWith("join") && margs.length > 0) irc.joinChannel(margs[0]);
                else if (message.toLower().startsWith("part") && margs.length > 0) irc.partChannel(margs[0]);
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
