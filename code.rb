require "docker-api"
require "pry"

if ARGV.length != 1
  puts 'Usage: code.rb <file_path>'
  exit(1)
end

command = ARGV[0]

file = File.open(command)

def command_image_binding(file)
  case File.extname(file.path).gsub(".", "")
  when "rb"
    {
      Cmd: ["ruby", file.path], image: "ruby:latest"
    }
  when "py"
    {
      Cmd: ["python3", file.path], image: "python:latest"
    }
  when "go"
    {
      Cmd: ["go", "run", file.path], image: "golang:latest"
    }
  when "java"
    {
      Cmd: ["bash", "-c", "javac #{file.path} && java #{file.path}"],
      image: "openjdk:latest"
    }
  when "c"
    {
      Cmd: ["bash", "-c", "gcc #{file.path} -o /tmp/a.out && /tmp/a.out"],
      image: "gcc:latest"
    }
  when "cpp"
    {
      Cmd: ["bash", "-c", "g++ #{file.path} -o /tmp/a.out && /tmp/a.out"],
      image: "gcc:latest"
    }
  when "cs"
    {
      Cmd: ["bash", "-c", "mcs -out:/workspace/a.exe #{file.path} && mono /workspace/a.exe"],
      image: "mono:latest"
    }
  when "rs"
    {
      Cmd: ["bash", "-c", "rustc #{file.path} -o /tmp/a.out && /tmp/a.out"],
      image: "rust:latest"
    }
  else
    puts "Unknown extension"
    exit(0)
  end
end
  
docker_args = command_image_binding(file)

image = Docker::Image.create(fromImage: docker_args[:image])

container = Docker::Container.create(
  **docker_args,
  'HostConfig': { 'Binds': ["#{Dir.pwd}:/workspace"] },
  'WorkingDir' => "/workspace"
)
container.start
stdout, stderr = container.attach(stdout: true, stderr: true)

puts stdout.join
puts stderr.join unless stderr.empty?

container.delete(force: true)