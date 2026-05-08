class Cvm < Formula
  desc "nvm-style version manager for Claude Code"
  homepage "https://github.com/cvm-sh/cvm"
  url "https://github.com/cvm-sh/cvm/archive/refs/tags/v0.0.2.tar.gz"
  version "0.0.2"
  sha256 :no_check
  license "MIT"

  depends_on "node"

  def install
    libexec.install Dir["*"]
    (bin/"cvm-installer").write <<~EOS
      #!/bin/bash
      exec "#{libexec}/install.sh" "$@"
    EOS
    chmod 0755, bin/"cvm-installer"
  end

  def caveats
    <<~EOS
      To finish installing cvm, run:

        cvm-installer

      Then restart your shell or source your shell profile.

      To uninstall later, run:

        cvm-uninstaller
    EOS
  end

  test do
    assert_match "Claude Version Manager", shell_output("bash -lc '. #{libexec}/cvm.sh && cvm help'")
  end
end
