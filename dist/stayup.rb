cask "stayup" do
  version "1.0.1"
  sha256 "c07db1e5babc8f1ffb686107016a0f28c6fa1bdac406d63614db183b2efb5e95"

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
