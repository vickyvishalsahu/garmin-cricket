import Toybox.Lang;
import Toybox.WatchUi;

class CricketDelegate extends WatchUi.BehaviorDelegate {

    function initialize() {
        BehaviorDelegate.initialize();
    }

    function onNextPage() as Lang.Boolean {
        WatchUi.pushView(new SettingsHintView(), new SettingsHintDelegate(), WatchUi.SLIDE_UP);
        return true;
    }

    function onSelect() as Lang.Boolean {
        var view = WatchUi.getCurrentView();
        if (view[0] instanceof CricketView) {
            var cv = view[0] as CricketView;
            if (cv._fetchFailed) {
                cv._fetchFailed = false;
                cv.fetchScore();
                WatchUi.requestUpdate();
                return true;
            }
        }
        WatchUi.pushView(new TeamPickerView(), new TeamPickerDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
}
