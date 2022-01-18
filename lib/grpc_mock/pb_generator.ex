defmodule GrpcMock.PbGenerator do

  @out_dir Application.compile_env(:grpc_mock, :proto_out_dir)

  def protoc_compile(import_path, proto_files_glob) do
    System.cmd("protoc", ~w(--proto_path=#{import_path} --elixir_opt=package_prefix=GprcMock.Protos --elixir_out=plugins=grpc:#{@out_dir} #{proto_files_glob}))
  end

  def load_modules do
    "#{@out_dir}/**/*.ex"
    |> Path.wildcard()
    |> Enum.map(&Code.compile_file/1)
    |> List.flatten()
  end
end
