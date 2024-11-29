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
      Cmd: ["bash", "-c", "javac #{File.basename(file.path)} && java #{File.basename(file.path, ".java")}"],
      image: "openjdk:latest"
    }
  when "c"
    {
      Cmd: ["bash", "-c", "gcc #{File.basename(file.path)} -o /tmp/a.out && /tmp/a.out"],
      image: "gcc:latest"
    }
  when "cpp"
    {
      Cmd: ["bash", "-c", "g++ #{File.basename(file.path)} -o /tmp/a.out && /tmp/a.out"],
      image: "gcc:latest"
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