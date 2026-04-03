import Toybox.Application;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Background;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.Time;

const BG_INTERVAL = 600;       // 10 min background refresh
const FG_INTERVAL = 120;       // 2 min foreground refresh

(:background)
class CricketApp extends Application.AppBase {

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
        // Register background temporal event (10 min)
        Background.registerForTemporalEvent(new Time.Duration(BG_INTERVAL));
    }

    function onStop(state as Dictionary?) as Void {
    }

    function getInitialView() as [Views] or [Views, InputDelegates] {
        return [new MainMenuView(), new MainMenuDelegate()];
    }

    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new CricketBackground()];
    }

    function onBackgroundData(data) as Void {
        if (data != null && data instanceof Dictionary) {
            Storage.setValue("matchData", data as Dictionary);
            Storage.setValue("lastFetch", Time.now().value());
        }
        WatchUi.requestUpdate();
    }

    function onSettingsChanged() as Void {
        // User changed team in Garmin Connect — clear cached data
        Storage.deleteValue("matchData");
        Storage.deleteValue("lastFetch");
        WatchUi.requestUpdate();
    }
}
