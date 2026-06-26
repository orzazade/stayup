cask "stayup" do
  version "1.0.0"
  sha256 "0000000000000000000000000000000000000000000000000000000000000000"

  url "https://github.com/orzazade/stayup/releases/download/v#{version}/stayup-#{version}.zip"
  name "stayup"
  desc "Menu bar app that keeps you Available in Teams & Slack"
  homepage "https://github.com/orzazade/stayup"

  depends_on macos: ">= :ventura"

  app "stayup.app"

  zap trash: [
    "~/Library/Preferences/com.scifi.stayup.plist",
  ]
end
