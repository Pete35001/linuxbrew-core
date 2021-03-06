class GnuSed < Formula
  desc "GNU implementation of the famous stream editor"
  homepage "https://www.gnu.org/software/sed/"
  url "https://ftp.gnu.org/gnu/sed/sed-4.7.tar.xz"
  mirror "https://ftpmirror.gnu.org/sed/sed-4.7.tar.xz"
  sha256 "2885768cd0a29ff8d58a6280a270ff161f6a3deb5690b2be6c49f46d4c67bd6a"

  bottle do
    rebuild 2
    sha256 "f519013891bc629f64d4ebbd37869007b73480f501185d1e7d1e7e771fe66502" => :mojave
    sha256 "8ad20319d307e03c34ba4c38027b27d091b3774dc5f8daaaba41c3b02b76ebd0" => :high_sierra
    sha256 "b195a1be46f37611386c845da0452fe7d406394376a57d21d6df1d55dd1856d1" => :sierra
    sha256 "d3b8c9c0bc3c6d4f2ed250f8192d0cdc1e012cb56c0188f06953a71b3e7a4c9d" => :x86_64_linux
  end

  conflicts_with "ssed", :because => "both install share/info/sed.info"

  def install
    args = %W[
      --prefix=#{prefix}
      --disable-dependency-tracking
    ]

    args << "--program-prefix=g" if OS.mac?
    args << "--without-selinux" unless OS.mac?
    system "./configure", *args
    system "make", "install"

    if OS.mac?
      (libexec/"gnubin").install_symlink bin/"gsed" =>"sed"
      (libexec/"gnuman/man1").install_symlink man1/"gsed.1" => "sed.1"
    end

    libexec.install_symlink "gnuman" => "man"
  end

  def caveats
    return unless OS.mac?

    <<~EOS
      GNU "sed" has been installed as "gsed".
      If you need to use it as "sed", you can add a "gnubin" directory
      to your PATH from your bashrc like:

        PATH="#{opt_libexec}/gnubin:$PATH"
    EOS
  end

  test do
    (testpath/"test.txt").write "Hello world!"
    if OS.mac?
      system "#{bin}/gsed", "-i", "s/world/World/g", "test.txt"
      assert_match /Hello World!/, File.read("test.txt")

      system "#{opt_libexec}/gnubin/sed", "-i", "s/world/World/g", "test.txt"
      assert_match /Hello World!/, File.read("test.txt")
    end

    unless OS.mac?
      system "#{bin}/sed", "-i", "s/world/World/g", "test.txt"
      assert_match /Hello World!/, File.read("test.txt")
    end
  end
end
