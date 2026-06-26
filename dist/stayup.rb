cask "stayup" do
  version "1.0.0"
  sha256 "9f3b3b44045bd224f8e8ec4c4faa0053a1de3b9d3ab7255e16c134844b5fbb40"

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
