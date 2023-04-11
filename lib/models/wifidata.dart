class WifiData {
  late String ssid, bssid, level, building;
  late List<dynamic> link;

  WifiData({
    required this.ssid, 
    required this.bssid, 
    required this.level,
    required this.building,
    required this.link,
  });
}
