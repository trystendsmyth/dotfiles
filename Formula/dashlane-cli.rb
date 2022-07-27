require "language/node"

class DashlaneCli < Formula
  desc "A non-official Dashlane CLI"
  homepage "https://dashlane.com"
  url "https://github.com/Dashlane/dashlane-cli/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "ce4fef1101389fb0cf48e43019f068a4ef8e3aaf7bf98ebe6754917b356e2a68"
  license "Apache-2.0"

  depends_on "node"

  def install
    Language::Node.setup_npm_environment
    system "npm", "install", *Language::Node.local_npm_install_args
    system "npm", "run", "build"

    system "npm", "install", *Language::Node.std_npm_install_args(libexec)
    bin.install_symlink Dir["#{libexec}/bin/*"]
  end

  test do
    assert_equal version.to_s, shell_output("#{bin}/dcli --version").chomp
  end
end
