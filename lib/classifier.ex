defmodule Classifier do
  def run(input_path, output_path, similarity_threshold) do
    input_path
    |> File.read()
    |> case do
      {:ok, contents} ->
        contents
        |> Jason.decode!()
        |> normalize_paths()
        |> filter_paths()
        |> clusterize(similarity_threshold)
        |> Enum.sort_by(&length/1, :desc)
        |> Jason.encode!()
        |> then(&File.write!(output_path, &1))

      {:error, reason} ->
        IO.puts("Error reading file: #{reason}")
    end
  end

  def normalize_paths(paths_data) do
    Enum.map(paths_data, fn {id, paths} ->
      app_name = extract_app_name(paths)

      normalized_paths =
        Enum.map(paths, fn path ->
          String.replace(path, app_name, "app_name")
        end)

      {id, normalized_paths}
    end)
  end

  def extract_app_name(paths) do
    paths
    |> Enum.find_value(fn path ->
      if String.starts_with?(path, "Payload/") do
        Regex.named_captures(~r/Payload\/(?<app_name>[\w\.\h-]+)\.app/, path)["app_name"]
      end
    end)
  end

  def filter_paths(paths_data) do
    regex_nib = ~r/(\w|\d){3}-(\w|\d){2}-(\w|\d){3}-view-(\w|\d){3}-(\w|\d){2}-(\w|\d){3}\.nib/

    Enum.map(paths_data, fn {id, paths} ->
      filtered_paths =
        paths
        |> Enum.filter(&String.ends_with?(&1, "/"))
        |> Enum.reject(&reject_path?(&1, regex_nib))

      {id, MapSet.new(filtered_paths)}
    end)
  end

  def reject_path?(path, regex_nib) do
    path =~ regex_nib or String.contains?(path, "lproj")
  end

  def clusterize(subdirectories_list, threshold) do
    Enum.reduce(subdirectories_list, [], fn {id, subdirectories}, acc ->
      case Enum.find_index(acc, fn cluster ->
             similarity(subdirectories, hd(cluster) |> elem(1)) > threshold
           end) do
        nil ->
          [[{id, subdirectories}] | acc]

        index ->
          List.update_at(acc, index, &[{id, subdirectories} | &1])
      end
    end)
    |> Enum.map(fn cluster -> Enum.map(cluster, &elem(&1, 0)) end)
  end

  def similarity(set1, set2) do
    intersection = MapSet.size(MapSet.intersection(set1, set2))
    intersection / min(MapSet.size(set1), MapSet.size(set2))
  end
end
