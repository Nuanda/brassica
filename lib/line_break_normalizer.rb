class LineBreakNormalizer
  def call(filepath)
    File.open(filepath, "r") do |src|
      Tempfile.open("") do |dst|
        src.read.split(/\r\n|\r|\n/).each do |line|
          dst << "#{line}\n"
        end

        dst.flush

        FileUtils.cp(dst.path, src.path)
      end
    end
  end
end
