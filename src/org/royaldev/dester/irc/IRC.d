module org.royaldev.dester.irc.IRC;

import org.royaldev.dester.irc.EventType;
import org.royaldev.dester.irc.LineType;
import org.royaldev.dester.irc.listeners.Listener;

import std.algorithm: equal, startsWith;
import std.array: replace, join;
import std.c.stdlib: exit;
import std.conv: to;
import std.regex: regex, Regex, match;
import std.socket: Socket, SocketException, SocketType, AddressFamily, InternetAddress;
import std.stdio: writeln;
import std.string: isNumeric, split;
import std.utf: UTFException, toUTF8;

public class IRC {
    private Socket s;
    private string nick;
    private Regex!char lineRegex = regex(r"^(:(?P<prefix>\S+) )?(?P<command>\S+)( (?!:)(?P<params>.+?))?( :(?P<trail>.+))?$", "g");
    private bool connected = false;

    private Listener[string] listeners;

    public this(string server) {
        auto parts = server.split(":");
        server = parts[0];
        short port = parts.length > 1 ? to!short(parts[1]) : 6667;
        string pass = parts.length > 2 ? parts[2..$].join(":") : "";
        try {
            s = new Socket(AddressFamily.INET, SocketType.STREAM);
            s.connect(new InternetAddress(server, port));
        } catch (SocketException s) {
            writeln("Couldn't connect!");
            exit(-1);
        }
        if (!pass.equal("")) sendRaw("PASS " ~ pass);
    }

    /**
     * Returns if the connection is still live.
     */
    public bool isAlive() {
        return s.isAlive();
    }

    /**
     * Returns if the bot is actually connected and communicating with the server. This
     * changes to true when the end of MOTD or error message for no MOTD is received,
     * according to RFC standards.
     */
    public bool isConnected() {
        return connected;
    }

    public string getNick() {
        return nick;
    }

    /**
     * Sends a message to the target.
     */
    public void sendMessage(string target, string message) {
        if (!isAlive()) return;
        sendRaw("PRIVMSG " ~ target ~ " :" ~ message);
    }

    /**
     * Sends a raw IRC line to the server. Do not include the linebreak in your line.
     */
    public void sendRaw(string ircLine) {
        if (!isAlive()) return;
        s.send(ircLine ~ "\r\n");
    }

    /**
     * This can only be done once on most IRC servers. This sets the default connection
     * information when connecting. This should be called immediately after construction.
     */
    public void setCredentials(string nick, string realname, string user) {
        if (!isAlive()) return;
        this.nick = nick;
        sendRaw("USER " ~ user ~ " 8 * :" ~ realname);
        sendRaw("NICK " ~ nick);
    }

    public void joinChannel(string channel) {
        sendRaw("JOIN " ~ channel);
    }

    public void partChannel(string channel) {
        sendRaw("PART " ~ channel);
    }

    /**
     * Blockingly reads a line. This will block until it receives "\r\n"
     */
    public string readLine() {
        string line = "";
        with (s) {
            while (isAlive()) {
                char[1] buff;
                auto amt = receive(buff);
                line ~= to!string(buff[0..amt]);
                if (line.length > 2 && line[$-2..$].equal("\r\n")) return line;
            }
        }
        return line;
    }

    private void runListeners(EventType et, Captures!(string, ulong) captures) {
        foreach(listener; listeners.byValue()) if (listener.getEventType() == et) listener.run(captures);
    }

    private void runListeners(LineType lt, Captures!(string, ulong) captures) {
        foreach(listener; listeners.byValue()) if (listener.getLineType() == lt) listener.run(captures);
    }

    /**
     * Starts the bot. This is blocking until the bot is finished, so using this in a thread
     * is advised.
     */
    public void startBot() {
        while (isAlive()) {
            string line;
            try {
                line = toUTF8(readLine().replace("\r\n", ""));
            } catch (UTFException ex) {
                continue;
            }
            writeln(line);
            if (line.startsWith("PING ")) sendRaw("PONG " ~ line[5..$]);
            auto match = line.match(lineRegex);
            if (!match) continue;
            auto captures = match.captures;
            string command = captures["command"];
            if (command.isNumeric()) {
                int code = to!int(command);
                if (code == LineType.RplMotdEnd || code == LineType.ErrNoMotd) connected = true;
                foreach(listener; listeners.byValue()) if (listener.getLineType() == code) listener.run(captures);
                continue;
            }
            if (command.equal("PRIVMSG")) {
                string params = captures["params"];
                string message = captures["trail"];
                if (params.startsWith("#") && !message.startsWith("\x01ACTION")) { // channel message, not action
                    runListeners(EventType.ChannelMessage, captures);
                } else if (params.equal(getNick())) { // private message
                    runListeners(EventType.PrivateMessage, captures);
                }
            } else if (command.equal("INVITE")) {
                runListeners(EventType.Invite, captures);
            }
        }
    }

    public void addListener(string name, Listener listener) {
        if (name !in listeners) listeners[name] = listener;
    }

    public void removeListener(string name) {
        if (name in listeners) listeners.remove(name);
    }

}
