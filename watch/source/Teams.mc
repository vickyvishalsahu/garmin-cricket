import Toybox.Lang;

(:background)
module Teams {
    var CODES as Array<String> = [
        "IND_M", "IND_W",
        "AUS_M", "AUS_W",
        "ENG_M", "ENG_W",
        "NZ_M",  "NZ_W",
        "SA_M",  "SA_W",
        "PAK_M", "PAK_W",
        "SL_M",
        "WI_M",
        "BAN_M",
        "AFG_M",
        "ZIM_M",
        "IRE_M"
    ] as Array<String>;

    var LABELS as Array<String> = [
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

    function getCode(index as Number) as String {
        if (index >= 0 && index < CODES.size()) {
            return CODES[index] as String;
        }
        return "IND_M";
    }

    function getLabel(index as Number) as String {
        if (index >= 0 && index < LABELS.size()) {
            return LABELS[index] as String;
        }
        return "India Men";
    }
}
