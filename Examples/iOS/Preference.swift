struct Preference {
    static var defaultInstance = Preference()

    var uri: String? = "rtmp://192.168.1.10/live"
    var streamName: String? = "live"
}
