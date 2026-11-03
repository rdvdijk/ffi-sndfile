# frozen_string_literal: true

require "fileutils"
require "tmpdir"

# A temporary directory per example, removed after the example.
module TmpFiles
  def tmp_path(name)
    File.join(tmp_dir, name)
  end

  def tmp_dir
    @tmp_dir ||= Dir.mktmpdir("ffi-sndfile-")
  end

  def remove_tmp_dir
    FileUtils.remove_entry(@tmp_dir) if @tmp_dir
  end
end
