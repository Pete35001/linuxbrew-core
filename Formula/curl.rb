class Curl < Formula
  desc "Get a file from an HTTP, HTTPS or FTP server"
  homepage "https://curl.haxx.se/"
  url "https://curl.haxx.se/download/curl-7.64.1.tar.bz2"
  mirror "http://curl.mirror.anstey.ca/curl-7.64.1.tar.bz2"
  sha256 "4cc7c738b35250d0680f29e93e0820c4cb40035f43514ea3ec8d60322d41a45d"

  bottle do
    cellar :any
    root_url "https://linuxbrew.bintray.com/bottles"
    sha256 "78f8672e9458cf3ed13f1695269e8554148fb5bd74a668123970a5faf46b6d46" => :mojave
    sha256 "df8ce79cb806192943d07b93ab0bfa9c18f938261f733ce0eaefb73c17c78949" => :high_sierra
    sha256 "d4c2fe1328ac7ac25d4e22605b772fd640ba505d205691ffbce53df2946396d7" => :sierra
    sha256 "36502980f0e1e6f05f751d923b6178565780905aae35df9c26a5860c6469d73e" => :x86_64_linux
  end

  pour_bottle? do
    reason "The bottle needs to be installed into #{Homebrew::DEFAULT_PREFIX} when built with OpenSSL."
    satisfy { OS.mac? || HOMEBREW_PREFIX.to_s == Homebrew::DEFAULT_PREFIX }
  end

  head do
    url "https://github.com/curl/curl.git"

    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  keg_only :provided_by_macos

  depends_on "pkg-config" => :build
  depends_on "openssl" unless OS.mac?

  def install
    system "./buildconf" if build.head?

    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --disable-silent-rules
      --prefix=#{prefix}
    ]

    if OS.mac?
      args << "--with-darwinssl"
      args << "--without-ca-bundle"
      args << "--without-ca-path"
    else
      ENV.prepend_path "PKG_CONFIG_PATH", "#{Formula["openssl"].opt_lib}/pkgconfig"
      args << "--with-ssl=#{Formula["openssl"].opt_prefix}"
      args << "--with-ca-bundle=#{etc}/openssl/cert.pem"
      args << "--with-ca-path=#{etc}/openssl/certs"
      args << "--disable-ares"
      args << "--disable-ldap"
    end

    system "./configure", *args
    system "make", "install"
    system "make", "install", "-C", "scripts"
    libexec.install "lib/mk-ca-bundle.pl"
  end

  test do
    # Fetch the curl tarball and see that the checksum matches.
    # This requires a network connection, but so does Homebrew in general.
    filename = (testpath/"test.tar.gz")
    system "#{bin}/curl", "-L", stable.url, "-o", filename
    filename.verify_checksum stable.checksum

    system libexec/"mk-ca-bundle.pl", "test.pem"
    assert_predicate testpath/"test.pem", :exist?
    assert_predicate testpath/"certdata.txt", :exist?
  end
end
