module org.royaldev.chester.irc.listeners.Listener;

import org.royaldev.chester.irc.LineType;
import org.royaldev.chester.irc.EventType;
import std.regex: RegexMatch, regex, Captures;

public interface Listener {
    public LineType getLineType();
    public EventType getEventType();
    
    public void run(Captures!(string, ulong) captures);
}