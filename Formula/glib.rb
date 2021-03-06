class Glib < Formula
  desc "Core application library for C"
  homepage "https://developer.gnome.org/glib/"
  url "https://download.gnome.org/sources/glib/2.60/glib-2.60.2.tar.xz"
  sha256 "2ef15475060addfda0443a7e8a52b28a10d5e981e82c083034061daf9a8f80d9"

  bottle do
    root_url "https://linuxbrew.bintray.com/bottles"
    sha256 "1969b4088e0235f81bdd6fc846f0f990008d07122728b2e927a0af71b6edf56d" => :mojave
    sha256 "989876659fc86bb374e56e2d585ce0ae7dec6b2a54728e20e24b1b2609c9a45b" => :high_sierra
    sha256 "873a94deda0ef73e09e22fa30c1cdb3145f8acadfc275298d015e0a2f359725c" => :sierra
    sha256 "11f5e63eaea0ca6d90f702842eb2bdcf0b2197aac5303bf5c08f02581f4b0163" => :x86_64_linux
  end

  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "gettext"
  depends_on "libffi"
  depends_on "pcre"
  depends_on "python"
  depends_on "util-linux" unless OS.mac? # for libmount.so

  # https://bugzilla.gnome.org/show_bug.cgi?id=673135 Resolved as wontfix,
  # but needed to fix an assumption about the location of the d-bus machine
  # id file.
  patch do
    url "https://raw.githubusercontent.com/Homebrew/formula-patches/6164294a7/glib/hardcoded-paths.diff"
    sha256 "a57fec9e85758896ff5ec1ad483050651b59b7b77e0217459ea650704b7d422b"
  end

  def install
    inreplace %w[gio/gdbusprivate.c gio/xdgmime/xdgmime.c glib/gutils.c],
      "@@HOMEBREW_PREFIX@@", HOMEBREW_PREFIX

    # Disable dtrace; see https://trac.macports.org/ticket/30413
    args = %W[
      -Dgio_module_dir=#{HOMEBREW_PREFIX}/lib/gio/modules
      -Dbsymbolic_functions=false
      -Ddtrace=false
    ]

    args << "-Diconv=native" if OS.mac?
    # Prevent meson to use lib64 on centos
    args << "--libdir=#{lib}" unless OS.mac?

    mkdir "build" do
      system "meson", "--prefix=#{prefix}", *args, ".."
      system "ninja", "-v"
      system "ninja", "install", "-v"
    end

    # ensure giomoduledir contains prefix, as this pkgconfig variable will be
    # used by glib-networking and glib-openssl to determine where to install
    # their modules
    inreplace lib/"pkgconfig/gio-2.0.pc",
              "giomoduledir=#{HOMEBREW_PREFIX}/lib/gio/modules",
              "giomoduledir=${libdir}/gio/modules"

  # `pkg-config --libs glib-2.0` includes -lintl, and gettext itself does not
  # have a pkgconfig file, so we add gettext lib and include paths here.
  gettext = Formula["gettext"].opt_prefix
  lintl = OS.mac? ? "-lintl ": ""
  inreplace lib+"pkgconfig/glib-2.0.pc" do |s|
    s.gsub! "Libs: #{lintl}-L${libdir} -lglib-2.0",
            "Libs: -L${libdir} -lglib-2.0 -L#{gettext}/lib#{lintl}"
    s.gsub! "Cflags: -I${includedir}/glib-2.0 -I${libdir}/glib-2.0/include",
            "Cflags: -I${includedir}/glib-2.0 -I${libdir}/glib-2.0/include -I#{gettext}/include"
  end
  end

  def post_install
    (HOMEBREW_PREFIX/"lib/gio/modules").mkpath
  end

  test do
    (testpath/"test.c").write <<~EOS
      #include <string.h>
      #include <glib.h>

      int main(void)
      {
          gchar *result_1, *result_2;
          char *str = "string";

          result_1 = g_convert(str, strlen(str), "ASCII", "UTF-8", NULL, NULL, NULL);
          result_2 = g_convert(result_1, strlen(result_1), "UTF-8", "ASCII", NULL, NULL, NULL);

          return (strcmp(str, result_2) == 0) ? 0 : 1;
      }
    EOS
    system ENV.cc, "-o", "test", "test.c", "-I#{include}/glib-2.0",
                   "-I#{lib}/glib-2.0/include", "-L#{lib}", "-lglib-2.0"
    system "./test"
  end
end
