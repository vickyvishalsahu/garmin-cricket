import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

class SettingsHintView extends WatchUi.View {

    function initialize() {
        View.initialize();
    }

    function onUpdate(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.clear();

        var cx = dc.getWidth() / 2;
        var cy = dc.getHeight() / 2;

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
        dc.drawText(cx, cy - 20, Graphics.FONT_TINY, "Change team in",
            Graphics.TEXT_JUSTIFY_CENTER);
        dc.drawText(cx, cy + 4, Graphics.FONT_TINY, "Garmin Connect app",
            Graphics.TEXT_JUSTIFY_CENTER);
    }
}

class SettingsHintDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onBack() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }

    function onPreviousPage() as Lang.Boolean {
        WatchUi.popView(WatchUi.SLIDE_DOWN);
        return true;
    }
}
