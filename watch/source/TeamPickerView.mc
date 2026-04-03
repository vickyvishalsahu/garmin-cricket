import Toybox.Graphics;
import Toybox.WatchUi;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Lang;

class TeamPickerView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title => "Select Team"});

        var labels = [
            "India Men",      "India Women",
            "Australia Men",  "Australia Women",
            "England Men",    "England Women",
            "NZ Men",         "NZ Women",
            "SA Men",         "SA Women",
            "Pakistan Men",   "Pakistan Women",
            "Sri Lanka Men",
            "West Indies Men",
            "Bangladesh Men",
            "Afghanistan Men",
            "Zimbabwe Men",
            "Ireland Men"
        ] as Array<String>;

        for (var i = 0; i < labels.size(); i++) {
            addItem(new WatchUi.MenuItem(labels[i], Teams.getCode(i), i, {}));
        }
    }
}

class TeamPickerDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var index = item.getId() as Number;
        Properties.setValue("TeamIndex", index);
        Storage.setValue("teamSelected", true);
        Storage.deleteValue("matchData");
        Storage.deleteValue("lastFetch");
        WatchUi.switchToView(new CricketView(), new CricketDelegate(), WatchUi.SLIDE_LEFT);
    }
}
