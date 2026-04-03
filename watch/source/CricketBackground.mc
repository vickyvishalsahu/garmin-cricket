import Toybox.Background;
import Toybox.Communications;
import Toybox.Application.Properties;
import Toybox.System;
import Toybox.Lang;

(:background)
class CricketBackground extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
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
            method(:onBgResponse)
        );
    }

    function onBgResponse(responseCode as Number, data as Dictionary or String or Null) as Void {
        if (responseCode == 200 && data != null && data instanceof Dictionary) {
            Background.exit(data as Dictionary);
        } else {
            Background.exit(null);
        }
    }
}
