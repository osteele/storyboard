FRAME_DIR = '/tmp/storyboard/frames'

desc "Create a H.264 movie"
task :h264 do
  # -metadata title="Visualizing the Fourier Transform"
  # -metadata author="Oliver Steele"
  # -s 1920x1080
  cd File.join(File.dirname(__FILE__), "build")
  sh "ffmpeg -y -i #{FRAME_DIR}/frame-%04d.png -an -pass 1 -vcodec libx264 -vpre fastfirstpass -threads 0 -sameq -b 7000k -minrate 7000k -maxrate 7000k dft.mp4"
end

desc "Create a VGA-size movie"
task :vga do
  cd File.join(File.dirname(__FILE__), "build")
  sh "ffmpeg -y -i #{FRAME_DIR}/frame-%04d.png -an -pass 1 -vcodec libx264 -vpre fastfirstpass -threads 0 -sameq -b 7000k -minrate 7000k -maxrate 7000k -s vga dft-vga.mp4"
end

desc "Create an XGA-size movie"
task :xga do
  cd File.join(File.dirname(__FILE__), "build")
  sh "ffmpeg -y -i #{FRAME_DIR}/frame-%04d.png -an -pass 1 -vcodec libx264 -vpre fastfirstpass -threads 0 -sameq -b 7000k -minrate 7000k -maxrate 7000k -s xga dft-xga.mp4"
end

desc "Create a movie using the MPEG4 encoder"
task :mp4 do
  cd File.join(File.dirname(__FILE__), "build")
  sh "ffmpeg -y -i #{FRAME_DIR}/frame-%04d.png -vcodec mpeg4 -sameq dft.mp4"
end

desc "Create an movie for the iPod"
task :ipod do
  cd File.join(File.dirname(__FILE__), "build")
  sh "ffmpeg -y -i #{FRAME_DIR}/frame-%04d.png -f mov -b 1800 -maxrate 2500 -vcodec libxvid -sameq -s 320x240 -aspect 4:3 -acodec aac -ab 128 dft.mov"
end
