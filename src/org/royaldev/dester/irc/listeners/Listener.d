module org.royaldev.dester.irc.listeners.Listener;

import org.royaldev.dester.irc.EventType;
import org.royaldev.dester.irc.LineType;

import std.regex: Captures;

public interface Listener {
    public LineType getLineType();
    public EventType getEventType();

    public void run(Captures!(string, ulong) captures);
}
