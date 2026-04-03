import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Application.Storage;
import Toybox.Application.Properties;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Timer;
import Toybox.Communications;

class CricketView extends WatchUi.View {

    var _timer as Timer.Timer?;
    var _fetchFailed as Boolean = false;

    function initialize() {
        View.initialize();
    }

    function onShow() as Void {
        // Start foreground refresh timer (2 min)
        _timer = new Timer.Timer();
        _timer.start(method(:onFgTimer), FG_INTERVAL * 1000, true);
        // Kick off an immediate foreground fetch
        fetchScore();
    }

    function onHide() as Void {
        if (_timer != null) {
            _timer.stop();
            _timer = null;
        }
    }

    function onFgTimer() as Void {
        fetchScore();
    }

    function fetchScore() as Void {
        var baseUrl = Properties.getValue("WorkerUrl") as String;
        var teamIndex = Properties.getValue("TeamIndex") as Number;
        var team = Teams.getCode(teamIndex);
        var url = baseUrl + "/score?team=" + team;
        Communications.makeWebRequest(
            url,
            null,
            {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onScoreResponse)
        );
    }

    function onScoreResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data != null && data instanceof Dictionary) {
            Storage.setValue("matchData", data as Dictionary);
            Storage.setValue("lastFetch", Time.now().value());
            _fetchFailed = false;
        } else {
            _fetchFailed = true;
        }
        WatchUi.requestUpdate();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        var data = Storage.getValue("matchData") as Dictionary?;
        var teamIndex = Properties.getValue("TeamIndex") as Number;
        var team = Teams.getCode(teamIndex);
        var teamName = Teams.getLabel(teamIndex);

        if (data == null || !(data instanceof Dictionary)) {
            if (_fetchFailed) {
                drawError(dc, cx, h, teamName);
            } else {
                drawNoData(dc, cx, h, teamName);
            }
            return;
        }

        var found = data.get("found");
        if (found == null || !found.equals(true)) {
            drawNotFound(dc, cx, h, teamName);
            return;
        }

        var match = data.get("match") as Dictionary?;
        if (match == null) {
            drawNotFound(dc, cx, h, teamName);
            return;
        }

        var status = match.get("status") as String?;
        if (status != null && status.equals("live")) {
            drawLive(dc, cx, h, match, team);
        } else {
            drawCompleted(dc, cx, h, match, team);
        }

        // Footer: age of data
        drawFooter(dc, cx, h);
    }

    function drawNoData(dc as Dc, cx as Number, h as Number, teamName as String) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h / 2 - 20, Graphics.FONT_SMALL, teamName,
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h / 2 + 10, Graphics.FONT_TINY, "Fetching scores...",
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawError(dc as Dc, cx as Number, h as Number, teamName as String) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h / 2 - 30, Graphics.FONT_SMALL, teamName,
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h / 2, Graphics.FONT_TINY, "Could not connect",
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h / 2 + 25, Graphics.FONT_XTINY, "Press select to retry",
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawNotFound(dc as Dc, cx as Number, h as Number, teamName as String) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h / 2 - 30, Graphics.FONT_SMALL, teamName,
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h / 2, Graphics.FONT_TINY, "No recent matches",
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, h / 2 + 25, Graphics.FONT_XTINY, "Press select to change team",
            Graphics.TEXT_JUSTIFY_CENTER);
    }

    function drawLive(dc as Dc, cx as Number, h as Number, match as Dictionary, team as String) as Void {
        var opponent = match.get("opponent") as String?;
        if (opponent == null) { opponent = "???"; }
        var matchType = match.get("type") as String?;
        if (matchType == null) { matchType = ""; }

        var batting = match.get("batting") as Dictionary?;

        // Header: "IND v AUS · T20" with LIVE indicator
        var y = h / 6;
        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y - 16, Graphics.FONT_XTINY, "LIVE",
            Graphics.TEXT_JUSTIFY_CENTER);

        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var shortTeam = team.substring(0, team.find("_"));
        var header = shortTeam + " v " + opponent;
        if (!matchType.equals("")) {
            header = header + " · " + matchType.toUpper();
        }
        dc.drawText(cx, y, Graphics.FONT_SMALL, header,
            Graphics.TEXT_JUSTIFY_CENTER);

        if (batting != null) {
            // Score: "142/3 (14.2)"
            var batTeam = batting.get("team") as String?;
            if (batTeam == null) { batTeam = "?"; }
            var runs = batting.get("runs");
            var wickets = batting.get("wickets");
            var overs = batting.get("overs") as String?;
            if (overs == null) { overs = "?"; }

            var scoreStr = runs.toString() + "/" + wickets.toString();
            var oversStr = "(" + overs + ")";

            var sy = h / 2 - 10;
            dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, sy - 14, Graphics.FONT_XTINY, batTeam + " batting",
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(cx, sy + 2, Graphics.FONT_MEDIUM, scoreStr,
                Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(cx, sy + 32, Graphics.FONT_TINY, oversStr,
                Graphics.TEXT_JUSTIFY_CENTER);

            // CRR / RRR / Target
            var ry = h * 3 / 4;
            var crr = match.get("crr");
            var rrr = match.get("rrr");
            var target = match.get("target");
            var rateStr = "";
            if (crr != null) {
                rateStr = "CRR " + (crr as Float).format("%.2f");
            }
            if (rrr != null) {
                rateStr = rateStr + "  RRR " + (rrr as Float).format("%.2f");
            }
            if (!rateStr.equals("")) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, ry - 8, Graphics.FONT_XTINY, rateStr,
                    Graphics.TEXT_JUSTIFY_CENTER);
            }
            if (target != null) {
                dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, ry + 8, Graphics.FONT_XTINY, "Target: " + target.toString(),
                    Graphics.TEXT_JUSTIFY_CENTER);
            }
        }
    }

    function drawCompleted(dc as Dc, cx as Number, h as Number, match as Dictionary, team as String) as Void {
        var opponent = match.get("opponent") as String?;
        if (opponent == null) { opponent = "???"; }
        var matchType = match.get("type") as String?;
        if (matchType == null) { matchType = ""; }

        // Header
        var y = h / 6;
        var shortTeam = team.substring(0, team.find("_"));
        var header = shortTeam + " v " + opponent;
        if (!matchType.equals("")) {
            header = header + " · " + matchType.toUpper();
        }
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, y, Graphics.FONT_SMALL, header,
            Graphics.TEXT_JUSTIFY_CENTER);

        // Innings scores
        var innings = match.get("innings") as Array?;
        if (innings != null) {
            var iy = h / 3 + 5;
            for (var i = 0; i < innings.size() && i < 4; i++) {
                var inn = innings[i] as Dictionary;
                var innTeam = inn.get("team") as String?;
                if (innTeam == null) { innTeam = "?"; }
                var runs = inn.get("runs");
                var wkts = inn.get("wickets");
                var overs = inn.get("overs") as String?;
                if (overs == null) { overs = "?"; }

                var line = innTeam + "  " + runs.toString() + "/" + wkts.toString() + " (" + overs + ")";
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
                dc.drawText(cx, iy + (i * 24), Graphics.FONT_TINY, line,
                    Graphics.TEXT_JUSTIFY_CENTER);
            }
        }

        // Result string
        var result = match.get("result") as String?;
        if (result != null) {
            dc.setColor(Graphics.COLOR_YELLOW, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h * 3 / 4 + 5, Graphics.FONT_XTINY, result,
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    function drawFooter(dc as Dc, cx as Number, h as Number) as Void {
        var lastFetch = Storage.getValue("lastFetch") as Number?;
        if (lastFetch != null) {
            var ago = Time.now().value() - lastFetch;
            var mins = ago / 60;
            var footerText;
            if (mins < 1) {
                footerText = "just now";
            } else {
                footerText = mins.toString() + "m ago";
            }
            dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.drawText(cx, h - 22, Graphics.FONT_XTINY, footerText,
                Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

}
