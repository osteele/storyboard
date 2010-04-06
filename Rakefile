task :mpeg do
  # -metadata title="Visualizing the Fourier Transform"
  # -metadata author="Oliver Steele"
  # -s 1920x1080
  sh "ffmpeg -y -i build/frames/frame-%04d.png -r 24 build/dft.mp4"
end

task :hidef do
  sh "ffmpeg -y -i build/frames/frame-%04d.png -an -pass 1 -vcodec libx264 -vpre fastfirstpass -threads 0 build/dft-hi.mp4"
end
