class Cointop < Formula
  desc "Interactive terminal based UI application for tracking cryptocurrencies"
  homepage "https://cointop.sh"
  url "https://github.com/miguelmota/cointop/archive/1.2.0.tar.gz"
  sha256 "1848a70457f6e634579619328f1792d68b97a0e2c10118b72b0cacf7e808360c"

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles"
    cellar :any_skip_relocation
    sha256 "a0fe4aa1fd04aab8af64b98c947dcfbbf7e22642c62d381795055817ab6c9c8a" => :mojave
    sha256 "4de9a5503a238cf8d9f110c1aa58b4b29e8ce078652a0e90d40062d9461aae9b" => :high_sierra
    sha256 "dc670756a1f1a98928ce3031396d7bb46d5c39d1d786df70f86fd99991ebc583" => :sierra
    sha256 "cd9d4335c0b88d432a7f9a4f6733647e20e8fdb35aa7285b3d939b3165a92696" => :x86_64_linux
  end

  depends_on "go" => :build

  def install
    ENV["GOPATH"] = buildpath
    src = buildpath/"src/github.com/miguelmota/cointop"
    src.install buildpath.children
    src.cd do
      system "go", "build", "-o", bin/"cointop"
      prefix.install_metafiles
    end
  end

  test do
    system bin/"cointop", "-test"
  end
end
