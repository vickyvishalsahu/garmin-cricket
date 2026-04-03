import Toybox.WatchUi;
import Toybox.Application.Properties;
import Toybox.Application.Storage;
import Toybox.Lang;

class MainMenuView extends WatchUi.Menu2 {

    function initialize() {
        Menu2.initialize({:title => "Cricket"});
        addItem(new WatchUi.MenuItem("Favorite Team", null, :fav, {}));
        addItem(new WatchUi.MenuItem("Live Matches", null, :live, {}));
        addItem(new WatchUi.MenuItem("Select Team", null, :team, {}));
    }
}

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {

    function initialize() {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        if (id == :fav) {
            var hasFav = Storage.getValue("teamSelected");
            if (hasFav != null && hasFav.equals(true)) {
                WatchUi.switchToView(new CricketView(), new CricketDelegate(), WatchUi.SLIDE_LEFT);
            } else {
                WatchUi.pushView(new TeamPickerView(), new TeamPickerDelegate(), WatchUi.SLIDE_LEFT);
            }
        } else if (id == :team) {
            WatchUi.pushView(new TeamPickerView(), new TeamPickerDelegate(), WatchUi.SLIDE_LEFT);
        } else if (id == :live) {
            // TODO: live/popular matches — placeholder for now
        }
    }
}
